import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/anime_stories_data.dart';
import '../data/shaarawi_data.dart';
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
    'maintenanceMessage': '',
    'homeCards': {
      'shaarawi': true,
      'companions': true,
      'animeStories': true,
      'quranRadio': true,
      'soulMedicine': true,
      'commitmentTree': true,
      'namesOfAllah': true,
      'morningEvening': true,
      'smartTasbeeh': true,
      'prayerTimes': true,
    }
  };

  List<AnimeProphetStory> _remoteAnimeStories = [];
  List<ShaarawiLesson> _remoteShaarawiLessons = [];
  bool _isInitialized = false;

  Map<String, dynamic> get appConfig => _appConfig;
  Map<String, dynamic> get homeCards =>
      (_appConfig['homeCards'] as Map<String, dynamic>?) ?? {};

  /// Check if a specific home screen card is enabled
  bool isCardVisible(String cardKey) {
    final cards = homeCards;
    if (cards.containsKey(cardKey)) {
      return cards[cardKey] == true;
    }
    return true; // default visible
  }

  /// Initialize service, load offline cache first, then subscribe to Firestore
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await _loadFromLocalCache();

    // Initialize Firebase in background & listen
    try {
      final initialized = await FirebaseAuthService.instance.initialize();
      if (initialized) {
        _subscribeToFirestore();
      }
    } catch (e) {
      debugPrint('RemoteContentService init note: $e');
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
      firestore.collection('anime_stories').snapshots().listen((snap) {
        if (snap.docs.isNotEmpty) {
          _remoteAnimeStories = snap.docs
              .map((d) => _parseAnimeStory(d.data(), fallbackId: d.id))
              .where((s) => s.isActive)
              .toList();
          _saveLocalAnime();
          notifyListeners();
        }
      }, onError: (err) {
        debugPrint('Firestore anime_stories sync note: $err');
      });

      // 3. Shaarawi Lessons Collection
      firestore.collection('shaarawi_lessons').snapshots().listen((snap) {
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
    );
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
      }).toList();
      await prefs.setString(_shaarawiCacheKey, jsonEncode(list));
    } catch (_) {}
  }

  /// Get merged anime series groups (built-in + remote)
  List<AnimeSeriesGroup> getAnimeSeriesGroups() {
    if (_remoteAnimeStories.isEmpty) {
      return animeSeriesGroups;
    }

    final result = List<AnimeSeriesGroup>.from(animeSeriesGroups);

    final Map<String, List<AnimeProphetStory>> remoteGroups = {};
    for (final story in _remoteAnimeStories) {
      final groupKey = story.seriesTitleAr ?? 'إضافات المشرف الحصرية';
      remoteGroups.putIfAbsent(groupKey, () => []).add(story);
    }

    for (final entry in remoteGroups.entries) {
      result.insert(
        0,
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

    return result;
  }

  /// Get merged Shaarawi series groups (built-in + remote)
  List<ShaarawiSeriesGroup> getShaarawiSeriesGroups() {
    if (_remoteShaarawiLessons.isEmpty) {
      return shaarawiSeriesGroups;
    }

    final result = List<ShaarawiSeriesGroup>.from(shaarawiSeriesGroups);
    result.insert(
      0,
      ShaarawiSeriesGroup(
        id: 'remote_shaarawi_group',
        titleAr: 'دروس مضافة حديثاً من الإدارة',
        titleEn: 'Recently Added Lessons',
        descriptionAr: 'خواطر ودروس حصرية محدثة سحابياً عبر لوحة الإدارة',
        descriptionEn: 'Exclusive lessons updated remotely via Admin Dashboard',
        badge: 'تحديث سحابي ☁️',
        category: ShaarawiCategory.tafsir,
        episodes: _remoteShaarawiLessons,
      ),
    );
    return result;
  }
}
