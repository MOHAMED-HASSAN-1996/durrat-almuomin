import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:adhkar/services/storage.dart';
import 'package:adhkar/types/adhkar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('today progress', () {
    test('save/load round-trips per-dhikr counts', () async {
      final storage = DhikrStorage();
      final today = DhikrStorage.localTodayIso();

      await storage.saveDhikrProgress(DhikrCategory.morning, {
        'morning-01': 1,
        'morning-07': 3, // repeats three times; stays unclipped on load
      });

      final loaded = storage.getTodayProgress(DhikrCategory.morning);
      expect(loaded, {'morning-01': 1, 'morning-07': 3});
      expect(today, isNotEmpty);
    });

    test('stored counts exceeding the target are clipped on load', () async {
      SharedPreferences.setMockInitialValues({
        'adhkar.today_progress': jsonEncode({
          'day': DhikrStorage.localTodayIso(),
          'categories': {
            'morning': {'morning-01': 999},
          },
        }),
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = DhikrStorage(prefs: prefs);

      final loaded = storage.getTodayProgress(DhikrCategory.morning);
      // morning-01 repeats once; the absurd stored value must be clipped to 1.
      expect(loaded['morning-01'], 1);
    });

    test('progress saved under a past date is not treated as today', () async {
      SharedPreferences.setMockInitialValues({
        'adhkar.today_progress': jsonEncode({
          'day': '2001-01-01',
          'categories': {
            'morning': {'morning-01': 1},
          },
        }),
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = DhikrStorage(prefs: prefs);

      expect(storage.getTodayProgress(DhikrCategory.morning), isEmpty);
    });

    test('resetTodayProgress clears only today', () async {
      final storage = DhikrStorage();
      await storage.saveDhikrProgress(DhikrCategory.morning, {'morning-01': 1});
      await storage.resetTodayProgress();

      expect(storage.getTodayProgress(DhikrCategory.morning), isEmpty);
      expect(storage.getTodayProgress(DhikrCategory.evening), isEmpty);
    });
  });

  group('history', () {
    test('commitDayToHistory snapshots completed/total for both categories',
        () async {
      final storage = DhikrStorage();
      await storage.saveDhikrProgress(DhikrCategory.morning, {
        'morning-01': 1, // complete
        'morning-02': 0, // incomplete (not stored)
      });
      await storage.saveDhikrProgress(DhikrCategory.evening, {});

      await storage.commitDayToHistory();

      final history = storage.getHistory();
      expect(history, isNotEmpty);
      final entry = history.first;
      expect(entry['date'], DhikrStorage.localTodayIso());
      final morning = entry['morning'] as Map<String, dynamic>;
      expect(morning['completed'], 1);
      expect(morning['total'],
          storage.buildTargets(DhikrCategory.morning).length);
    });

    test('getHistory respects the limit and sorts newest first', () async {
      final storage = DhikrStorage();
      await storage.saveDhikrProgress(DhikrCategory.morning, {'morning-01': 1});
      await storage.saveDhikrProgress(DhikrCategory.morning, {'morning-02': 1});
      await storage.commitDayToHistory();

      expect(storage.getHistory(limit: 1).length, 1);
      final all = storage.getHistory(limit: 50);
      expect(all.first['date'], DhikrStorage.localTodayIso());
    });
  });

  group('settings', () {
    test('settings round-trip through a real prefs backend', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = DhikrStorage(prefs: prefs);

      await storage.saveSettings(const AppSettings(
        language: AppLanguage.english,
        themeMode: ThemeModeSetting.dark,
        audioEnabled: false,
      ));

      final reloaded = await SharedPreferences.getInstance();
      final settings = DhikrStorage(prefs: reloaded).getSettings();
      expect(settings.language, AppLanguage.english);
      expect(settings.themeMode, ThemeModeSetting.dark);
      expect(settings.audioEnabled, isFalse);
    });

    test('corrupt settings fall back to defaults', () async {
      SharedPreferences.setMockInitialValues({
        'adhkar.settings': 'not-json{',
      });
      final prefs = await SharedPreferences.getInstance();
      final settings = DhikrStorage(prefs: prefs).getSettings();

      expect(settings.language, AppLanguage.arabic);
      expect(settings.themeMode, ThemeModeSetting.light);
      expect(settings.audioEnabled, isTrue);
    });
  });
}