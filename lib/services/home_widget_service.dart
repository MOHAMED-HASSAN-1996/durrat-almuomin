import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class HomeWidgetService {
  HomeWidgetService._();
  static final HomeWidgetService instance = HomeWidgetService._();

  static const _channel = MethodChannel('com.dhikr.adhkar/widget');

  Future<void> updateHomeWidget({
    String? nextPrayerName,
    String? nextPrayerTime,
    String? nextPrayerKey,
    String? fajrTime,
    String? dhuhrTime,
    String? asrTime,
    String? maghribTime,
    String? ishaTime,
  }) async {
    if (kIsWeb) return;

    try {
      final data = <String, String>{};
      if (nextPrayerTime != null) data['next_prayer_time'] = nextPrayerTime;
      if (nextPrayerKey != null) data['next_prayer_key'] = nextPrayerKey;
      if (fajrTime != null) data['prayer_fajr'] = fajrTime;
      if (dhuhrTime != null) data['prayer_dhuhr'] = dhuhrTime;
      if (asrTime != null) data['prayer_asr'] = asrTime;
      if (maghribTime != null) data['prayer_maghrib'] = maghribTime;
      if (ishaTime != null) data['prayer_isha'] = ishaTime;

      await _channel.invokeMethod('updateWidget', data);
    } catch (e) {
      debugPrint('Widget update error: $e');
    }
  }
}
