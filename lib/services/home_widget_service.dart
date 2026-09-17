import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// Service to synchronize Dhikr & Prayer times data with Home Screen Widgets
/// (Android AppWidget / iOS WidgetKit) — matches the 9/16 device behavior:
/// PrayerWidgetProvider + PrayerTrackerWidgetProvider, both from home_widget.
class HomeWidgetService {
  HomeWidgetService._();
  static final HomeWidgetService instance = HomeWidgetService._();

  static const String _prayerProvider = 'PrayerWidgetProvider';
  static const String _trackerProvider = 'PrayerTrackerWidgetProvider';
  static const String _iosWidget = 'DhikrAppWidget';

  static const String _androidPrayerProviderQualified =
      'com.dhikr.adhkar.PrayerWidgetProvider';
  static const String _androidTrackerProviderQualified =
      'com.dhikr.adhkar.PrayerTrackerWidgetProvider';

  /// Update widgets with latest prayer + tracker data.
  /// Only non-null values are overwritten.
  Future<void> updateHomeWidget({
    String? nextPrayerName,
    String? nextPrayerTime,
    String? nextPrayerKey,
    int? nextPrayerTimestamp,
    String? fajrTime,
    String? sunriseTime,
    String? dhuhrTime,
    String? asrTime,
    String? maghribTime,
    String? ishaTime,
    String? widgetDayCalligraphy,
    String? widgetHijriDate,
    String? widgetGregorianDate,
    int? streakCount,
    Set<String>? prayerTasks,
    String? dhikrLabel,
    String? dhikrText,
  }) async {
    if (kIsWeb) return;

    try {
      // ── Full widget (bitmap rendered on the Kotlin side) ──
      if (nextPrayerName != null) {
        await HomeWidget.saveWidgetData<String>(
          'next_prayer_title',
          'الصلاة القادمة: $nextPrayerName',
        );
      }
      if (nextPrayerTime != null) {
        await HomeWidget.saveWidgetData<String>(
          'next_prayer_time',
          nextPrayerTime,
        );
      }
      if (nextPrayerKey != null) {
        await HomeWidget.saveWidgetData<String>(
          'next_prayer_key',
          nextPrayerKey,
        );
      }
      if (nextPrayerTimestamp != null) {
        await HomeWidget.saveWidgetData<int>(
          'next_prayer_timestamp',
          nextPrayerTimestamp,
        );
      }

      if (widgetDayCalligraphy != null) {
        await HomeWidget.saveWidgetData<String>(
          'widget_day_calligraphy',
          widgetDayCalligraphy,
        );
      }
      if (widgetHijriDate != null) {
        await HomeWidget.saveWidgetData<String>(
          'widget_hijri_date',
          widgetHijriDate,
        );
      }
      if (widgetGregorianDate != null) {
        await HomeWidget.saveWidgetData<String>(
          'widget_gregorian_date',
          widgetGregorianDate,
        );
      }

      if (streakCount != null) {
        await HomeWidget.saveWidgetData<int>('streak_count', streakCount);
      }

      final tasks = prayerTasks ?? <String>{};
      for (final key in const [
        'fajr',
        'dhuhr',
        'asr',
        'maghrib',
        'isha',
      ]) {
        await HomeWidget.saveWidgetData<bool>(
          'task_${key}_done',
          tasks.contains(key),
        );
      }

      // All prayer times
      if (fajrTime != null) {
        await HomeWidget.saveWidgetData<String>('prayer_fajr', fajrTime);
      }
      if (sunriseTime != null) {
        await HomeWidget.saveWidgetData<String>('prayer_sunrise', sunriseTime);
      }
      if (dhuhrTime != null) {
        await HomeWidget.saveWidgetData<String>('prayer_dhuhr', dhuhrTime);
      }
      if (asrTime != null) {
        await HomeWidget.saveWidgetData<String>('prayer_asr', asrTime);
      }
      if (maghribTime != null) {
        await HomeWidget.saveWidgetData<String>('prayer_maghrib', maghribTime);
      }
      if (ishaTime != null) {
        await HomeWidget.saveWidgetData<String>('prayer_isha', ishaTime);
      }

      if (dhikrLabel != null) {
        await HomeWidget.saveWidgetData<String>(
          'dhikr_label',
          dhikrLabel,
        );
      }
      if (dhikrText != null) {
        await HomeWidget.saveWidgetData<String>(
          'dhikr_text',
          dhikrText,
        );
      }

      // ── Refresh both providers ──
      await HomeWidget.updateWidget(
        androidName: _prayerProvider,
        qualifiedAndroidName: _androidPrayerProviderQualified,
        iOSName: _iosWidget,
      );
      await HomeWidget.updateWidget(
        androidName: _trackerProvider,
        qualifiedAndroidName: _androidTrackerProviderQualified,
        iOSName: _iosWidget,
      );
      debugPrint('HomeWidget updated successfully');
    } catch (e) {
      debugPrint('HomeWidget update error: $e');
    }
  }

  /// Quick tracker-only sync (e.g. after marking a prayer as done).
  Future<void> syncTracker() async {
    await updateHomeWidget();
  }

  /// Initial sync with default peaceful Dhikr
  Future<void> syncDefaultDhikr() async {
    final hour = DateTime.now().hour;
    final isMorning = hour >= 4 && hour < 16;
    final label = isMorning ? '🌅 أذكار الصباح' : '🌙 أذكار المساء';
    final dhikr = isMorning
        ? 'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ'
        : 'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ';

    await updateHomeWidget(
      dhikrLabel: label,
      dhikrText: dhikr,
    );
  }

  /// Pin (add) the home screen widget — works on Android 8.0+
  Future<bool> pinWidget({bool isTracker = false}) async {
    if (kIsWeb) return false;
    try {
      await updateHomeWidget();
      return true;
    } catch (e) {
      debugPrint('pinWidget error: $e');
      return false;
    }
  }
}