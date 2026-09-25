import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/content_validation.dart';
import '../types/adhkar.dart';
import 'firebase_auth_service.dart';

/// Optional remote feed for the app's adhkar content.
///
/// Everything here is an **additive, non-blocking, safe-off** layer that
/// never deletes or replaces the built-in lists. The built-in data
/// (lib/data/*.dart) is the always-available baseline; this service only
/// makes the admin-edited remote lists available per category when:
///   * the feature is enabled, AND
///   * the Firestore `adhkar` collection (or legacy `/api/adhkar`) is reachable.
/// On any failure it degrades to the built-in content, so no screen ever
/// throws. Cached remote content is kept in SharedPreferences so a cold start
/// with connectivity still works.
class AdhkarRemoteService extends ChangeNotifier {
  AdhkarRemoteService._();
  static final AdhkarRemoteService instance = AdhkarRemoteService._();

  static const _prefLedgerKey = 'adhkar.remote.adhkar.cache';
  static const _prefEnabledKey = 'adhkar.remote.enabled';
  static const _prefBaseKey = 'adhkar.remote.base';

  static const _defaultBase = 'http://127.0.0.1:4000/api';

  String _base = _defaultBase;
  String get base => _base;
  void setBase(String value) {
    final v = value.trim();
    if (v.isEmpty || v == _base) return;
    _base = v.endsWith('/') ? v.substring(0, v.length - 1) : v;
    _markDirty();
    _persistConfig();
  }

  bool _enabled = true;
  bool get enabled => _enabled;
  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    _markDirty();
    _persistConfig();
    notifyListeners();
    if (value) {
      subscribeFirestore();
      refresh(silent: true);
    } else {
      _cancelFirestore();
    }
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _firestoreSub;
  bool get firestoreActive => _firestoreSub != null;

  bool _busy = false;
  bool get busy => _busy;
  bool get isLoading => _busy;

  String? _lastError;
  String? get lastError => _lastError;

  DateTime? _lastSync;
  DateTime? get lastSync => _lastSync;
  bool get isReady => _lastSync != null;

  bool _prefsDirty = false;

  void _markDirty() => _prefsDirty = true;

  final Map<DhikrCategory, List<Dhikr>> _remote = {};
  Map<DhikrCategory, List<Dhikr>> get remoteByCategory =>
      Map.unmodifiable(_remote);

  int get remoteTotal => _remote.values.fold(0, (n, list) => n + list.length);

  /// Synchronous, safe reader used by the screens. Never throws.
  List<Dhikr> adhkarFor(DhikrCategory category) {
    final remote = _remote[category];
    if (_enabled && remote != null && remote.isNotEmpty) return remote;
    return getBuiltInAdhkar(category);
  }

  /// Fetches the whole validated list from the admin server, merges it with
  /// any built-in dhikr whose id isn't present remotely (so nothing existing
  /// disappears), caches it, and switches the live list over.
  Future<AdhkarFetchResult> refresh({bool silent = false}) async {
    if (_busy || !_enabled) return const AdhkarFetchResult(ok: false);
    _busy = true;
    if (!silent) notifyListeners();
    try {
      final res = await http
          .get(Uri.parse('$_base/adhkar'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) {
        throw http.ClientException('adhkar HTTP ${res.statusCode}');
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final raw = (body['adhkar'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
      final validated = validateAdhkarList(raw.map(Dhikr.fromJson).toList());
      _apply(validated.valid);
      _lastSync = DateTime.now();
      _lastError = null;
      await _persist();
      if (!silent) notifyListeners();
      return AdhkarFetchResult(ok: true, total: validated.valid.length);
    } catch (e) {
      _lastError = e.toString();
      if (!silent) notifyListeners();
      return const AdhkarFetchResult(ok: false);
    } finally {
      _busy = false;
    }
  }

  void _apply(List<Dhikr> validated) {
    final merged = <Dhikr>[];
    final remoteIds = <String>{};
    for (final d in validated) {
      remoteIds.add(d.id);
      merged.add(d);
    }
    for (final c in DhikrCategory.values) {
      for (final builtIn in getBuiltInAdhkar(c)) {
        if (!remoteIds.contains(builtIn.id)) merged.add(builtIn);
      }
    }
    _remote
      ..clear()
      ..addEntries(DhikrCategory.values.map((c) => MapEntry(c, <Dhikr>[])));
    for (final d in merged) {
      _remote[d.category]!.add(d);
    }
  }

  Future<void> _persistConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefEnabledKey, _enabled);
    await prefs.setString(_prefBaseKey, _base);
    _prefsDirty = false;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final flat = _remote.values.expand((l) => l).toList();
    await prefs.setString(
      _prefLedgerKey,
      jsonEncode(flat.map((d) => d.toJson()).toList()),
    );
    if (_prefsDirty) {
      await _persistConfig();
    }
  }

  /// Loads persisted state (toggle + cached remote list) so a previously
  /// enabled+synced app keeps showing remote content on next launch.
  /// Fresh installs default to enabled so the admin dashboard can manage
  /// content; the built-in lists always remain as offline fallback.
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_prefEnabledKey) ?? true;
    _base = prefs.getString(_prefBaseKey) ?? _base;
    final raw = prefs.getString(_prefLedgerKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final revived = (jsonDecode(raw) as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map(Dhikr.fromJson)
            .toList();
        _apply(revived);
      } catch (_) {}
    }
    notifyListeners();
    if (_enabled) subscribeFirestore();
  }

  /// Live Firestore feed for the `adhkar` collection managed by the admin
  /// dashboard. Additive and non-blocking: invalid docs are dropped by
  /// [validateAdhkarList] and built-in items are always merged back in.
  void subscribeFirestore() {
    if (_firestoreSub != null) return;
    unawaited(_listenFirestore());
  }

  Future<void> _listenFirestore() async {
    try {
      var ok = await FirebaseAuthService.instance.initialize();
      if (!ok) {
        // One delayed retry: cold-start races must not kill the feed.
        await Future<void>.delayed(const Duration(seconds: 4));
        if (_firestoreSub != null) return;
        ok = await FirebaseAuthService.instance.initialize();
      }
      if (!ok) return;
      final query = FirebaseFirestore.instance
          .collection('adhkar')
          .limit(2000);
      _firestoreSub = query.snapshots().listen((snap) {
        if (snap.docs.isEmpty) return;
        try {
          final maps = snap.docs.map((d) {
            final data = Map<String, dynamic>.from(d.data());
            data.putIfAbsent('id', () => d.id);
            // Dashboard may store a single audio URL; normalize to list.
            if (data['quranAudio'] == null) {
              final single = (data['audioUrl'] ?? '').toString().trim();
              if (single.isNotEmpty) data['quranAudio'] = [single];
            }
            return data;
          }).toList();
          maps.sort((a, b) {
            final ao = (a['order'] as num?)?.toDouble() ?? 1e9;
            final bo = (b['order'] as num?)?.toDouble() ?? 1e9;
            return ao.compareTo(bo);
          });
          final parsed = <Dhikr>[];
          for (final m in maps) {
            try {
              parsed.add(Dhikr.fromJson(m));
            } catch (_) {
              // Drop malformed admin docs; never crash the reader.
            }
          }
          if (parsed.isEmpty) return;
          final validated = validateAdhkarList(parsed);
          if (validated.valid.isEmpty) return;
          _apply(validated.valid);
          _lastSync = DateTime.now();
          _lastError = null;
          unawaited(_persist());
          notifyListeners();
        } catch (e) {
          debugPrint('Adhkar Firestore parse note: $e');
        }
      }, onError: (Object e) {
        debugPrint('Adhkar Firestore sync note: $e');
      });
    } catch (e) {
      debugPrint('Adhkar Firestore subscribe note: $e');
    }
  }

  void _cancelFirestore() {
    _firestoreSub?.cancel();
    _firestoreSub = null;
  }
}

/// Result of a single refresh round.
class AdhkarFetchResult {
  const AdhkarFetchResult({required this.ok, this.total = 0});
  final bool ok;
  final int total;
}
