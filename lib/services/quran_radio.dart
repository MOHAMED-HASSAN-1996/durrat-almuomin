import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:audio_service/audio_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'firebase_auth_service.dart';
import '../data/radio_live_stations_data.dart';
import 'radio_audio_handler.dart';

typedef RadioStation = ({int id, String name, String url, String category});

class QuranRadioService {
  QuranRadioService._();
  static final QuranRadioService instance = QuranRadioService._();
  factory QuranRadioService() => instance;

  // ── Single player, reused ──────────────────────────────────────────────
  final AudioPlayer _player = AudioPlayer();
  bool _audioContextSet = false;

  // ── State ──────────────────────────────────────────────────────────────
  bool _playing = false;
  bool get isPlaying => _playing;
  String? _currentUrl;
  String? get currentUrl => _currentUrl;
  String? _stationName;
  String? get stationName => _stationName;
  String? _stationCategory;
  String? get stationCategory => _stationCategory;
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;
  bool _userStopped = true;
  int _sessionId = 0;
  Timer? _reconnectTimer;

  final _stateCtrl = StreamController<PlayerState>.broadcast();
  Stream<PlayerState> get stateStream => _stateCtrl.stream;

  // ── Stations ───────────────────────────────────────────────────────────
  List<RadioStation> _stations = [];
  List<RadioStation> get stations => List.unmodifiable(_stations);
  bool _initialized = false;

  // ── Audio handler ──────────────────────────────────────────────────────
  RadioAudioHandler? _audioHandler;
  RadioAudioHandler? get audioHandler => _audioHandler;

  // ── Notification (إلغاء فقط لتنظيف الإشعار القديم بعد إزالته) ──────────
  final _notif = FlutterLocalNotificationsPlugin();
  static const int _notifId = 9999;

  // ── Hardcoded live stations ────────────────────────────────────────────
  // These resolve from the dedicated links file; each id matches the admin
  // dashboard `radio` collection so panel edits override the built-in live
  // stations automatically.
  static const Map<String, int> _panelLiveIds = {
    'radio_cairo': 1001,
    'radio_madina': 1002,
    'radio_sunnah': 1003,
  };

  static RadioStation _builtInStation(String panelId) {
    final entry = builtInLiveStations.firstWhere((s) => s.id == panelId);
    return (
      id: _panelLiveIds[panelId] ?? 999,
      name: entry.name,
      url: entry.url,
      category: entry.category,
    );
  }

  static final RadioStation _cairoStation = _builtInStation('radio_cairo');
  static final RadioStation _madinaStation = _builtInStation('radio_madina');
  static final RadioStation _sunnahStation = _builtInStation('radio_sunnah');
  static final List<RadioStation> _defaultLive = [
    _cairoStation,
    _madinaStation,
    _sunnahStation,
  ];

  RadioStation get cairoStation => _cairoStation;
  RadioStation get madinaStation => _madinaStation;
  RadioStation get sunnahStation => _sunnahStation;

  /// All live stations actually available: built-ins plus any station added or
  /// edited from the admin dashboard (Firestore). Keeps built-ins until the
  /// merged list is ready.
  List<RadioStation> get liveStations {
    if (_initialized && _stations.isNotEmpty) {
      return _stations.where((s) => s.category == 'live').toList();
    }
    return _defaultLive;
  }

  List<RadioStation> get reciterStations =>
      _stations.where((s) => s.category != 'live').toList();
  bool isLiveStation(RadioStation s) => s.category == 'live';

  // ═══════════════════════════════════════════════════════════════════════
  //  INIT — runs once
  // ═══════════════════════════════════════════════════════════════════════

  void _init() {
    _player.setPlayerMode(PlayerMode.mediaPlayer);

    _player.onPlayerStateChanged.listen((s) {
      if (_userStopped && s == PlayerState.playing) {
        _player.stop();
        _playing = false;
        _stateCtrl.add(PlayerState.stopped);
        return;
      }
      _stateCtrl.add(s);
      if (s == PlayerState.playing) {
        _playing = true;
        _reconnectTimer?.cancel();
        _syncHandler();
      } else if (s == PlayerState.stopped) {
        _playing = false;
        _hideNotification();
      }
    });

    _player.onPlayerComplete.listen((_) {
      if (!_userStopped && _currentUrl != null) {
        _scheduleReconnect();
      } else {
        _playing = false;
        _stateCtrl.add(PlayerState.stopped);
        _hideNotification();
      }
    });
  }

  bool _initDone = false;

  Future<void> _ensureInit() async {
    if (_initDone) return;
    _initDone = true;
    _init();
    _audioHandler ??= await AudioService.init(
      builder: () => RadioAudioHandler(_player),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.dhikr.adhkar.radio.channel',
        androidNotificationChannelName: 'درة المؤمن',
        androidNotificationChannelDescription: 'تشغيل البث المباشر في الخلفية',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidNotificationIcon: 'mipmap/ic_launcher',
        notificationColor: Color(0xFF0F2E23),
      ),
    );
  }

  Future<void> ensureAudioContext() async {
    if (_audioContextSet) return;
    try {
      await _player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {AVAudioSessionOptions.defaultToSpeaker},
          ),
        ),
      );
      _audioContextSet = true;
    } catch (_) {}
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  FETCH RECITERS FROM API (background, non-blocking)
  // ═══════════════════════════════════════════════════════════════════════

  Future<List<RadioStation>> fetchStations() async {
    // Always keep live stations first
    _stations = List.from(_defaultLive);

    // Admin-managed stations from Firestore (best-effort, never blocking).
    await _mergeRemoteStations();

    try {
      final res = await http
          .get(
            Uri.parse('https://www.mp3quran.net/api/v3/radios?language=ar'),
            headers: {'User-Agent': 'DhikrApp/1.0'},
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['radios'] is List) {
          final seenUrls = <String>{};
          final seenNames = <String>{};
          for (final item in data['radios']) {
            if (item is! Map) continue;
            final name = (item['name'] as String? ?? '').trim();
            var url = (item['url'] as String? ?? '').trim().replaceFirst('http://', 'https://');
            final id = (item['id'] as num?)?.toInt() ?? 0;
            if (url.isEmpty || name.isEmpty) continue;

            final normName = name.replaceAll(RegExp(r'\s+'), ' ');
            if (seenUrls.contains(url) || seenNames.contains(normName)) continue;
            seenUrls.add(url);
            seenNames.add(normName);
            _stations.add((id: id, name: name, url: url, category: 'radio'));
          }
        }
      }
    } catch (e) {
      debugPrint('[Radio] API: $e');
    }

    _initialized = true;
    return List.unmodifiable(_stations);
  }

  Future<List<RadioStation>> buildStationList() async {
    if (!_initialized) return fetchStations();
    return List.unmodifiable(_stations);
  }

  /// Merges admin-managed stations from the Firestore `radio` collection.
  /// Remote live stations with the same id as a built-in one (radio_cairo,
  /// radio_madina, radio_sunnah) override its name/url, so a link edited in
  /// the control panel takes effect in the app on next refresh. New stations
  /// are appended (de-duplicated by URL). Any failure keeps the current list.
  Future<void> _mergeRemoteStations() async {
    try {
      final ok = await FirebaseAuthService.instance.initialize();
      if (!ok) return;
      final snap = await FirebaseFirestore.instance
          .collection('radio')
          .limit(100)
          .get()
          .timeout(const Duration(seconds: 6));
      if (snap.docs.isEmpty) return;

      final current = List.of(_stations);
      final known = current.map((s) => s.url).toSet();
      final replacements = <int, RadioStation>{};
      final extra = <RadioStation>[];
      var fallbackId = 100000;

      for (final doc in snap.docs) {
        final data = doc.data();
        final name = (data['name'] ?? '').toString().trim();
        var url = (data['url'] ?? '').toString().trim();
        if (name.isEmpty || url.isEmpty) continue;
        if (url.startsWith('http://')) {
          url = url.replaceFirst('http://', 'https://');
        }
        if (!url.startsWith('https://')) continue;

        final rawId = (data['id'] ?? doc.id).toString();
        final panelId = _panelLiveIds[rawId];

        // Override matching built-in live station (position preserved).
        // Only applied when the new link answers a HEAD/GET so a stale dead
        // link stored in Firestore never replaces a working built-in one.
        if (panelId != null) {
          final idx = current.indexWhere((s) => s.id == panelId);
          if (idx != -1) {
            if (data['isActive'] != false &&
                url != current[idx].url &&
                await _isUrlAlive(url)) {
              replacements[idx] = (
                id: panelId,
                name: name,
                url: url,
                category: 'live',
              );
            }
            continue;
          }
        }

        if (data['isActive'] == false) continue;
        if (known.contains(url)) continue;
        known.add(url);
        final parsedId = int.tryParse(rawId) ?? fallbackId++;
        final rawCat = (data['category'] ?? 'radio').toString().trim();
        extra.add((
          id: parsedId,
          name: name,
          url: url,
          category: rawCat.isEmpty ? 'radio' : rawCat,
        ));
      }

      if (replacements.isEmpty && extra.isEmpty) return;
      final merged = List.of(current);
      replacements.forEach((idx, station) {
        if (idx >= 0 && idx < merged.length) merged[idx] = station;
      });
      merged.addAll(extra);
      _stations = merged;
    } catch (e) {
      debugPrint('[Radio] remote stations note: $e');
    }
  }

  /// Quick reachability probe used before replacing a working built-in link
  /// with a control-panel link, so stale/dead panel entries are ignored.
  Future<bool> _isUrlAlive(String url) async {
    try {
      final res = await http
          .head(Uri.parse(url), headers: {'User-Agent': 'DhikrApp/1.0'})
          .timeout(const Duration(seconds: 4));
      if (res.statusCode > 0 && res.statusCode < 400) return true;
      // Some stream servers reject HEAD; fall back to a tiny ranged GET.
      final get = await http
          .get(
            Uri.parse(url),
            headers: {'User-Agent': 'DhikrApp/1.0', 'Range': 'bytes=0-0'},
          )
          .timeout(const Duration(seconds: 4));
      return get.statusCode >= 200 && get.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  PLAY — simple, fast, single player
  // ═══════════════════════════════════════════════════════════════════════

  Future<bool> play({String? url, String? name, String? category}) async {
    final session = ++_sessionId;
    _userStopped = false;
    _reconnectTimer?.cancel();

    await _ensureInit();
    await ensureAudioContext();

    // Resolve target
    var targetUrl = url ?? _currentUrl ?? _cairoStation.url;
    var targetName = name ?? _stationName ?? _cairoStation.name;
    var targetCat = category ?? _stationCategory ?? 'live';

    // Update metadata
    _currentUrl = targetUrl;
    _stationName = targetName;
    _stationCategory = targetCat;
    final idx = _stations.indexWhere((s) => s.url == targetUrl);
    if (idx != -1) _currentIndex = idx;

    // Stop cleanly first — bounded so switching never stalls.
    try {
      await _player.stop().timeout(const Duration(seconds: 2));
    } catch (_) {}

    if (session != _sessionId || _userStopped) return false;

    // Play the URL, then mirrors on failure/timeout.
    for (final candidate in [targetUrl, ..._getMirrors(targetUrl)]) {
      if (session != _sessionId || _userStopped) return false;
      final started = await _tryPlay(candidate, session);
      if (!started) continue;
      if (session != _sessionId || _userStopped) return false;
      _currentUrl = candidate;
      debugPrint('[Radio] OK: $candidate');
      return true;
    }

    if (session == _sessionId) {
      _playing = false;
      _stateCtrl.add(PlayerState.stopped);
    }
    return false;
  }

  /// Starts a URL and waits until playback actually begins (or fails/bails),
  /// so callers get a truthful result instead of hanging on a dead stream.
  Future<bool> _tryPlay(String url, int session) async {
    final completer = Completer<bool>();
    StreamSubscription<PlayerState>? stateSub;
    Timer? timer;

    void finish(bool ok) {
      if (completer.isCompleted) return;
      stateSub?.cancel();
      timer?.cancel();
      completer.complete(ok);
    }

    stateSub = _player.onPlayerStateChanged.listen((s) {
      if (session != _sessionId || _userStopped) {
        finish(false);
        return;
      }
      if (s == PlayerState.playing) {
        debugPrint('[Radio] Playing: $url');
        finish(true);
      } else if (s == PlayerState.completed || s == PlayerState.stopped) {
        finish(false);
      }
    });

    try {
      debugPrint('[Radio] Starting: $url');
      await _player.play(UrlSource(url));
    } catch (e) {
      debugPrint('[Radio] Start failed: $url -> $e');
      finish(false);
    }

    // Bail out after this long even if the stream never enters playing state.
    timer = Timer(const Duration(seconds: 7), () {
      debugPrint('[Radio] Start timeout: $url');
      finish(false);
    });

    final ok = await completer.future;
    if (!ok) {
      try {
        await _player.stop().timeout(const Duration(seconds: 2));
      } catch (_) {}
    }
    return ok;
  }

  List<String> _getMirrors(String url) {
    if (url.contains('radiojar') || url.contains('radio/mix')) {
      return [
        'https://n07.radiojar.com/8s5u5tpdtwzuv',
        'https://backup.qurango.net/radio/mix',
        'https://qurango.net/radio/mix',
      ];
    }
    // Reciter fallback: try qurango.net version
    if (url.contains('backup.qurango.net')) {
      return [url.replaceFirst('backup.qurango.net', 'qurango.net')];
    }
    if (url.contains('qurango.net')) {
      return [url.replaceFirst('qurango.net', 'backup.qurango.net')];
    }
    return [];
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  STOP / PAUSE / RESUME
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> stop() async {
    _sessionId++;
    _userStopped = true;
    _reconnectTimer?.cancel();
    _playing = false;
    _stateCtrl.add(PlayerState.stopped);
    _hideNotification();
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (_) {}
  }

  Future<bool> resume() async =>
      play(url: _currentUrl, name: _stationName, category: _stationCategory);

  // ═══════════════════════════════════════════════════════════════════════
  //  NAVIGATION
  // ═══════════════════════════════════════════════════════════════════════

  Future<bool> playCairo() => play(
      url: _cairoStation.url, name: _cairoStation.name, category: 'live');

  Future<bool> playMadina() => play(
      url: _madinaStation.url, name: _madinaStation.name, category: 'live');

  Future<bool> nextLive() {
    final live = liveStations;
    final idx = live.indexWhere((s) => s.url == _currentUrl);
    final next = (idx + 1) % live.length;
    final t = live[next];
    return play(url: t.url, name: t.name, category: 'live');
  }

  Future<bool> previousLive() {
    final live = liveStations;
    final idx = live.indexWhere((s) => s.url == _currentUrl);
    final prev = idx <= 0 ? live.length - 1 : idx - 1;
    final t = live[prev];
    return play(url: t.url, name: t.name, category: 'live');
  }

  Future<bool> nextReciter() {
    final list = reciterStations;
    if (list.isEmpty) return Future.value(false);
    final idx = list.indexWhere((s) => s.url == _currentUrl);
    final next = (idx + 1) % list.length;
    final t = list[next];
    return play(url: t.url, name: t.name, category: 'reciter');
  }

  Future<bool> previousReciter() {
    final list = reciterStations;
    if (list.isEmpty) return Future.value(false);
    final idx = list.indexWhere((s) => s.url == _currentUrl);
    final prev = idx <= 0 ? list.length - 1 : idx - 1;
    final t = list[prev];
    return play(url: t.url, name: t.name, category: 'reciter');
  }

  Future<bool> nextStation() {
    if (_stations.isEmpty) return Future.value(false);
    final next = (_currentIndex + 1) % _stations.length;
    final s = _stations[next];
    return play(url: s.url, name: s.name, category: s.category);
  }

  Future<bool> previousStation() {
    if (_stations.isEmpty) return Future.value(false);
    final prev = (_currentIndex - 1 + _stations.length) % _stations.length;
    final s = _stations[prev];
    return play(url: s.url, name: s.name, category: s.category);
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  RECONNECT
  // ═══════════════════════════════════════════════════════════════════════

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (!_userStopped && _currentUrl != null) {
        play(url: _currentUrl, name: _stationName, category: _stationCategory);
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  AUDIO HANDLER
  // ═══════════════════════════════════════════════════════════════════════

  void _syncHandler() {
    _audioHandler?.updateStationMetadata(
      url: _currentUrl ?? '',
      title: _stationName ?? _cairoStation.name,
      category: _stationCategory,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  NOTIFICATION — إزالة الإشعار المخصص بالكامل (إشعار الـ Media Session
  //  الخاص بـ audio_service يكفي ويظهر وحده).
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _hideNotification() async {
    if (kIsWeb) return;
    try {
      await _notif.cancel(id: _notifId);
    } catch (_) {}
  }

  /// تنظيف إشعار الإشعارات القديمة (بعد إزالة الإشعار المخصص من الواجهة).
  Future<void> clearLegacyNotification() => _hideNotification();

  // ═══════════════════════════════════════════════════════════════════════
  //  RESET / DISPOSE
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> resetPlayer() async {
    _sessionId++;
    try {
      await _player.stop();
    } catch (_) {}
    _playing = false;
    _stateCtrl.add(PlayerState.stopped);
  }

  void dispose() {
    _stateCtrl.close();
    _player.dispose();
  }
}
