import 'package:flutter_test/flutter_test.dart';

import 'package:adhkar/services/adhan_alert.dart';
import 'package:adhkar/services/prayer_alert_service.dart';

void main() {
  test(
    'adhan payload preserves the prayer names for the full-screen alert',
    () {
      final alert = AdhanAlert(prayerNameAr: 'المغرب', prayerNameEn: 'Maghrib');

      expect(AdhanAlert.fromPayload(alert.payload), alert);
    },
  );

  test('unknown notification payload is not treated as an adhan alert', () {
    expect(AdhanAlert.fromPayload('radio:station'), isNull);
  });

  test('adhan notification uses a repeating vibration pattern', () {
    expect(PrayerAlertService.adhanVibrationPattern, [
      0,
      700,
      450,
      700,
      450,
      700,
    ]);
  });
}
