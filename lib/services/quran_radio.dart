import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'radio_audio_handler.dart';

typedef RadioStation = ({int id, String name, String url, String category});

@pragma('vm:entry-point')
void _notificationBackgroundHandler(NotificationResponse response) {
  if (response.actionId == 'stop_radio') {
    QuranRadioService.instance.stop();
  } else if (response.actionId == 'next_station') {
    QuranRadioService.instance.nextStation();
  } else if (response.actionId == 'prev_station') {
    QuranRadioService.instance.previousStation();
  }
}

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

  // ── Notification ───────────────────────────────────────────────────────
  final _notif = FlutterLocalNotificationsPlugin();
  bool _notifReady = false;
  static const int _notifId = 9999;
  static const String _channelId = 'sakinah_radio_playback_channel';

  // ── Hardcoded live stations ────────────────────────────────────────────
  static const _cairoStation = (
    id: 1,
    name: 'إذاعة القرآن الكريم — القاهرة',
    url: 'https://n07.radiojar.com/8s5u5tpdtwzuv',
    category: 'live',
  );
  static const _madinaStation = (
    id: 2,
    name: 'إذاعة القرآن الكريم — المدينة المنورة',
    url: 'https://win.holol.com/live/quran/playlist.m3u8',
    category: 'live',
  );
  static const _sunnahStation = (
    id: 3,
    name: 'السنة النبوية',
    url: 'https://win.holol.com/live/sunnah/playlist.m3u8',
    category: 'live',
  );

  RadioStation get cairoStation => _cairoStation;
  RadioStation get makkahStation => _madinaStation;
  List<RadioStation> get liveStations => const [_cairoStation, _madinaStation, _sunnahStation];
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
        _showNotification();
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
        androidNotificationChannelName: 'دُرَّةُ الْمُؤْمِن',
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

  static const _defaultLive = [_cairoStation, _madinaStation, _sunnahStation];

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

    // Stop cleanly first
    try {
      await _player.stop();
    } catch (_) {}

    if (session != _sessionId || _userStopped) return false;

    // Play the URL directly
    try {
      debugPrint('[Radio] Playing: $targetUrl');
      await _player.play(UrlSource(targetUrl));
      if (session != _sessionId || _userStopped) return false;
      debugPrint('[Radio] OK: $targetUrl');
      return true;
    } catch (e) {
      debugPrint('[Radio] FAILED $targetUrl: $e');
    }

    // Try mirrors
    for (final mirror in _getMirrors(targetUrl)) {
      if (session != _sessionId || _userStopped) return false;
      try {
        debugPrint('[Radio] Trying mirror: $mirror');
        await _player.play(UrlSource(mirror));
        if (session != _sessionId || _userStopped) return false;
        _currentUrl = mirror;
        debugPrint('[Radio] MIRROR OK: $mirror');
        return true;
      } catch (e) {
        debugPrint('[Radio] Mirror failed: $mirror: $e');
      }
    }

    if (session == _sessionId) {
      _playing = false;
      _stateCtrl.add(PlayerState.stopped);
    }
    return false;
  }

  List<String> _getMirrors(String url) {
    if (url.contains('radiojar') || url.contains('radio/mix')) {
      return [
        'https://n07.radiojar.com/8s5u5tpdtwzuv',
        'https://backup.qurango.net/radio/mix',
        'https://qurango.net/radio/mix',
      ];
    }
    if (url.contains('holol.com/live/quran')) {
      return [
        'https://live.kwikmotion.com/sbrksaquranradiolive/ksaquranradio/playlist.m3u8',
      ];
    }
    if (url.contains('holol.com/live/sunnah')) {
      return [];
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

  Future<bool> playMakkah() => play(
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
  //  NOTIFICATION
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _initNotification() async {
    if (kIsWeb || _notifReady) return;
    try {
      await _notif.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (r) async {
          if (r.actionId == 'stop_radio') {
            await stop();
          } else if (r.actionId == 'next_station') {
            await nextStation();
          } else if (r.actionId == 'prev_station') {
            await previousStation();
          }
        },
      );
      final android = _notif.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        await android.requestNotificationsPermission();
        await android.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            'درّة المؤمن — بث مباشر',
            description: 'إشعار البث المباشر',
            importance: Importance.high,
            playSound: false,
            enableVibration: false,
          ),
        );
      }
      _notifReady = true;
    } catch (e) {
      debugPrint('[Radio] Notif init: $e');
    }
  }

  Future<void> _showNotification() async {
    if (kIsWeb) return;
    await _initNotification();
    try {
      await _notif.show(
        id: _notifId,
        title: 'درّة المؤمن — بث مباشر',
        body: _stationName ?? 'إذاعة القرآن الكريم',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'درّة المؤمن — بث مباشر',
            channelDescription: 'إشعار البث المباشر',
            importance: Importance.high,
            priority: Priority.high,
            ongoing: true,
            autoCancel: false,
            showWhen: false,
            playSound: false,
            enableVibration: false,
            icon: '@mipmap/ic_launcher',
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            styleInformation: BigTextStyleInformation(
              _stationName ?? '',
              contentTitle: 'درّة المؤمن — بث مباشر',
              summaryText: 'تلاوات القرآن الكريم',
            ),
            actions: [
              const AndroidNotificationAction(
                'prev_station',
                '⏮ السابق',
                showsUserInterface: false,
              ),
              const AndroidNotificationAction(
                'stop_radio',
                '⏹ إيقاف',
                showsUserInterface: false,
                cancelNotification: true,
              ),
              const AndroidNotificationAction(
                'next_station',
                '⏭ التالي',
                showsUserInterface: false,
              ),
            ],
            color: const Color(0xFF0F2E23),
            visibility: NotificationVisibility.public,
          ),
          iOS: const DarwinNotificationDetails(presentBadge: true, presentSound: false),
        ),
      );
    } catch (_) {}
  }

  Future<void> _hideNotification() async {
    if (kIsWeb) return;
    try {
      await _notif.cancel(id: _notifId);
    } catch (_) {}
  }

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
