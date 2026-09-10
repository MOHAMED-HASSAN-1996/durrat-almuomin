import 'dart:math' as math;

/// Offline prayer time calculator — pure Dart, no network.
/// Method: Muslim World League (MWL) — Fajr 18°, Isha 17°, Shafi madhab.
/// Returns local times for a given date + latitude/longitude.
/// All calculations use the device's local timezone.
class PrayerTimes {
  const PrayerTimes({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;

  Map<String, DateTime> asMap() => {
        'fajr': fajr,
        'sunrise': sunrise,
        'dhuhr': dhuhr,
        'asr': asr,
        'maghrib': maghrib,
        'isha': isha,
      };
}

class PrayerCalculator {
  PrayerCalculator._();

  /// Calculate prayer times for [date] at [lat],[lng].
  /// [timezone] is offset from UTC in hours (e.g. 3 for Riyadh). If null, uses device local.
  static PrayerTimes calculate({
    required DateTime date,
    required double lat,
    required double lng,
    double? timezone,
  }) {
    final tz = timezone ?? (DateTime.now().timeZoneOffset.inMinutes / 60.0);
    final jd = _julianDay(date);
    final decl = _sunDeclination(jd);
    final eqt = _equationOfTime(jd);

    final noon = _fixHour(12 + tz - lng / 15 - eqt / 60);
    final dhuhr = _timeFromHour(date, noon);

    // Regional angles: Egyptian Survey Authority (Egypt: lat 22-32, lng 25-37) uses Fajr 19.5°, Isha 17.5°
    // Otherwise standard MWL (Fajr 18.0°, Isha 17.0°)
    const sunriseAngle = 0.833;
    final isEgypt = lat >= 21.0 && lat <= 32.5 && lng >= 24.5 && lng <= 37.0;
    final fajrAngle = isEgypt ? 19.5 : 18.0;
    final ishaAngle = isEgypt ? 17.5 : 17.0;

    final sunriseOffset = _hourAngle(lat, decl, sunriseAngle) / 15;
    final fajrOffset = _hourAngle(lat, decl, fajrAngle) / 15;
    final ishaOffset = _hourAngle(lat, decl, ishaAngle) / 15;

    final sunrise = _timeFromHour(date, noon - sunriseOffset);
    final sunset = _timeFromHour(date, noon + sunriseOffset);
    final fajr = _timeFromHour(date, noon - fajrOffset);
    final isha = _timeFromHour(date, noon + ishaOffset);

    // Asr: Shafi / Hanbali / Maliki (Shadow = 1 + shadow at noon)
    final asrHourAngleDeg = _asrHourAngle(lat, decl);
    final asrOffset = asrHourAngleDeg / 15;
    final asr = _timeFromHour(date, noon + asrOffset);

    return PrayerTimes(
      fajr: fajr,
      sunrise: sunrise,
      dhuhr: dhuhr,
      asr: asr,
      maghrib: sunset,
      isha: isha,
    );
  }

  static double _asrHourAngle(double lat, double decl) {
    final latRad = lat * math.pi / 180;
    final declRad = decl * math.pi / 180;
    final shadowNoon = math.tan((lat - decl).abs() * math.pi / 180);
    // Sun altitude above horizon at Asr: cot(alt) = 1 + shadowNoon => tan(alt) = 1 / (1 + shadowNoon)
    final asrAlt = math.atan(1.0 / (1.0 + shadowNoon));
    final cosH = (math.sin(asrAlt) - math.sin(latRad) * math.sin(declRad)) /
        (math.cos(latRad) * math.cos(declRad));
    final c = cosH.clamp(-1.0, 1.0);
    return math.acos(c) * 180 / math.pi;
  }

  static double _julianDay(DateTime date) {
    final y = date.year;
    final m = date.month;
    final d = date.day;
    final a = (14 - m) ~/ 12;
    final yy = y + 4800 - a;
    final mm = m + 12 * a - 3;
    return d +
        (153 * mm + 2) ~/ 5 +
        365 * yy +
        yy ~/ 4 -
        yy ~/ 100 +
        yy ~/ 400 -
        32045;
  }

  static double _sunDeclination(double jd) {
    final d = jd - 2451545.0;
    final g = _fixAngle(357.529 + 0.98560028 * d);
    final q = _fixAngle(280.459 + 0.98564736 * d);
    final l = _fixAngle(
        q + 1.915 * math.sin(g * math.pi / 180) + 0.020 * math.sin(2 * g * math.pi / 180));
    final e = 23.439 - 0.00000036 * d;
    return math.asin(math.sin(e * math.pi / 180) * math.sin(l * math.pi / 180)) *
        180 /
        math.pi;
  }

  static double _equationOfTime(double jd) {
    final d = jd - 2451545.0;
    final g = _fixAngle(357.529 + 0.98560028 * d);
    final q = _fixAngle(280.459 + 0.98564736 * d);
    final l = _fixAngle(
        q + 1.915 * math.sin(g * math.pi / 180) + 0.020 * math.sin(2 * g * math.pi / 180));
    final e = 23.439 - 0.00000036 * d;
    final ra = math.atan2(
            math.cos(e * math.pi / 180) * math.sin(l * math.pi / 180),
            math.cos(l * math.pi / 180)) *
        180 /
        math.pi;
    final raFixed = _fixAngle(ra);
    return 4 * (q - raFixed); // minutes
  }

  static double _hourAngle(double lat, double decl, double angle) {
    final latRad = lat * math.pi / 180;
    final declRad = decl * math.pi / 180;
    final angleRad = angle * math.pi / 180;
    final cosH =
        (-math.sin(angleRad) - math.sin(latRad) * math.sin(declRad)) /
            (math.cos(latRad) * math.cos(declRad));
    final c = cosH.clamp(-1.0, 1.0);
    return math.acos(c) * 180 / math.pi;
  }

  static double _fixAngle(double a) {
    a = a % 360;
    if (a < 0) a += 360;
    return a;
  }

  static double _fixHour(double h) {
    h = h % 24;
    if (h < 0) h += 24;
    return h;
  }

  static DateTime _timeFromHour(DateTime date, double hour) {
    final h = hour.floor();
    final m = ((hour - h) * 60).round();
    return DateTime(date.year, date.month, date.day, h, m);
  }
}
