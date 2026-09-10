import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// Service to synchronize Dhikr & Prayer times data with Home Screen Widgets (Android AppWidget / iOS WidgetKit)
class HomeWidgetService {
  HomeWidgetService._();
  static final HomeWidgetService instance = HomeWidgetService._();

  static const String _androidWidgetProvider = 'DhikrAppWidgetProvider';
  static const String _iosWidget = 'DhikrAppWidget';

  /// Update widget with latest prayer and dhikr data
  Future<void> updateHomeWidget({
    String? nextPrayerName,
    String? nextPrayerTime,
    String? nextPrayerKey,
    String? fajrTime,
    String? dhuhrTime,
    String? asrTime,
    String? maghribTime,
    String? ishaTime,
    String? dhikrLabel,
    String? dhikrText,
  }) async {
    if (kIsWeb) return;

    try {
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
      // Save all prayer times
      if (fajrTime != null) {
        await HomeWidget.saveWidgetData<String>('prayer_fajr', fajrTime);
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

      await HomeWidget.updateWidget(
        androidName: _androidWidgetProvider,
        qualifiedAndroidName: 'com.dhikr.adhkar.DhikrAppWidgetProvider',
        iOSName: _iosWidget,
      );
      debugPrint('HomeWidget updated successfully');
    } catch (e) {
      debugPrint('HomeWidget update error: $e');
    }
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
}
