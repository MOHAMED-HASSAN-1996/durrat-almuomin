import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:shared_preferences/shared_preferences.dart';
import '../data/anime_stories_data.dart';
import '../data/companions_stories_data.dart';
import '../data/hadith_data.dart';
import '../data/shaarawi_data.dart';
import '../data/soul_remedies_data.dart';
import 'firebase_auth_service.dart';

/// Remote Content & App Configuration Service
/// Manages remote display of Home Cards, Anime Stories, and Shaarawi Lessons
/// with 100% offline resilience and instant local cache.
class RemoteContentService extends ChangeNotifier {
  RemoteContentService._();
  static final RemoteContentService instance = RemoteContentService._();

  static const String _configCacheKey = 'durrat_remote_app_config';
  static const String _animeCacheKey = 'durrat_remote_anime_stories';
  static const String _shaarawiCacheKey = 'durrat_remote_shaarawi_lessons';

  // State
  Map<String, dynamic> _appConfig = {
    'maintenanceMode': false,
    'maintenanceMessage': 'التطبيق في صيانة مجدولة وسيعود قريباً بإذن الله.',
    'featuredDhikr': '',
    'minSupportedVersion': '1.0.0',
    'appVersion': '1.0.0',
    'forceUpdateUrl': '',
    'telegramUrl': 'https://t.me/durrat_al_mumin',
    'supportContact': 'support@durrat-al-mumin.app',
    'playStoreUrl': '',
    'homeCards': {
      'quranMushaf': true,
      'hadith': true,
      'jawamiDhikr': true,
      'shaarawi': true,
      'companions': true,
      'animeStories': true,
      'duaInAbsentia': true,
      'commitmentTree': true,
      'zakatCalc': true,
      'nisabCalc': true,
      'zakatBeneficiaries': true,
      'udhiyahBeneficiaries': true,
      'quranRadio': true,
      'hajjUmrah': true,
      'soulMedicine': true,
      'qibla': true,
      'nearestMosque': true,
      'morningEvening': true,
      'smartTasbeeh': true,
      'namesOfAllah': true,
      'prayerTimes': true,
    }
  };

  List<AnimeProphetStory> _remoteAnimeStories = [];
  List<ShaarawiLesson> _remoteShaarawiLessons = [];
  List<Map<String, dynamic>> _remoteBroadcasts = [];
  List<CompanionStory> _remoteCompanions = [];
  List<SoulRemedy> _remoteSoulRemedies = [];
  List<HadithItem> _remoteHadith = [];
  bool _isInitialized = false;

  /// Admin-added companion stories, split by section.
  List<CompanionStory> get remoteMenCompanions => _remoteCompanions
      .where((c) => c.category == CompanionCategory.men)
      .toList();
  List<CompanionStory> get remoteWomenCompanions => _remoteCompanions
      .where((c) => c.category == CompanionCategory.women)
      .toList();

  /// Admin-added soul remedies (feelings).
  List<SoulRemedy> get remoteSoulRemedies =>
      List<SoulRemedy>.unmodifiable(_remoteSoulRemedies);

  /// Admin-added hadith (shown first in the hadith library).
  List<HadithItem> get remoteHadith =>
      List<HadithItem>.unmodifiable(_remoteHadith);

  /// Admin broadcasts visible to users (newest first). A broadcast is shown
  /// when it is not archived and not explicitly disabled.
  List<Map<String, dynamic>> get activeBroadcasts => _remoteBroadcasts
      .where((b) =>
          (b['status']?.toString() ?? 'sent') != 'archived' &&
          b['isActive'] != false)
      .toList();

  Map<String, dynamic> get appConfig => _appConfig;
  Map<String, dynamic> get homeCards =>
      (_appConfig['homeCards'] as Map<String, dynamic>?) ?? {};

  /// Remote control getters
  bool get isMaintenanceMode => _appConfig['maintenanceMode'] == true;
  String get maintenanceMessage =>
      (_appConfig['maintenanceMessage'] ?? '').toString().trim().isNotEmpty
          ? _appConfig['maintenanceMessage'].toString()
          : 'التطبيق في صيانة مجدولة وسيعود قريباً بإذن الله.';
  String get featuredDhikr =>
      (_appConfig['featuredDhikr'] ?? '').toString().trim();
  String get minSupportedVersion =>
      (_appConfig['minSupportedVersion'] ?? '1.0.0').toString().trim();
  String get appVersion =>
      (_appConfig['appVersion'] ?? '1.0.0').toString().trim();
  String get forceUpdateUrl =>
      (_appConfig['forceUpdateUrl'] ?? '').toString().trim();
  String get telegramUrl =>
      (_appConfig['telegramUrl'] ?? '').toString().trim();
  String get supportContact =>
      (_appConfig['supportContact'] ?? '').toString().trim();
  String get playStoreUrl =>
      (_appConfig['playStoreUrl'] ?? '').toString().trim();

  Map<String, dynamic>? get popupAnnouncement {
    final p = _appConfig['popupAnnouncement'];
    if (p is Map<String, dynamic> && p['isActive'] == true) {
      final title = (p['title'] ?? '').toString().trim();
      final message = (p['message'] ?? '').toString().trim();
      if (title.isNotEmpty || message.isNotEmpty) return p;
    }
    return null;
  }

  /// Check if a specific home screen card is enabled
  bool isCardVisible(String cardKey) {
    final cards = homeCards;
    if (cards.containsKey(cardKey)) {
      return cards[cardKey] == true;
    }
    return true; // default visible
  }

  /// Manually force-refresh remote configuration from Firestore
  Future<void> refreshConfig() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('main')
          .get(const GetOptions(source: Source.serverAndCache));
      if (doc.exists && doc.data() != null) {
        _appConfig = doc.data()!;
        _saveLocalConfig();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Manual config refresh note: $e');
    }
  }

  /// Initialize service, load offline cache first, then subscribe to Firestore
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await _loadFromLocalCache();

    // Initialize Firebase in background & listen (with one delayed retry so
    // a cold-start race never leaves the dashboard feeds disconnected).
    unawaited(_connectWithRetry());
  }

  Future<void> _connectWithRetry() async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final initialized = await FirebaseAuthService.instance.initialize();
        if (initialized) {
          _subscribeToFirestore();
          return;
        }
      } catch (e) {
        debugPrint('RemoteContentService init note: $e');
      }
      await Future<void>.delayed(const Duration(seconds: 5));
    }
  }

  Future<void> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedConfig = prefs.getString(_configCacheKey);
      if (cachedConfig != null) {
        final decoded = jsonDecode(cachedConfig) as Map<String, dynamic>;
        _appConfig = decoded;
      }

      final cachedAnime = prefs.getString(_animeCacheKey);
      if (cachedAnime != null) {
        final list = jsonDecode(cachedAnime) as List<dynamic>;
        _remoteAnimeStories = list.map((item) => _parseAnimeStory(item as Map<String, dynamic>)).toList();
      }

      final cachedShaarawi = prefs.getString(_shaarawiCacheKey);
      if (cachedShaarawi != null) {
        final list = jsonDecode(cachedShaarawi) as List<dynamic>;
        _remoteShaarawiLessons = list.map((item) => _parseShaarawiLesson(item as Map<String, dynamic>)).toList();
      }
      notifyListeners();
    } catch (_) {}
  }

  void _subscribeToFirestore() {
    try {
      final firestore = FirebaseFirestore.instance;

      // 1. App Config & Home Cards
      firestore.collection('app_config').doc('main').snapshots().listen((doc) {
        if (doc.exists && doc.data() != null) {
          _appConfig = doc.data()!;
          _saveLocalConfig();
          notifyListeners();
        }
      }, onError: (err) {
        debugPrint('Firestore app_config sync note: $err');
      });

      // 2. Anime Stories Collection
      firestore.collection('anime_stories').limit(100).snapshots().listen((snap) {
        _remoteAnimeStories = snap.docs
            .map((d) => _parseAnimeStory(d.data(), fallbackId: d.id))
            .where((s) => s.isActive)
            .toList();
        _saveLocalAnime();
        notifyListeners();
      }, onError: (err) {
        debugPrint('Firestore anime_stories sync note: $err');
      });

      // 3. Shaarawi Lessons Collection
      firestore.collection('shaarawi_lessons').limit(100).snapshots().listen((snap) {
        if (snap.docs.isNotEmpty) {
          _remoteShaarawiLessons = snap.docs
              .map((d) => _parseShaarawiLesson(d.data(), fallbackId: d.id))
              .toList();
          _saveLocalShaarawi();
          notifyListeners();
        }
      }, onError: (err) {
        debugPrint('Firestore shaarawi_lessons sync note: $err');
      });

      // 4. Admin broadcasts (in-app banner). Empty collection keeps old cache.
      firestore.collection('broadcasts').limit(20).snapshots().listen((snap) {
        if (snap.docs.isNotEmpty) {
          _remoteBroadcasts = snap.docs.map((d) {
            final data = Map<String, dynamic>.from(d.data());
            data.putIfAbsent('id', () => d.id);
            return data;
          }).toList();
          notifyListeners();
        }
      }, onError: (err) {
        debugPrint('Firestore broadcasts sync note: $err');
      });

      // 5. Admin companion stories (appended to local lists).
      firestore.collection('companions').limit(120).snapshots().listen((snap) {
        if (snap.docs.isNotEmpty) {
          _remoteCompanions = snap.docs
              .map((d) => _parseCompanion(d.data(), fallbackId: d.id))
              .whereType<CompanionStory>()
              .toList();
          notifyListeners();
        }
      }, onError: (err) {
        debugPrint('Firestore companions sync note: $err');
      });

      // 6. Admin soul remedies (appended to local feelings).
      firestore.collection('soul_remedies').limit(80).snapshots().listen((snap) {
        if (snap.docs.isNotEmpty) {
          _remoteSoulRemedies = snap.docs
              .map((d) => _parseSoulRemedy(d.data(), fallbackId: d.id))
              .whereType<SoulRemedy>()
              .toList();
          notifyListeners();
        }
      }, onError: (err) {
        debugPrint('Firestore soul_remedies sync note: $err');
      });

      // 7. Admin hadith additions (shown first in the library).
      firestore.collection('hadith').limit(150).snapshots().listen((snap) {
        if (snap.docs.isNotEmpty) {
          _remoteHadith = snap.docs
              .map((d) => _parseHadith(d.data(), fallbackId: d.id))
              .whereType<HadithItem>()
              .toList();
          notifyListeners();
        }
      }, onError: (err) {
        debugPrint('Firestore hadith sync note: $err');
      });
    } catch (e) {
      debugPrint('Firestore subscribe note: $e');
    }
  }

  AnimeProphetStory _parseAnimeStory(Map<String, dynamic> data, {String? fallbackId}) {
    final catStr = data['category']?.toString() ?? 'quranSeries';
    final category = catStr == 'khalid' ? AnimeCategory.khalid : AnimeCategory.quranSeries;

    return AnimeProphetStory(
      id: data['id']?.toString() ?? fallbackId ?? 'anime_${DateTime.now().millisecondsSinceEpoch}',
      titleAr: data['titleAr']?.toString() ?? 'قصة أنمي',
      titleEn: data['titleEn']?.toString() ?? 'Anime Story',
      prophetNameAr: data['prophetNameAr']?.toString() ?? 'الأنبياء والصالحين',
      prophetNameEn: data['prophetNameEn']?.toString() ?? 'Prophets & Righteous',
      descriptionAr: data['descriptionAr']?.toString() ?? '',
      descriptionEn: data['descriptionEn']?.toString() ?? '',
      category: category,
      videoUrl: data['videoUrl']?.toString() ?? '',
      durationOrEpisodes: data['duration']?.toString() ?? '20:00',
      customThumbnail: data['customThumbnail']?.toString(),
      isFeatured: data['isFeatured'] == true,
      tag: data['tag']?.toString(),
      seriesId: data['seriesId']?.toString() ?? 'custom_series',
      seriesTitleAr: data['seriesTitleAr']?.toString() ?? 'سلسلة خاصة',
      seriesTitleEn: data['seriesTitleEn']?.toString() ?? 'Special Series',
      episodeNumber: data['episodeNumber'] is int ? data['episodeNumber'] : int.tryParse(data['episodeNumber']?.toString() ?? '1'),
      episodeTitleAr: data['titleAr']?.toString(),
      displayOrder: data['displayOrder'] is int ? data['displayOrder'] : int.tryParse(data['displayOrder']?.toString() ?? ''),
      seriesOrder: data['seriesOrder'] is int ? data['seriesOrder'] : int.tryParse(data['seriesOrder']?.toString() ?? ''),
      isActive: data['isActive'] != false,
    );
  }

  ShaarawiLesson _parseShaarawiLesson(Map<String, dynamic> data, {String? fallbackId}) {
    return ShaarawiLesson(
      id: data['id']?.toString() ?? fallbackId ?? 'les_${DateTime.now().millisecondsSinceEpoch}',
      titleAr: data['titleAr']?.toString() ?? 'خواطر الشيخ الشعراوي',
      titleEn: data['titleEn']?.toString() ?? 'Shaarawi Reflections',
      descriptionAr: data['descriptionAr']?.toString() ?? '',
      descriptionEn: data['descriptionEn']?.toString() ?? '',
      category: ShaarawiCategory.tafsir,
      videoUrl: data['videoUrl']?.toString() ?? '',
      duration: data['duration']?.toString() ?? '20:00',
      customThumbnail: data['customThumbnail']?.toString(),
      isFeatured: data['isFeatured'] == true,
      seriesId: data['seriesId']?.toString(),
      seriesTitleAr: data['seriesTitleAr']?.toString() ?? 'خواطر وتفسير',
      seriesTitleEn: data['seriesTitleEn']?.toString(),
      displayOrder: data['displayOrder'] is int ? data['displayOrder'] : int.tryParse(data['displayOrder']?.toString() ?? ''),
      seriesOrder: data['seriesOrder'] is int ? data['seriesOrder'] : int.tryParse(data['seriesOrder']?.toString() ?? ''),
    );
  }

  List<String> _strList(dynamic v) {
    if (v is List) {
      return v.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    }
    if (v is String && v.trim().isNotEmpty) {
      return v.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
    return const [];
  }

  int _asInt(dynamic v, int fallback) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? fallback;
  }

  int _asColor(dynamic v, int fallback) {
    if (v is int) return v;
    final parsed = int.tryParse(v?.toString() ?? '');
    return parsed ?? fallback;
  }

  CompanionStory? _parseCompanion(Map<String, dynamic> data, {String? fallbackId}) {
    try {
      if (data['isActive'] == false) return null;
      final catStr = data['category']?.toString() ?? 'men';
      return CompanionStory(
        id: data['id']?.toString() ?? fallbackId ?? 'comp_${DateTime.now().millisecondsSinceEpoch}',
        category: catStr == 'women' ? CompanionCategory.women : CompanionCategory.men,
        nameAr: data['nameAr']?.toString() ?? 'صحابي كريم',
        nameEn: data['nameEn']?.toString() ?? '',
        titleAr: data['titleAr']?.toString() ?? '',
        titleEn: data['titleEn']?.toString() ?? '',
        emoji: data['emoji']?.toString() ?? '⭐',
        summaryAr: data['summaryAr']?.toString() ?? '',
        summaryEn: data['summaryEn']?.toString() ?? '',
        storyAr: data['storyAr']?.toString() ?? '',
        storyEn: data['storyEn']?.toString() ?? '',
        lessonsAr: _strList(data['lessonsAr']),
        lessonsEn: _strList(data['lessonsEn']),
        famousQuoteAr: data['famousQuoteAr']?.toString() ?? '',
        famousQuoteEn: data['famousQuoteEn']?.toString() ?? '',
        readTimeMinutes: _asInt(data['readTimeMinutes'], 5),
        milestonesAr: _strList(data['milestonesAr']),
        milestonesEn: _strList(data['milestonesEn']),
        virtuesAr: _strList(data['virtuesAr']),
        virtuesEn: _strList(data['virtuesEn']),
      );
    } catch (e) {
      debugPrint('Companion parse note: $e');
      return null;
    }
  }

  SoulRemedy? _parseSoulRemedy(Map<String, dynamic> data, {String? fallbackId}) {
    try {
      if (data['isActive'] == false) return null;
      final ayahs = <QuranAyahItem>[];
      final rawAyahs = data['ayahs'];
      if (rawAyahs is List) {
        for (final a in rawAyahs) {
          if (a is Map) {
            ayahs.add(QuranAyahItem(
              ayah: a['ayah']?.toString() ?? '',
              surah: a['surah']?.toString() ?? '',
              translation: a['translation']?.toString() ?? '',
            ));
          }
        }
      }
      final duas = <PropheticDuaItem>[];
      final rawDuas = data['duas'];
      if (rawDuas is List) {
        for (final d in rawDuas) {
          if (d is Map) {
            duas.add(PropheticDuaItem(
              dua: d['dua']?.toString() ?? '',
              source: d['source']?.toString() ?? '',
              repeat: _asInt(d['repeat'], 1),
              note: d['note']?.toString() ?? '',
            ));
          }
        }
      }
      final rawGradients = data['gradientColors'];
      final gradInts = <int>[];
      if (rawGradients is List) {
        for (final g in rawGradients) {
          final v = g is int ? g : int.tryParse(g?.toString() ?? '');
          if (v != null) gradInts.add(v);
        }
      }

      return SoulRemedy(
        id: data['id']?.toString() ?? fallbackId ?? 'soul_${DateTime.now().millisecondsSinceEpoch}',
        feelingAr: data['feelingAr']?.toString() ?? 'شعور',
        feelingEn: data['feelingEn']?.toString() ?? '',
        emoji: data['emoji']?.toString() ?? '💚',
        descriptionAr: data['descriptionAr']?.toString() ?? '',
        subtitleAr: data['subtitleAr']?.toString() ?? '',
        categoryKey: data['categoryKey']?.toString() ?? 'all',
        accentColor: Color(_asColor(data['accentColor'], 0xFF059669)),
        gradientColors: gradInts.isNotEmpty
            ? gradInts.map((v) => Color(v)).toList()
            : const [Color(0xFF064E3B), Color(0xFF022C22)],
        ayahs: ayahs,
        duas: duas,
        solacePointsAr: _strList(data['solacePointsAr']),
        solacePointsEn: _strList(data['solacePointsEn']),
      );
    } catch (e) {
      debugPrint('Soul remedy parse note: $e');
      return null;
    }
  }

  HadithItem? _parseHadith(Map<String, dynamic> data, {String? fallbackId}) {
    try {
      if (data['isActive'] == false) return null;
      final arabic = data['arabic']?.toString() ?? '';
      if (arabic.trim().isEmpty) return null;
      return HadithItem(
        id: data['id']?.toString() ?? fallbackId ?? 'hadith_${DateTime.now().millisecondsSinceEpoch}',
        title: data['title']?.toString() ?? '',
        arabic: arabic,
        narrator: data['narrator']?.toString() ?? '',
        source: data['source']?.toString() ?? '',
        explanation: data['explanation']?.toString() ?? '',
        category: data['category']?.toString() ?? 'عام',
      );
    } catch (e) {
      debugPrint('Hadith parse note: $e');
      return null;
    }
  }

  Future<void> _saveLocalConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_configCacheKey, jsonEncode(_appConfig));
    } catch (_) {}
  }

  Future<void> _saveLocalAnime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _remoteAnimeStories.map((s) => {
        'id': s.id,
        'titleAr': s.titleAr,
        'titleEn': s.titleEn,
        'category': s.category.name,
        'videoUrl': s.videoUrl,
        'duration': s.durationOrEpisodes,
        'seriesTitleAr': s.seriesTitleAr,
        'episodeNumber': s.episodeNumber,
        'descriptionAr': s.descriptionAr,
        'isFeatured': s.isFeatured,
        'isActive': s.isActive,
        'displayOrder': s.displayOrder,
        'seriesOrder': s.seriesOrder,
      }).toList();
      await prefs.setString(_animeCacheKey, jsonEncode(list));
    } catch (_) {}
  }

  Future<void> _saveLocalShaarawi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _remoteShaarawiLessons.map((l) => {
        'id': l.id,
        'titleAr': l.titleAr,
        'titleEn': l.titleEn,
        'videoUrl': l.videoUrl,
        'duration': l.duration,
        'seriesTitleAr': l.seriesTitleAr,
        'isFeatured': l.isFeatured,
        'displayOrder': l.displayOrder,
        'seriesOrder': l.seriesOrder,
      }).toList();
      await prefs.setString(_shaarawiCacheKey, jsonEncode(list));
    } catch (_) {}
  }

  /// Get merged anime series groups (built-in + remote) — remote episodes
  /// that share an existing series title are merged into that series to
  /// avoid duplicate cards (e.g. adding "موسى — الجزء 1" to an existing
  /// "قصص الأنبياء" shelf).
  List<AnimeSeriesGroup> getAnimeSeriesGroups() {
    if (_remoteAnimeStories.isEmpty) {
      return animeSeriesGroups;
    }

    // Work on a mutable copy so we can merge in place.
    final result = List<AnimeSeriesGroup>.from(animeSeriesGroups);

    final Map<String, List<AnimeProphetStory>> remoteGroups = {};
    for (final story in _remoteAnimeStories) {
      final key = (story.seriesTitleAr ?? '').trim();
      final groupKey = key.isEmpty ? 'إضافات المشرف الحصرية' : key;
      remoteGroups.putIfAbsent(groupKey, () => []).add(story);
    }

    for (final entry in remoteGroups.entries) {
      final idx = result.indexWhere((g) => g.titleAr.trim() == entry.key);
      if (idx != -1) {
        final base = result[idx];
        // Merge without duplicating by id.
        final existingIds = base.episodes.map((e) => e.id).toSet();
        final toAdd = entry.value.where((e) => !existingIds.contains(e.id)).toList();
        if (toAdd.isEmpty) continue;
        result[idx] = AnimeSeriesGroup(
          id: base.id,
          titleAr: base.titleAr,
          titleEn: base.titleEn,
          descriptionAr: base.descriptionAr,
          descriptionEn: base.descriptionEn,
          badge: base.badge,
          category: base.category,
          episodes: [...base.episodes, ...toAdd],
        );
      } else {
        // Append new admin-added remote series in a stable position AFTER the
        // built-in series; their relative position is then fixed by the
        // seriesOrder sort below (nulls → placed last, stable order kept).
        result.add(
          AnimeSeriesGroup(
            id: 'remote_${entry.key.hashCode}',
            titleAr: entry.key,
            titleEn: entry.value.first.seriesTitleEn ?? 'Admin Exclusive Series',
            descriptionAr: 'سلسلة مضافة ومحدثة سحابياً من لوحة التحكم الإدارية',
            descriptionEn: 'Series added & updated via Admin Dashboard',
            badge: 'جديد 🌟',
            category: entry.value.first.category,
            episodes: entry.value,
          ),
        );
      }
    }

    // Sort episodes within each group by displayOrder → episodeNumber
    for (var i = 0; i < result.length; i++) {
      final g = result[i];
      final sorted = List<AnimeProphetStory>.from(g.episodes)
        ..sort((a, b) => (a.displayOrder ?? a.episodeNumber ?? 999).compareTo(b.displayOrder ?? b.episodeNumber ?? 999));
      bool same = sorted.length == g.episodes.length;
      if (same) {
        for (var j = 0; j < sorted.length; j++) {
          if (sorted[j].id != g.episodes[j].id) { same = false; break; }
        }
      }
      if (!same) {
        result[i] = AnimeSeriesGroup(
          id: g.id, titleAr: g.titleAr, titleEn: g.titleEn,
          descriptionAr: g.descriptionAr, descriptionEn: g.descriptionEn,
          badge: g.badge, category: g.category, episodes: sorted,
        );
      }
    }
    // Sort groups by seriesOrder (min of episodes' seriesOrder). Groups whose
    // episodes all lack seriesOrder (i.e. admin left "ترتيب السلسلة" empty)
    // are treated as 999999 → they fall AFTER ranked series while keeping a
    // stable order among themselves (Dart sort is not stable, so use the
    // original list index as tiebreaker).
    final originalOrder = <AnimeSeriesGroup, int>{
      for (var i = 0; i < result.length; i++) result[i]: i,
    };
    result.sort((a, b) {
      int ao = 999999, bo = 999999;
      for (final e in a.episodes) { if (e.seriesOrder != null && e.seriesOrder! < ao) ao = e.seriesOrder!; }
      for (final e in b.episodes) { if (e.seriesOrder != null && e.seriesOrder! < bo) bo = e.seriesOrder!; }
      if (ao != bo) {
        // Ranked series (seriesOrder set) come before unranked ones.
        if (ao == 999999) return 1;
        if (bo == 999999) return -1;
        return ao.compareTo(bo);
      }
      // Tie (both equal rank or both unranked): keep original order.
      return (originalOrder[a] ?? 0).compareTo(originalOrder[b] ?? 0);
    });

    return result;
  }

  /// Get merged Shaarawi series groups (built-in + remote) — same
  /// merge-and-sort logic as anime, so series / episode order is controllable.
  List<ShaarawiSeriesGroup> getShaarawiSeriesGroups() {
    if (_remoteShaarawiLessons.isEmpty) {
      return shaarawiSeriesGroups;
    }
    final result = List<ShaarawiSeriesGroup>.from(shaarawiSeriesGroups);
    final Map<String, List<ShaarawiLesson>> remoteGroups = {};
    for (final l in _remoteShaarawiLessons) {
      final key = (l.seriesTitleAr ?? '').trim();
      final gk = key.isEmpty ? 'خواطر وتفسير' : key;
      remoteGroups.putIfAbsent(gk, () => []).add(l);
    }
    for (final entry in remoteGroups.entries) {
      final idx = result.indexWhere((g) => g.titleAr.trim() == entry.key);
      if (idx != -1) {
        final base = result[idx];
        final existingIds = base.episodes.map((e) => e.id).toSet();
        final toAdd = entry.value.where((e) => !existingIds.contains(e.id)).toList();
        if (toAdd.isEmpty) continue;
        result[idx] = ShaarawiSeriesGroup(
          id: base.id, titleAr: base.titleAr, titleEn: base.titleEn,
          descriptionAr: base.descriptionAr, descriptionEn: base.descriptionEn,
          badge: base.badge, category: base.category,
          episodes: [...base.episodes, ...toAdd],
        );
      } else {
        result.insert(0, ShaarawiSeriesGroup(
          id: 'remote_${entry.key.hashCode}',
          titleAr: entry.key,
          titleEn: entry.value.first.seriesTitleEn ?? 'Admin Lessons',
          descriptionAr: 'دروس مضافة ومحدثة سحابياً من لوحة التحكم',
          descriptionEn: 'Lessons added via Admin Dashboard',
          badge: 'جديد 🌟',
          category: entry.value.first.category,
          episodes: entry.value,
        ));
      }
    }
    for (var i = 0; i < result.length; i++) {
      final g = result[i];
      final sorted = List<ShaarawiLesson>.from(g.episodes)
        ..sort((a, b) => (a.displayOrder ?? a.partNumber ?? 999).compareTo(b.displayOrder ?? b.partNumber ?? 999));
      bool same = sorted.length == g.episodes.length;
      if (same) for (var j = 0; j < sorted.length; j++) if (sorted[j].id != g.episodes[j].id) { same = false; break; }
      if (!same) {
        result[i] = ShaarawiSeriesGroup(
          id: g.id, titleAr: g.titleAr, titleEn: g.titleEn,
          descriptionAr: g.descriptionAr, descriptionEn: g.descriptionEn,
          badge: g.badge, category: g.category, episodes: sorted,
        );
      }
    }
    result.sort((a, b) {
      int ao = 999999, bo = 999999;
      for (final e in a.episodes) if (e.seriesOrder != null && e.seriesOrder! < ao) ao = e.seriesOrder!;
      for (final e in b.episodes) if (e.seriesOrder != null && e.seriesOrder! < bo) bo = e.seriesOrder!;
      if (ao != 999999 || bo != 999999) return ao.compareTo(bo);
      return 0;
    });
    return result;
  }
}
