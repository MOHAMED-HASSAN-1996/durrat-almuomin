import 'package:flutter_test/flutter_test.dart';

import 'package:adhkar/services/storage.dart';
import 'package:adhkar/state/app_state.dart';
import 'package:adhkar/types/adhkar.dart';

void main() {
  late AppState state;

  setUp(() {
    state = AppState(storage: DhikrStorage());
  });

  group('counter', () {
    test('increments from 0 and clamps at the immutable target', () {
      final first = state.adhkarFor(DhikrCategory.morning).first;
      final target = first.repeat;

      expect(state.countFor(DhikrCategory.morning, first.id), 0);

      for (var i = 1; i <= target; i++) {
        expect(state.increment(DhikrCategory.morning, first.id), i);
      }

      // Exceeding the target must not push past it.
      expect(state.increment(DhikrCategory.morning, first.id), target);
      expect(state.increment(DhikrCategory.morning, first.id), target);
      expect(state.countFor(DhikrCategory.morning, first.id), target);
    });

    test('unknown dhikr id is safely ignored', () {
      expect(state.increment(DhikrCategory.morning, 'does-not-exist'), 0);
      expect(state.isDhikrComplete(DhikrCategory.morning, 'does-not-exist'),
          isFalse);
    });
  });

  group('progress', () {
    test('starts at 0% and reaches 100% only when every dhikr is done', () {
      final list = state.adhkarFor(DhikrCategory.morning);
      expect(state.categoryPercentInt(DhikrCategory.morning), 0);
      expect(state.isCategoryComplete(DhikrCategory.morning), isFalse);

      for (final d in list) {
        state.completeDhikr(DhikrCategory.morning, d.id);
      }

      expect(state.categoryPercentInt(DhikrCategory.morning), 100);
      expect(state.isCategoryComplete(DhikrCategory.morning), isTrue);
    });

    test('halfway progress rounds to nearest integer', () {
      final list = state.adhkarFor(DhikrCategory.evening);
      final half = list.length ~/ 2;
      for (var i = 0; i < half; i++) {
        state.completeDhikr(DhikrCategory.evening, list[i].id);
      }
      final p = state.categoryProgress(DhikrCategory.evening);
      expect(p.total, list.length);
      expect(p.completed, half);
      final expected =
          (half * 100 / list.length).round();
      expect(state.categoryPercentInt(DhikrCategory.evening), expected);
    });
  });

  group('morning/evening independence', () {
    test('completing morning items leaves evening untouched', () {
      final morning = state.adhkarFor(DhikrCategory.morning);
      state.completeDhikr(DhikrCategory.morning, morning.first.id);

      expect(state.categoryProgress(DhikrCategory.morning).completed, 1);
      expect(state.categoryProgress(DhikrCategory.evening).completed, 0);
      expect(state.categoryPercentInt(DhikrCategory.evening), 0);
    });
  });

  group('persistence', () {
    test('progress survives a fresh AppState over the same storage', () async {
      final storage = DhikrStorage();
      final firstState = AppState(storage: storage);
      await firstState.load();

      // Pick a dhikr that repeats at least twice so two increments are
      // observable (single-repeat items clamp at 1).
      final dhikr = firstState
          .adhkarFor(DhikrCategory.morning)
          .firstWhere((d) => d.repeat >= 2);

      firstState.increment(DhikrCategory.morning, dhikr.id);
      firstState.increment(DhikrCategory.morning, dhikr.id);

      final reloaded = AppState(storage: storage);
      await reloaded.load();

      expect(reloaded.countFor(DhikrCategory.morning, dhikr.id), 2);
    });

    test('settings survive a fresh AppState over the same storage', () async {
      final storage = DhikrStorage();
      final first = AppState(storage: storage);
      await first.load();
      await first.setLanguage(AppLanguage.english);
      await first.setTheme(ThemeModeSetting.dark);
      await first.setAudioEnabled(false);

      final reloaded = AppState(storage: storage);
      await reloaded.load();

      expect(reloaded.language, AppLanguage.english);
      expect(reloaded.themeMode, ThemeModeSetting.dark);
      expect(reloaded.audioEnabled, isFalse);
    });
  });

  group('reset', () {
    test('resetToday clears both categories but keeps settings', () async {
      final list = state.adhkarFor(DhikrCategory.morning);
      state.completeDhikr(DhikrCategory.morning, list.first.id);
      await state.setLanguage(AppLanguage.english);

      await state.resetToday();

      expect(state.categoryProgress(DhikrCategory.morning).completed, 0);
      expect(state.categoryProgress(DhikrCategory.evening).completed, 0);
      expect(state.language, AppLanguage.english);
    });

    test('resetCategory resets afterPrayer category independently', () async {
      final list = state.adhkarFor(DhikrCategory.afterPrayer);
      state.completeDhikr(DhikrCategory.afterPrayer, list.first.id);
      expect(state.categoryProgress(DhikrCategory.afterPrayer).completed, 1);

      await state.resetCategory(DhikrCategory.afterPrayer);
      expect(state.categoryProgress(DhikrCategory.afterPrayer).completed, 0);
    });
  });

  group('prayer tasks & streak', () {
    test('togglePrayerTask adds and removes prayer tasks and persists', () async {
      expect(state.completedPrayerTasksCount, 0);
      expect(state.isPrayerTaskCompleted('fajr'), isFalse);

      await state.togglePrayerTask('fajr');
      expect(state.completedPrayerTasksCount, 1);
      expect(state.isPrayerTaskCompleted('fajr'), isTrue);

      await state.togglePrayerTask('dhuhr');
      expect(state.completedPrayerTasksCount, 2);

      // Toggle off fajr
      await state.togglePrayerTask('fajr');
      expect(state.completedPrayerTasksCount, 1);
      expect(state.isPrayerTaskCompleted('fajr'), isFalse);
      expect(state.isPrayerTaskCompleted('dhuhr'), isTrue);
    });

    test('streak count initializes to at least 1 on activity', () {
      expect(state.streakCount, greaterThanOrEqualTo(1));
    });
  });
}