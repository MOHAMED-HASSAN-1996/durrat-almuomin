import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/content_validation.dart';
import '../services/adhkar_remote_service.dart';
import '../services/storage.dart';
import '../types/adhkar.dart';

/// Application-wide state root. Holds settings, today's progress per category,
/// theme mode, and language. Persists through [DhikrStorage].
class AppState extends ChangeNotifier {
  AppState({DhikrStorage? storage}) : _storage = storage ?? DhikrStorage() {
    _settings = _storage.getSettings();
  }

  final DhikrStorage _storage;

  AppSettings _settings = const AppSettings();
  AppSettings get settings => _settings;

  AppLanguage get language => _settings.language;
  ThemeModeSetting get themeMode => _settings.themeMode;
  bool get audioEnabled => _settings.audioEnabled;
  bool get hasChosenLanguage => _settings.hasChosenLanguage;

  // Cache onboarding status to avoid repeated storage reads
  bool? _cachedHasCompletedOnboarding;
  bool get hasCompletedOnboarding =>
      _cachedHasCompletedOnboarding ?? _storage.hasCompletedOnboarding();

  bool? _cachedHasCompletedPermissionsSetup;
  bool get hasCompletedPermissionsSetup =>
      _cachedHasCompletedPermissionsSetup ??
      _storage.hasCompletedPermissionsSetup();

  DhikrStorage get storage => _storage;

  /// Today's progress maps (dhikrId -> repetitions completed) per category.
  final Map<DhikrCategory, Map<String, int>> _todayProgress = {
    for (final c in DhikrCategory.values) c: <String, int>{},
  };

  Map<String, String>? _userProfile;
  Map<String, String>? get userProfile => _userProfile;
  bool get isLoggedIn =>
      _userProfile != null && (_userProfile!['name']?.isNotEmpty ?? false);

  Set<String> _todayPrayerTasks = {};
  Set<String> get todayPrayerTasks => Set.unmodifiable(_todayPrayerTasks);
  bool isPrayerTaskCompleted(String prayerKey) =>
      _todayPrayerTasks.contains(prayerKey);
  int get completedPrayerTasksCount => _todayPrayerTasks.length;

  // ── Nawafil Tasks ────────────────────────────────────────────────────────
  Set<String> _todayNawafilTasks = {};
  Set<String> get todayNawafilTasks => Set.unmodifiable(_todayNawafilTasks);
  int get completedNawafilTasksCount => _todayNawafilTasks.length;
  bool isNawafilTaskCompleted(String keyId) =>
      _todayNawafilTasks.contains(keyId);

  Future<void> toggleNawafilTask(String keyId) async {
    final todayIso = DhikrStorage.localTodayIso();
    await toggleNawafilTaskForDate(todayIso, keyId);
  }

  Future<void> toggleNawafilTaskForDate(String dateIso, String keyId) async {
    final tasks = _storage.getNawafilTasksForDate(dateIso);
    if (tasks.contains(keyId)) {
      tasks.remove(keyId);
    } else {
      tasks.add(keyId);
      _recordActivityToday();
    }
    await _storage.saveNawafilTasksForDate(dateIso, tasks);
    if (dateIso == DhikrStorage.localTodayIso()) {
      _todayNawafilTasks = Set.from(tasks);
    }
    notifyListeners();
  }

  Set<String> getNawafilTasksForDate(String dateIso) =>
      _storage.getNawafilTasksForDate(dateIso);

  Map<int, Set<String>> getMonthlyNawafilTasks(int year, int month) =>
      _storage.getMonthlyNawafilTasks(year, month);

  Future<void> togglePrayerTaskForDate(String dateIso, String prayerKey) async {
    final tasks = _storage.getPrayerTasksForDate(dateIso);
    if (tasks.contains(prayerKey)) {
      tasks.remove(prayerKey);
    } else {
      tasks.add(prayerKey);
      _recordActivityToday();
    }
    await _storage.savePrayerTasksForDate(dateIso, tasks);
    if (dateIso == DhikrStorage.localTodayIso()) {
      _todayPrayerTasks = Set.from(tasks);
    }
    notifyListeners();
  }

  Set<String> getPrayerTasksForDate(String dateIso) =>
      _storage.getPrayerTasksForDate(dateIso);

  int _streakCount = 1;
  int get streakCount => _streakCount;

  Map<int, Set<String>> getMonthlyPrayerTasks(int year, int month) =>
      _storage.getMonthlyPrayerTasks(year, month);

  bool _loaded = false;
  bool get loaded => _loaded;
  String _loadedDayIso = '';

  /// Loads persisted state from storage. Safe to call multiple times.
  Future<void> load() async {
    await _storage.init();
    _settings = _storage.getSettings();
    _userProfile = _storage.getUserProfile();

    // Force re-onboarding if app was updated (version mismatch)
    const currentVersion =
        4; // Re-run onboarding and permissions after the adhan reliability update.
    final savedVersion = _storage.getSavedAppVersion();
    if (savedVersion < currentVersion) {
      // New install or app updated - clear old onboarding state
      await _storage.setOnboardingCompleted(false);
      await _storage.setPermissionsSetupCompleted(false);
      await _storage.saveAppVersion(currentVersion);
    }
    for (final category in DhikrCategory.values) {
      _todayProgress[category] = _storage.getTodayProgress(category);
    }

    final todayIso = DhikrStorage.localTodayIso();
    _loadedDayIso = todayIso;
    _todayPrayerTasks = _storage.getPrayerTasksForDate(todayIso);
    _todayNawafilTasks = _storage.getNawafilTasksForDate(todayIso);

    final streakInfo = _storage.getStreakInfo();
    _calculateStreak(streakInfo.streak, streakInfo.lastDate, todayIso);

    // Cache onboarding and permissions status
    _cachedHasCompletedOnboarding = _storage.hasCompletedOnboarding();
    _cachedHasCompletedPermissionsSetup = _storage
        .hasCompletedPermissionsSetup();

    // Remote adhkar feed (admin dashboard). Non-blocking: screens keep
    // working on built-in content until the first remote snapshot lands.
    AdhkarRemoteService.instance.addListener(_onRemoteAdhkar);
    unawaited(AdhkarRemoteService.instance.restore());

    _loaded = true;
    notifyListeners();
  }

  void _onRemoteAdhkar() {
    if (!_loaded) return;
    notifyListeners();
  }

  /// يُستدعى عند عودة التطبيق للواجهة: لو تجاوزنا الساعة 2 صباحاً ليوم جديد
  /// يُصفّر تقدّم الأذكار ومهام الصلاة تلقائياً بدون تدخل المستخدم.
  Future<void> checkDayRollover() async {
    if (!_loaded) return;
    final todayIso = DhikrStorage.localTodayIso();
    if (todayIso == _loadedDayIso) return;
    _loadedDayIso = todayIso;
    for (final category in DhikrCategory.values) {
      _todayProgress[category] = _storage.getTodayProgress(category);
    }
    _todayPrayerTasks = _storage.getPrayerTasksForDate(todayIso);
    _todayNawafilTasks = _storage.getNawafilTasksForDate(todayIso);
    final streakInfo = _storage.getStreakInfo();
    _calculateStreak(streakInfo.streak, streakInfo.lastDate, todayIso);
    notifyListeners();
  }

  Future<void> togglePrayerTask(String prayerKey) async {
    final todayIso = DhikrStorage.localTodayIso();
    if (_todayPrayerTasks.contains(prayerKey)) {
      _todayPrayerTasks.remove(prayerKey);
    } else {
      _todayPrayerTasks.add(prayerKey);
      _recordActivityToday();
    }
    await _storage.savePrayerTasksForDate(todayIso, _todayPrayerTasks);
    notifyListeners();
  }

  void _calculateStreak(int savedStreak, String lastDate, String todayIso) {
    if (lastDate.isEmpty) {
      _streakCount = 1;
      _storage.saveStreakInfo(1, todayIso);
      return;
    }
    if (lastDate == todayIso) {
      _streakCount = savedStreak > 0 ? savedStreak : 1;
      return;
    }
    final last = DateTime.tryParse(lastDate);
    final today = DateTime.tryParse(todayIso);
    if (last != null && today != null) {
      final diff = today.difference(last).inDays;
      if (diff == 1) {
        _streakCount = savedStreak + 1;
      } else if (diff > 1) {
        _streakCount = 1;
      } else {
        _streakCount = savedStreak > 0 ? savedStreak : 1;
      }
    } else {
      _streakCount = 1;
    }
    _storage.saveStreakInfo(_streakCount, todayIso);
  }

  void _recordActivityToday() {
    final todayIso = DhikrStorage.localTodayIso();
    final streakInfo = _storage.getStreakInfo();
    if (streakInfo.lastDate != todayIso) {
      _calculateStreak(streakInfo.streak, streakInfo.lastDate, todayIso);
    }
  }

  Future<void> saveUserProfile({
    required String name,
    required String email,
    String phone = '',
    String authProvider = 'email',
    String? photo,
  }) async {
    await _storage.saveUserProfile(
      name: name,
      email: email,
      phone: phone,
      photo: photo ?? '',
      authProvider: authProvider,
    );
    _userProfile = _storage.getUserProfile();
    notifyListeners();
  }

  Future<void> logoutUser() async {
    await _storage.clearUserProfile();
    _userProfile = null;
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    await _storage.clearUserProfile();
    _userProfile = null;
    notifyListeners();
  }

  /// The Dhikr list for a category (validated, malformed items dropped).
  /// Prefers the admin-managed remote feed when enabled; always falls back
  /// to the built-in lists offline or on any sync failure.
  List<Dhikr> adhkarFor(DhikrCategory category) {
    try {
      return AdhkarRemoteService.instance.adhkarFor(category);
    } catch (_) {
      return getBuiltInAdhkar(category);
    }
  }

  /// Current repetition count for a specific dhikr id.
  int countFor(DhikrCategory category, String dhikrId) {
    return _todayProgress[category]?[dhikrId] ?? 0;
  }

  /// Whether a specific dhikr is complete. Unknown ids are never complete.
  bool isDhikrComplete(DhikrCategory category, String dhikrId) {
    for (final d in adhkarFor(category)) {
      if (d.id == dhikrId) {
        return countFor(category, dhikrId) >= d.repeat;
      }
    }
    return false;
  }

  /// Increments the counter for a dhikr, clamped at the immutable target.
  ///
  /// Passing `delta` as a small negative value is not supported (counters only
  /// move forward in the reading experience). Guarantees current never exceeds
  /// repeat. Returns the new count.
  int increment(DhikrCategory category, String dhikrId) {
    final list = adhkarFor(category);
    Dhikr target;
    try {
      target = list.firstWhere((d) => d.id == dhikrId);
    } catch (_) {
      return countFor(category, dhikrId);
    }
    final current = countFor(category, dhikrId);
    final next = current >= target.repeat ? target.repeat : current + 1;
    _todayProgress[category]![dhikrId] = next;
    unawaited(_storage.saveDhikrProgress(category, _todayProgress[category]!));
    notifyListeners();
    return next;
  }

  /// Decrements the counter for a dhikr (undo last tap), floored at zero.
  /// Returns the new count.
  int decrement(DhikrCategory category, String dhikrId) {
    final current = countFor(category, dhikrId);
    final next = current <= 0 ? 0 : current - 1;
    _todayProgress[category]![dhikrId] = next;
    unawaited(_storage.saveDhikrProgress(category, _todayProgress[category]!));
    notifyListeners();
    return next;
  }

  /// Marks a dhikr complete regardless of count (used by "complete" action / tests).
  void completeDhikr(DhikrCategory category, String dhikrId) {
    final list = adhkarFor(category);
    Dhikr target;
    try {
      target = list.firstWhere((d) => d.id == dhikrId);
    } catch (_) {
      return;
    }
    _todayProgress[category]![dhikrId] = target.repeat;
    unawaited(_storage.saveDhikrProgress(category, _todayProgress[category]!));
    notifyListeners();
  }

  /// Completed count / total for a category today.
  ({int completed, int total}) categoryProgress(DhikrCategory category) {
    final list = adhkarFor(category);
    var completed = 0;
    for (final d in list) {
      if (countFor(category, d.id) >= d.repeat) completed++;
    }
    return (completed: completed, total: list.length);
  }

  double categoryPercent(DhikrCategory category) {
    final p = categoryProgress(category);
    return p.total == 0 ? 0 : p.completed / p.total;
  }

  int categoryPercentInt(DhikrCategory category) {
    final p = categoryProgress(category);
    return p.total == 0 ? 0 : (p.completed * 100 / p.total).round();
  }

  bool isCategoryComplete(DhikrCategory category) {
    final p = categoryProgress(category);
    return p.total > 0 && p.completed >= p.total;
  }

  int categoryRemaining(DhikrCategory category) {
    final p = categoryProgress(category);
    return p.total - p.completed;
  }

  /// Resets today's progress entirely (all categories). Also clears the
  /// in-memory maps so UI reflects immediately.
  Future<void> resetToday() async {
    await _storage.resetTodayProgress();
    for (final category in DhikrCategory.values) {
      _todayProgress[category] = <String, int>{};
    }
    notifyListeners();
  }

  /// Resets a specific category (e.g. afterPrayer across the 5 daily prayers).
  Future<void> resetCategory(DhikrCategory category) async {
    _todayProgress[category] = <String, int>{};
    await _storage.saveDhikrProgress(category, _todayProgress[category]!);
    notifyListeners();
  }

  /// Saves settings and persists them.
  Future<void> setLanguage(AppLanguage lang) async {
    _settings = _settings.copyWith(language: lang);
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setLanguageWithChoice(AppLanguage lang) async {
    _settings = _settings.copyWith(language: lang, hasChosenLanguage: true);
    await _storage.saveSettings(_settings);
    await _storage.setOnboardingCompleted(true);
    _cachedHasCompletedOnboarding = true;
    notifyListeners();
  }

  Future<void> completeOnboarding(AppLanguage lang) async {
    await setLanguageWithChoice(lang);
    await _storage.setOnboardingCompleted(true);
    _cachedHasCompletedOnboarding = true;
    notifyListeners();
  }

  Future<void> completePermissionsSetup() async {
    await _storage.setPermissionsSetupCompleted(true);
    _cachedHasCompletedPermissionsSetup = true;
    notifyListeners();
  }

  Future<void> resetOnboardingAndPermissions() async {
    await _storage.setOnboardingCompleted(false);
    await _storage.setPermissionsSetupCompleted(false);
    _settings = _settings.copyWith(hasChosenLanguage: false);
    await _storage.saveSettings(_settings);
    _cachedHasCompletedOnboarding = false;
    _cachedHasCompletedPermissionsSetup = false;
    notifyListeners();
  }

  Future<void> setTheme(ThemeModeSetting mode) async {
    _settings = _settings.copyWith(themeMode: mode);
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setAudioEnabled(bool value) async {
    _settings = _settings.copyWith(audioEnabled: value);
    await _storage.saveSettings(_settings);
    notifyListeners();
  }

  /// Commits today into history (called on app lifecycle / navigation away).
  Future<void> commitHistory() => _storage.commitDayToHistory();

  List<Map<String, dynamic>> getHistory({int limit = 30}) =>
      _storage.getHistory(limit: limit);

  /// ---- خريطة السَّكَن (moment / mood ratings) -----------------------------

  /// Today's manual calm/stress self-rating (1..5), or 0 if not yet rated.
  int get todayMoodRating => _storage.getTodayMoodRating();

  /// Mood ratings for the last [limit] days (newest first): {date, rating}.
  List<Map<String, dynamic>> getMoodHistory({int limit = 30}) =>
      _storage.getMoodHistory(limit: limit);

  /// Persist a manual calm rating (1..5) for today.
  Future<void> setTodayMoodRating(int rating) async {
    await _storage.saveMoodRating(rating);
    notifyListeners();
  }

  /// Saves location coordinates and city/country names, then notifies all listeners.
  Future<void> saveLocation({
    required double lat,
    required double lng,
    required String cityAr,
    required String cityEn,
    String? countryAr,
    String? countryEn,
    String? countryCode,
  }) async {
    await _storage.saveLocation(
      lat: lat,
      lng: lng,
      cityAr: cityAr,
      cityEn: cityEn,
      countryAr: countryAr,
      countryEn: countryEn,
      countryCode: countryCode,
    );
    notifyListeners();
  }

  /// Clears user profile on sign out or delete account.
  Future<void> clearUserProfile() async {
    await _storage.clearUserProfile();
    _userProfile = null;
    notifyListeners();
  }

  /// Reloads user profile from storage.
  void reloadUserProfile() {
    _userProfile = _storage.getUserProfile();
    notifyListeners();
  }
}
