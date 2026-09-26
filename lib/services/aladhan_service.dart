import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'prayer_times.dart';

/// جلب مواقيت الصلاة من Aladhan API (‏https://api.aladhan.com/v1) لتصبح
/// المواقيت صحيحة في كل أنحاء العالم (طريقة الحساب حسب الدولة + توقيت المدينة).
///
/// - كاش في الذاكرة + SharedPreferences لكل (إحداثيات + يوم) ليعمل التطبيق أوفلاين.
/// - المواقيت تُحوّل من توقيت المدينة (meta.timezone) إلى توقيت الجهاز.
/// - عند فشل الشبكة تُعاد `null` ليتولى `PrayerCalculator` الحساب المحلي.
class AladhanService {
  AladhanService._();
  static final AladhanService instance = AladhanService._();

  static const String _base = 'https://api.aladhan.com/v1';
  static const Duration _timeout = Duration(seconds: 10);
  static const int _maxCacheDays = 45;
  static const String _cachePrefix = 'aladhan.v1.';

  final Map<String, Map<String, DateTime>> _memory = {};
  bool _tzReady = false;

  // ── مفتاح الكاش: إحداثيات (٣ خانات ≈ ١٠٠م) + اليوم ───────────────────
  String _key(DateTime date, double lat, double lng) =>
      '${lat.toStringAsFixed(3)}|${lng.toStringAsFixed(3)}|'
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String _prefKey(String key) =>
      '$_cachePrefix${base64Url.encode(utf8.encode(key))}';

  // ── كشف طريقة الحساب الأنسب حسب الدولة/المدينة ──────────────────────
  static const Map<String, int> _methodByCountry = {
    'egypt': 5, 'مصر': 5,
    'saudi': 4, 'السعودية': 4,
    'united arab emirates': 16, 'uae': 16, 'الإمارات': 16,
    'qatar': 10, 'قطر': 10,
    'kuwait': 9, 'الكويت': 9, 'bahrain': 9, 'البحرين': 9,
    'oman': 4, 'عمان': 4, 'yemen': 3, 'اليمن': 3,
    'jordan': 23, 'الأردن': 23, 'syria': 8, 'سوريا': 8,
    'lebanon': 5, 'لبنان': 5, 'iraq': 9, 'العراق': 9,
    'palestine': 5, 'فلسطين': 5, 'israel': 5,
    'libya': 5, 'ليبيا': 5, 'tunisia': 18, 'تونس': 18,
    'algeria': 19, 'الجزائر': 19, 'morocco': 21, 'المغرب': 21,
    'sudan': 5, 'السودان': 5,
    'turkey': 13, 'turkiye': 13, 'تركيا': 13,
    'pakistan': 1, 'باكستان': 1, 'india': 1, 'الهند': 1,
    'bangladesh': 1, 'بنغلاديش': 1, 'afghanistan': 1, 'أفغانستان': 1,
    'iran': 7, 'إيران': 7,
    'malaysia': 17, 'ماليزيا': 17, 'indonesia': 20, 'إندونيسيا': 20,
    'brunei': 17, 'بروناي': 17, 'singapore': 11, 'سنغافورة': 11,
    'united states': 2, 'usa': 2, 'america': 2, 'الولايات المتحدة': 2,
    'canada': 2, 'كندا': 2, 'mexico': 2, 'المكسيك': 2,
    'brazil': 2, 'البرازيل': 2, 'argentina': 2, 'الأرجنتين': 2,
    'australia': 2, 'أستراليا': 2, 'new zealand': 2, 'نيوزيلندا': 2,
    'south africa': 2, 'جنوب أفريقيا': 2,
    'france': 12, 'فرنسا': 12, 'russia': 14, 'روسيا': 14,
    'kazakhstan': 1, 'كازاخستان': 1, 'uzbekistan': 1, 'أوزبكستان': 1,
  };

  /// كشف طريقة الحساب: الدولة أولاً، ثم المدينة، ثم الإحداثيات، وإلا MWL.
  static int detectMethod({
    String countryEn = '',
    String cityEn = '',
    double? lat,
    double? lng,
  }) {
    final country = countryEn.trim().toLowerCase();
    final city = cityEn.trim().toLowerCase();

    for (final entry in _methodByCountry.entries) {
      if (country.isNotEmpty && country.contains(entry.key)) {
        return entry.value;
      }
    }

    if (city.contains('makkah') ||
        city.contains('madina') ||
        city.contains('riyadh') ||
        city.contains('مكة') ||
        city.contains('المدينة')) {
      return 4; // Umm Al-Qura
    }
    if (city.contains('dubai') || city.contains('abu dhabi')) return 16;
    if (city.contains('cairo') || city.contains('القاهرة')) return 5;

    // احتياطي جغرافي: مصر ثم الحرمين ثم MWL.
    if (lat != null && lng != null) {
      final inEgypt = lat >= 21 && lat <= 32.5 && lng >= 24.5 && lng <= 37;
      if (inEgypt) return 5;
      final inHijaz = lat >= 16 && lat <= 32 && lng >= 34 && lng <= 56;
      if (inHijaz) return 4;
    }
    return 3; // Muslim World League
  }

  tz.Location? _location(String timeZoneName) {
    if (timeZoneName.isEmpty) return null;
    try {
      if (!_tzReady) {
        tzdata.initializeTimeZones();
        _tzReady = true;
      }
      return tz.getLocation(timeZoneName);
    } catch (e) {
      debugPrint('Aladhan timezone lookup failed: $e');
      return null;
    }
  }

  /// يحوّل "05:12 (EEST)" ليوم معيّن إلى DateTime بتوقيت الجهاز.
  DateTime? _parseTiming(String raw, DateTime date, tz.Location? loc) {
    final clean = raw.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(clean);
    if (match == null) return null;
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (loc == null) {
      return DateTime(date.year, date.month, date.day, hour, minute);
    }
    try {
      return tz.TZDateTime(
        loc,
        date.year,
        date.month,
        date.day,
        hour,
        minute,
      ).toLocal();
    } catch (_) {
      return DateTime(date.year, date.month, date.day, hour, minute);
    }
  }

  Map<String, DateTime>? _fromTimings(
    Map<String, dynamic> timings,
    DateTime date,
    tz.Location? loc,
  ) {
    final fajr = _parseTiming('${timings['Fajr'] ?? ''}', date, loc);
    final sunrise = _parseTiming('${timings['Sunrise'] ?? ''}', date, loc);
    final dhuhr = _parseTiming('${timings['Dhuhr'] ?? ''}', date, loc);
    final asr = _parseTiming('${timings['Asr'] ?? ''}', date, loc);
    final maghrib = _parseTiming('${timings['Maghrib'] ?? ''}', date, loc);
    final isha = _parseTiming('${timings['Isha'] ?? ''}', date, loc);
    if (fajr == null ||
        dhuhr == null ||
        asr == null ||
        maghrib == null ||
        isha == null) {
      return null;
    }
    return {
      'fajr': fajr,
      'sunrise': sunrise ?? fajr.add(const Duration(minutes: 85)),
      'dhuhr': dhuhr,
      'asr': asr,
      'maghrib': maghrib,
      'isha': isha,
    };
  }

  // ── الكاش ─────────────────────────────────────────────────────────────
  Future<Map<String, DateTime>?> _readCache(
    DateTime date,
    double lat,
    double lng,
  ) async {
    final key = _key(date, lat, lng);
    final cached = _memory[key];
    if (cached != null) return cached;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey(key));
      if (raw == null) return null;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final parsed = <String, DateTime>{};
      for (final entry in data.entries) {
        final ms = (entry.value as num?)?.toInt();
        if (ms == null) return null;
        parsed[entry.key] = DateTime.fromMillisecondsSinceEpoch(ms);
      }
      if (parsed.length < 6) return null;
      _memory[key] = parsed;
      return parsed;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(
    DateTime date,
    double lat,
    double lng,
    Map<String, DateTime> times,
  ) async {
    final key = _key(date, lat, lng);
    _memory[key] = times;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefKey(key),
        jsonEncode(
          times.map((k, v) => MapEntry(k, v.millisecondsSinceEpoch)),
        ),
      );
    } catch (_) {}
  }

  // ── الواجهة العامة ───────────────────────────────────────────────────

  /// مواقيت يوم واحد (كاش → شبكة → كاش). تُعيد `null` لو تعذّر كل ذلك.
  Future<Map<String, DateTime>?> timingsFor({
    required DateTime date,
    required double lat,
    required double lng,
    String countryEn = '',
    String cityEn = '',
    int? method,
  }) async {
    final day = DateTime(date.year, date.month, date.day);
    final cached = await _readCache(day, lat, lng);
    if (cached != null) return cached;

    final resolvedMethod = method ??
        detectMethod(countryEn: countryEn, cityEn: cityEn, lat: lat, lng: lng);
    final stamp = '${day.day.toString().padLeft(2, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-${day.year}';
    final url = '$_base/timings/$stamp?latitude=$lat&longitude=$lng'
        '&method=$resolvedMethod&school=0';
    try {
      final res = await http.get(Uri.parse(url)).timeout(_timeout);
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['code'] != 200) return null;
      final data = body['data'] as Map<String, dynamic>;
      final timings = data['timings'] as Map<String, dynamic>;
      final meta = data['meta'] as Map<String, dynamic>?;
      final loc = _location('${meta?['timezone'] ?? ''}');
      final parsed = _fromTimings(timings, day, loc);
      if (parsed == null) return null;
      await _writeCache(day, lat, lng, parsed);
      return parsed;
    } catch (e) {
      debugPrint('Aladhan daily fetch failed: $e');
      return null;
    }
  }

  /// يجلب مواقيت شهر كامل بنداء واحد (تقويم Aladhan) ويخزّنها في الكاش،
  /// لتُستخدم في جدولة تنبيهات الأذان لأيام قادمة بدقة.
  Future<void> warmMonth({
    required int year,
    required int month,
    required double lat,
    required double lng,
    String countryEn = '',
    String cityEn = '',
    int? method,
  }) async {
    final resolvedMethod = method ??
        detectMethod(countryEn: countryEn, cityEn: cityEn, lat: lat, lng: lng);
    final url = '$_base/calendar/$year/$month?latitude=$lat&longitude=$lng'
        '&method=$resolvedMethod&school=0';
    try {
      final res = await http.get(Uri.parse(url)).timeout(_timeout);
      if (res.statusCode != 200) return;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['code'] != 200) return;
      final days = body['data'] as List<dynamic>;
      for (final entry in days) {
        final item = entry as Map<String, dynamic>;
        final timings = item['timings'] as Map<String, dynamic>?;
        final dateObj = item['date'] as Map<String, dynamic>?;
        final greg = dateObj?['gregorian'] as Map<String, dynamic>?;
        final day = int.tryParse('${greg?['day'] ?? ''}');
        if (timings == null || day == null) continue;
        final meta = item['meta'] as Map<String, dynamic>?;
        final loc = _location('${meta?['timezone'] ?? ''}');
        final target = DateTime(year, month, day);
        final parsed = _fromTimings(timings, target, loc);
        if (parsed != null) await _writeCache(target, lat, lng, parsed);
      }
    } catch (e) {
      debugPrint('Aladhan monthly fetch failed: $e');
    }
  }

  /// مواقيت أي يوم من الكاش فقط (بدون شبكة) — للاستخدام المتزامن في الواجهة.
  Map<String, DateTime>? cachedSync(DateTime date, double lat, double lng) =>
      _memory[_key(DateTime(date.year, date.month, date.day), lat, lng)];

  /// تحميل كاش يوم معيّن إلى الذاكرة ليقرأه [cachedSync] فوراً.
  Future<Map<String, DateTime>?> prime(DateTime date, double lat, double lng) =>
      _readCache(DateTime(date.year, date.month, date.day), lat, lng);

  /// مواقيت منسّقة لأي يوم: من الكاش/الشبكة وإلا الحساب المحلي (لا تُعيد null).
  Future<PrayerTimes> prayerTimesFor({
    required DateTime date,
    required double lat,
    required double lng,
    String countryEn = '',
    String cityEn = '',
  }) async {
    final remote = await timingsFor(
      date: date,
      lat: lat,
      lng: lng,
      countryEn: countryEn,
      cityEn: cityEn,
    );
    if (remote != null) {
      return PrayerTimes(
        fajr: remote['fajr']!,
        sunrise: remote['sunrise']!,
        dhuhr: remote['dhuhr']!,
        asr: remote['asr']!,
        maghrib: remote['maghrib']!,
        isha: remote['isha']!,
      );
    }
    return PrayerCalculator.calculate(date: date, lat: lat, lng: lng);
  }
}
