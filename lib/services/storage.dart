import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../types/adhkar.dart';
import '../data/adhkar.dart';

/// Central persistence layer for the DHIKR app.
///
/// All reading/writing of persisted state goes through this class. Components
/// must NOT access SharedPreferences (or any other storage) directly — they
/// interact with [DhikrStorage] only. This keeps storage concerns isolated and
/// makes the persistence behavior testable with an in-memory backend.
class DhikrStorage {
  DhikrStorage._(this._prefs);

  SharedPreferences? _prefs;

  /// Whether the storage backend is available. When null (e.g. in a pure Dart
  /// test environment) the app falls back to in-memory maps so it never crashes.
  bool get isAvailable => _prefs != null;

  static const _todayProgressKey = 'adhkar.today_progress';
  static const _historyKey = 'adhkar.history';
  static const _settingsKey = 'adhkar.settings';

  /// In-memory fallback used when SharedPreferences is unavailable.
  final Map<String, String> _memory = {};

  /// Creates the storage layer. If [prefs] is omitted, an in-memory backend is
  /// used (useful for unit tests and unsupported platforms).
  factory DhikrStorage({SharedPreferences? prefs}) {
    return DhikrStorage._(prefs);
  }

  Future<void> init() async {
    if (_prefs == null) {
      try {
        _prefs = await SharedPreferences.getInstance().timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw TimeoutException('SharedPreferences init timeout'),
        );
      } catch (_) {
        // Fallback for test environments without plugin binding
      }
    }
  }

  String _get(String key) {
    final p = _prefs;
    if (p != null) {
      return p.getString(key) ?? '';
    }
    return _memory[key] ?? '';
  }

  Future<void> _set(String key, String value) async {
    final p = _prefs;
    if (p != null) {
      await p.setString(key, value);
    } else {
      _memory[key] = value;
    }
  }

  /// ---- TODAY PROGRESS ----------------------------------------------------

  /// Storage shape for one category's per-dhikr progress within a day.
  ///
  /// A session is keyed by the local calendar date. Each category stores a map
  /// of {dhikrId: repetitions complete}.
  Map<String, dynamic> _buildDayState() {
    final stored = _get(_todayProgressKey);
    if (stored.isEmpty) return {};
    try {
      final decoded = jsonDecode(stored);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // Corrupt — treat as empty.
    }
    return {};
  }

  /// Returns today's progress for [category] as {dhikrId: completedCount}.
  /// The counter is clipped so a stored value can never exceed the target.
  Map<String, int> getTodayProgress(DhikrCategory category) {
    final today = localTodayIso();
    final day = _buildDayState();
    final categoryMap = day['day'] == today
        ? (day['categories'] is Map<String, dynamic>
            ? (day['categories'] as Map<String, dynamic>)[category.id]
            : null)
        : null;
    if (categoryMap is! Map<String, dynamic>) return {};

    final targets = buildTargets(category);
    final result = <String, int>{};
    categoryMap.forEach((id, value) {
      final target = targets[id];
      var count = value is num ? value.toInt() : 0;
      if (target != null && count > target) count = target;
      if (count > 0) result[id] = count;
    });
    return result;
  }

  Map<String, int> buildTargets(DhikrCategory category) {
    final list = switch (category) {
      DhikrCategory.morning => morningAdhkar,
      DhikrCategory.evening => eveningAdhkar,
      DhikrCategory.ruqyah => ruqyahAdhkar,
      DhikrCategory.sleep => sleepAdhkar,
      DhikrCategory.waking => wakingAdhkar,
      DhikrCategory.afterPrayer => afterPrayerAdhkar,
      DhikrCategory.tasbeeh => tasbeehAdhkar,
    };
    return {for (final d in list) d.id: d.repeat};
  }

  /// Persists the per-dhikr progress for [category] on today's date.
  Future<void> saveDhikrProgress(DhikrCategory category, Map<String, int> progress) async {
    final today = localTodayIso();
    final day = _buildDayState();
    final isSameDay = day['day'] == today;
    final categories = <String, dynamic>{
      if (isSameDay && day['categories'] is Map<String, dynamic>)
        ...(day['categories'] as Map<String, dynamic>),
    };
    categories[category.id] = {
      for (final e in progress.entries) if (e.value > 0) e.key: e.value,
    };
    day['day'] = today;
    day['categories'] = categories;
    await _set(_todayProgressKey, jsonEncode(day));
  }

  /// Clears today's progress for both categories (keeps history intact).
  Future<void> resetTodayProgress() async {
    await _set(_todayProgressKey, jsonEncode({'day': localTodayIso(), 'categories': {}}));
  }

  /// ---- HISTORY -----------------------------------------------------------

  Map<String, dynamic> _buildHistory() {
    final stored = _get(_historyKey);
    if (stored.isEmpty) return {};
    try {
      final decoded = jsonDecode(stored);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return {};
  }

  /// Returns the last [limit] days of progress, newest first. Each entry is
  /// {date, morning: {completed,total}, evening: {completed,total}}.
  List<Map<String, dynamic>> getHistory({int limit = 30}) {
    final history = _buildHistory();
    final entries = history.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    final result = <Map<String, dynamic>>[];
    for (final e in entries) {
      final value = e.value;
      if (value is Map<String, dynamic>) {
        final morning = _categorySummary(value['morning']);
        final evening = _categorySummary(value['evening']);
        result.add({
          'date': e.key,
          'morning': morning,
          'evening': evening,
        });
      }
      if (result.length >= limit) break;
    }
    return result;
  }

  Map<String, int> _categorySummary(dynamic v) {
    if (v is! Map<String, dynamic>) {
      return {'completed': 0, 'total': 0};
    }
    final completed = (v['completed'] as num?)?.toInt() ?? 0;
    final total = (v['total'] as num?)?.toInt() ?? 0;
    return {'completed': completed, 'total': total};
  }

  /// Records the current day into history, computing completed/total snapshots.
  Future<void> commitDayToHistory() async {
    final today = localTodayIso();
    final day = _buildDayState();
    if (day['day'] != today) return;
    final categories = day['categories'] is Map<String, dynamic>
        ? day['categories'] as Map<String, dynamic>
        : <String, dynamic>{};
    final history = _buildHistory();

    final morningProgress = _decodeCategoryProgress(
        categories[DhikrCategory.morning.id], DhikrCategory.morning);
    final eveningProgress = _decodeCategoryProgress(
        categories[DhikrCategory.evening.id], DhikrCategory.evening);

    // Keep full per-id counts for the current day's view but store snapshots
    // for history (today row updated in place, yesterday kept).
    final todayEntry = {
      'morning': _snapshot(morningProgress, DhikrCategory.morning),
      'evening': _snapshot(eveningProgress, DhikrCategory.evening),
    };
    history[today] = todayEntry;

    await _set(_historyKey, jsonEncode(history));
  }

  Map<String, dynamic> _snapshot(Map<String, int> progress, DhikrCategory cat) {
    final targets = buildTargets(cat);
    var completed = 0;
    targets.forEach((id, target) {
      final v = progress[id] ?? 0;
      if (v >= target) completed++;
    });
    return {'completed': completed, 'total': targets.length};
  }

  Map<String, int> _decodeCategoryProgress(dynamic v, DhikrCategory cat) {
    final result = <String, int>{};
    if (v is! Map<String, dynamic>) return result;
    final targets = buildTargets(cat);
    v.forEach((id, value) {
      final target = targets[id];
      var count = value is num ? value.toInt() : 0;
      if (target != null && count > target) count = target;
      if (count > 0) result[id] = count;
    });
    return result;
  }

  /// ---- SETTINGS ----------------------------------------------------------

  AppSettings getSettings() {
    final stored = _get(_settingsKey);
    if (stored.isEmpty) return const AppSettings();
    try {
      final decoded = jsonDecode(stored);
      if (decoded is Map<String, dynamic>) {
        final lang = decoded['language'];
        final theme = decoded['themeMode'];
        final audio = decoded['audioEnabled'];
        final chosen = decoded['hasChosenLanguage'];
        return AppSettings(
          language: lang is String && lang == 'english'
              ? AppLanguage.english
              : AppLanguage.arabic,
          themeMode: _parseTheme(theme),
          audioEnabled: audio is bool ? audio : true,
          hasChosenLanguage: chosen is bool ? chosen : false,
        );
      }
    } catch (_) {}
    return const AppSettings();
  }

  ThemeModeSetting _parseTheme(dynamic v) {
    if (v is String) {
      if (v == 'dark') return ThemeModeSetting.dark;
      if (v == 'light') return ThemeModeSetting.light;
      if (v == 'system') return ThemeModeSetting.system;
    }
    return ThemeModeSetting.system;
  }

  Future<void> saveSettings(AppSettings settings) async {
    final encoded = jsonEncode({
      'language': settings.language == AppLanguage.english ? 'english' : 'arabic',
      'themeMode': _themeId(settings.themeMode),
      'audioEnabled': settings.audioEnabled,
      'hasChosenLanguage': settings.hasChosenLanguage,
    });
    await _set(_settingsKey, encoded);
  }

  String _themeId(ThemeModeSetting m) => switch (m) {
        ThemeModeSetting.system => 'system',
        ThemeModeSetting.light => 'light',
        ThemeModeSetting.dark => 'dark',
      };

  /// ---- USER PROFILE -----------------------------------------------------
  static const _userProfileKey = 'adhkar.user_profile';

  Map<String, String>? getUserProfile() {
    final stored = _get(_userProfileKey);
    if (stored.isEmpty) return null;
    try {
      final decoded = jsonDecode(stored);
      if (decoded is Map) {
        return {
          'name': decoded['name']?.toString() ?? '',
          'email': decoded['email']?.toString() ?? '',
          'phone': decoded['phone']?.toString() ?? '',
          'photo': decoded['photo']?.toString() ?? '',
          'authProvider': decoded['authProvider']?.toString() ?? '',
        };
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveUserProfile({
    required String name,
    required String email,
    String phone = '',
    String photo = '',
    String authProvider = 'email',
  }) async {
    final encoded = jsonEncode({
      'name': name,
      'email': email,
      'phone': phone,
      'photo': photo,
      'authProvider': authProvider,
    });
    await _set(_userProfileKey, encoded);
  }

  Future<void> clearUserProfile() async {
    await _set(_userProfileKey, '');
  }

  /// ---- LOCATION ----------------------------------------------------------
  static const _locationKey = 'adhkar.location';

  Map<String, dynamic>? getSavedLocation() {
    final stored = _get(_locationKey);
    if (stored.isEmpty) return null;
    try {
      final decoded = jsonDecode(stored);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveLocation({
    required double lat,
    required double lng,
    required String cityAr,
    required String cityEn,
    String? countryAr,
    String? countryEn,
  }) async {
    final encoded = jsonEncode({
      'lat': lat,
      'lng': lng,
      'cityAr': cityAr,
      'cityEn': cityEn,
      'countryAr': countryAr ?? '',
      'countryEn': countryEn ?? '',
    });
    await _set(_locationKey, encoded);
  }

  /// ---- ADHAN PREFERENCE --------------------------------------------------
  static const _adhanIndexKey = 'adhkar.adhan_index';

  int getSavedAdhanIndex() {
    final stored = _get(_adhanIndexKey);
    if (stored.isEmpty) return 0;
    return int.tryParse(stored) ?? 0;
  }

  Future<void> saveAdhanIndex(int index) async {
    await _set(_adhanIndexKey, index.toString());
  }

  /// ---- PRAYER TASKS TRACKER ---------------------------------------------
  static const _prayerTasksKeyPrefix = 'adhkar.prayer_tasks.';

  Set<String> getPrayerTasksForDate(String dateIso) {
    final stored = _get('$_prayerTasksKeyPrefix$dateIso');
    if (stored.isEmpty) return <String>{};
    try {
      final list = jsonDecode(stored);
      if (list is List) {
        return list.map((e) => e.toString()).toSet();
      }
    } catch (_) {}
    return <String>{};
  }

  Future<void> savePrayerTasksForDate(String dateIso, Set<String> completedPrayers) async {
    final encoded = jsonEncode(completedPrayers.toList());
    await _set('$_prayerTasksKeyPrefix$dateIso', encoded);
  }

  Map<int, Set<String>> getMonthlyPrayerTasks(int year, int month) {
    final Map<int, Set<String>> result = {};
    for (int day = 1; day <= 31; day++) {
      final dateIso = '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final tasks = getPrayerTasksForDate(dateIso);
      if (tasks.isNotEmpty) {
        result[day] = tasks;
      }
    }
    return result;
  }

  /// ---- NAWAFIL & SUNAN TASKS TRACKER -----------------------------------
  static const _nawafilTasksKeyPrefix = 'adhkar.nawafil_tasks.';

  Set<String> getNawafilTasksForDate(String dateIso) {
    final stored = _get('$_nawafilTasksKeyPrefix$dateIso');
    if (stored.isEmpty) return <String>{};
    try {
      final list = jsonDecode(stored);
      if (list is List) {
        return list.map((e) => e.toString()).toSet();
      }
    } catch (_) {}
    return <String>{};
  }

  Future<void> saveNawafilTasksForDate(String dateIso, Set<String> completedNawafil) async {
    final encoded = jsonEncode(completedNawafil.toList());
    await _set('$_nawafilTasksKeyPrefix$dateIso', encoded);
  }

  Map<int, Set<String>> getMonthlyNawafilTasks(int year, int month) {
    final Map<int, Set<String>> result = {};
    for (int day = 1; day <= 31; day++) {
      final dateIso = '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final tasks = getNawafilTasksForDate(dateIso);
      if (tasks.isNotEmpty) {
        result[day] = tasks;
      }
    }
    return result;
  }


  /// ---- STREAK / ACTIVITY TRACKER ---------------------------------------
  static const _streakCountKey = 'adhkar.streak_count';
  static const _streakLastDateKey = 'adhkar.streak_last_date';

  ({int streak, String lastDate}) getStreakInfo() {
    final count = int.tryParse(_get(_streakCountKey)) ?? 0;
    final lastDate = _get(_streakLastDateKey);
    return (streak: count, lastDate: lastDate);
  }

  Future<void> saveStreakInfo(int streak, String lastDate) async {
    await _set(_streakCountKey, streak.toString());
    await _set(_streakLastDateKey, lastDate);
  }


  /// ---- MOMENT / SAKAN (خريطة السَّكَن) ----------------------------------
  ///
  /// A manual daily self-rating (1..5) of stress/calm — the user's own sense
  /// of how settled their heart felt that day. Stored as {date: rating} so the
  /// weekly pattern can correlate consistency (from history) with the mood.
  static const _sakanMoodKey = 'adhkar.sakan_mood';

  Map<String, dynamic> _buildMoodMap() {
    final stored = _get(_sakanMoodKey);
    if (stored.isEmpty) return {};
    try {
      final decoded = jsonDecode(stored);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return {};
  }

  /// The mood rating (1..5) the user set for [dateIso], or 0 if none yet.
  int getMoodRatingFor(String dateIso) {
    final v = _buildMoodMap()[dateIso];
    return v is num ? v.toInt().clamp(1, 5) : 0;
  }

  /// Mood ratings for the most recent [limit] days, oldest first. Each entry
  /// is {date, rating} where rating is 0 when the user never rated that day.
  List<Map<String, dynamic>> getMoodHistory({int limit = 30}) {
    final map = _buildMoodMap();
    final dates = map.keys.toList()..sort();
    final result = <Map<String, dynamic>>[];
    for (final d in dates) {
      if (result.length >= limit) break;
      final v = map[d];
      result.add({
        'date': d,
        'rating': v is num ? v.toInt().clamp(1, 5) : 0,
      });
    }
    return result.reversed.toList();
  }

  /// Today's mood rating (1..5) or 0 if not yet set.
  int getTodayMoodRating() => getMoodRatingFor(localTodayIso());

  Future<void> saveMoodRating(int rating, {String? dateIso}) async {
    final date = dateIso ?? localTodayIso();
    final map = _buildMoodMap();
    map[date] = rating.clamp(1, 5);
    await _set(_sakanMoodKey, jsonEncode(map));
  }


  /// ---- APP VERSION FOR ONBOARDING RESET -----------------------------------
  static const _appVersionKey = 'adhkar.app_version';

  int getSavedAppVersion() {
    final v = _get(_appVersionKey);
    if (v.isEmpty) return 0;
    return int.tryParse(v) ?? 0;
  }

  Future<void> saveAppVersion(int version) async {
    await _set(_appVersionKey, version.toString());
  }

  /// ---- CLEAR ALL DATA (RESET APP) -----------------------------------------
  Future<void> clearAllData() async {
    final prefs = _prefs;
    if (prefs != null) {
      await prefs.clear();
    }
    _memory.clear();
  }

  /// ---- ONBOARDING & PERMISSIONS SETUP ------------------------------------
  static const _onboardingCompletedKey = 'adhkar.onboarding_completed';
  static const _permissionsSetupCompletedKey = 'adhkar.permissions_setup_completed';

  bool hasCompletedOnboarding() {
    return _get(_onboardingCompletedKey) == 'true';
  }

  Future<void> setOnboardingCompleted(bool value) async {
    await _set(_onboardingCompletedKey, value ? 'true' : 'false');
  }

  bool hasCompletedPermissionsSetup() {
    return _get(_permissionsSetupCompletedKey) == 'true';
  }

  Future<void> setPermissionsSetupCompleted(bool value) async {
    await _set(_permissionsSetupCompletedKey, value ? 'true' : 'false');
  }

  /// ---- HELPERS -----------------------------------------------------------

  /// "اليوم" الفعلي للأذكار: يبدأ من الساعة 2:00 صباحاً بدل منتصف الليل.
  /// قبل 2 صباحاً يُحتسب التاريخ تابعاً لليوم السابق حتى لا تتصفّر الأذكار
  /// عند منتصف الليل أثناء السهر/القيام.
  static String localTodayIso() {
    final now = DateTime.now();
    final effective = now.hour < 2
        ? now.subtract(const Duration(days: 1))
        : now;
    final y = effective.year.toString().padLeft(4, '0');
    final m = effective.month.toString().padLeft(2, '0');
    final d = effective.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
