import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'data/content_validation.dart';
import 'services/home_widget_service.dart';
import 'services/prayer_alert_service.dart';
import 'services/quran_radio.dart';
import 'services/remote_content_service.dart';
import 'services/storage.dart';
import 'state/app_state.dart';
import 'types/adhkar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Content validation gate: log errors but never crash the app.
  final validation = validateAllBuiltIn();
  if (!validation.isClean) {
    // ignore: avoid_print
    print('DHIKR content validation issues:\n${validation.errors.join('\n')}');
  }

  final storage = DhikrStorage();
  final appState = AppState(storage: storage);
  await appState.load();

  // Run app immediately — لا نحجب أول فريم خلف أي تهيئة شبكية.
  runApp(DhikrApp(appState: appState));

  // تهيئة Supabase في الخلفية بعد أول فريم (كانت تحجب البدء لثوانٍ).
  Future.microtask(() async {
    try {
      await Supabase.initialize(
        url: 'https://djhdcrwxtyzbtwjcrvwu.supabase.co',
        publishableKey: 'sb_publishable_gEjbiqpjtbk_i2NqQwuUPQ_taK2ldeo',
      );
    } catch (e) {
      debugPrint('Supabase init failed: $e');
    }
    // محتوى الإدارة (بطاقات الرئيسية/الأنمي) من الكاش أولاً ثم Firestore
    // في الخلفية — لا يحجب الواجهة.
    try {
      await RemoteContentService.instance.initialize();
    } catch (_) {}
  });

  // First run: do not request notifications, GPS, or IP geolocation here.
  // Those happen from the onboarding / permissions screens at the right time.
  final firstRun = !storage.hasCompletedOnboarding() ||
      !storage.hasCompletedPermissionsSetup();

  // Initialize widgets & (after setup) notifications & location in background
  if (!kIsWeb) {
    Future.microtask(() async {
      try {
        await HomeWidgetService.instance.syncDefaultDhikr();
      } catch (_) {}

      // تنظيف إشعار البث القديم إن وُجد (أُزيل الإشعار المخصص من التطبيق).
      try {
        await QuranRadioService.instance.clearLegacyNotification();
      } catch (_) {}

      if (firstRun) return;

      try {
        await PrayerAlertService.instance.init();
        final savedLoc = storage.getSavedLocation() ??
            await _tryAutoLocate(storage);
        final lat = (savedLoc?['lat'] as num?)?.toDouble() ?? 33.3152;
        final lng = (savedLoc?['lng'] as num?)?.toDouble() ?? 44.3661;
        final isAr = appState.language == AppLanguage.arabic;
        // Rolling 30-day seed without a hard limit: each app open pushes the
        // window forward again (throttled inside the service), so alerts keep
        // working even if the phone is never touched for weeks.
        PrayerAlertService.instance.scheduleUpcomingPrayers(
          lat: lat,
          lng: lng,
          isArabic: isAr,
          daysToSchedule: PrayerAlertService.scheduleWindowDays,
        );
      } catch (_) {}
    });
  }
}

Future<Map<String, dynamic>?> _tryAutoLocate(DhikrStorage storage) async {
  // Try GPS first
  try {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return await _resolveAndSave(storage, pos.latitude, pos.longitude);
    }
  } catch (_) {}

  // Fallback: IP-based geolocation (multiple providers for worldwide reliability)
  // Provider 1: freeipapi.com — HTTPS, free, global
  try {
    final res = await http
        .get(Uri.parse('https://freeipapi.com/api/json'))
        .timeout(const Duration(seconds: 4));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final lat = (data['latitude'] as num?)?.toDouble();
      final lon = (data['longitude'] as num?)?.toDouble();
      if (lat != null && lon != null) {
        return await _resolveAndSave(storage, lat, lon);
      }
    }
  } catch (_) {}

  // Provider 2: ipwho.is — HTTPS, reliable
  try {
    final res = await http
        .get(Uri.parse('https://ipwho.is/'))
        .timeout(const Duration(seconds: 5));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        final lat = (data['latitude'] as num?)?.toDouble();
        final lon = (data['longitude'] as num?)?.toDouble();
        if (lat != null && lon != null) {
          return await _resolveAndSave(storage, lat, lon);
        }
      }
    }
  } catch (_) {}

  // Provider 3: ipapi.co — HTTPS, good global coverage
  try {
    final res = await http
        .get(Uri.parse('https://ipapi.co/json/'))
        .timeout(const Duration(seconds: 6));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final lat = (data['latitude'] as num?)?.toDouble();
      final lon = (data['longitude'] as num?)?.toDouble();
      if (lat != null && lon != null) {
        return await _resolveAndSave(storage, lat, lon);
      }
    }
  } catch (_) {}

  return null;
}

Future<Map<String, dynamic>?> _resolveAndSave(
    DhikrStorage storage, double lat, double lng) async {
  // Tier 1: Photon by Komoot — fast, OSM-based, native Arabic
  try {
    final res = await http
        .get(
          Uri.parse('https://photon.komoot.io/reverse?lat=$lat&lon=$lng'),
          headers: {'User-Agent': 'adhkar/1.0 (adhkar.app@example.com)'},
        )
        .timeout(const Duration(seconds: 4));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final features = (data['features'] as List<dynamic>?) ?? [];
      if (features.isNotEmpty) {
        final props =
            (features.first['properties'] as Map<String, dynamic>?) ?? {};
        final city = (props['city'] as String?) ??
            (props['name'] as String?) ??
            (props['locality'] as String?) ??
            '';
        final province = (props['state'] as String?) ?? '';
        final country = (props['country'] as String?) ?? '';
        final cc = ((props['countrycode'] as String?) ?? '').trim().toUpperCase();
        if (city.isNotEmpty || province.isNotEmpty || country.isNotEmpty) {
          await storage.saveLocation(
            lat: lat,
            lng: lng,
            cityAr: city.isNotEmpty ? city : 'موقعي الحالي',
            cityEn: city.isNotEmpty ? city : 'Current Location',
            provinceAr: province.isNotEmpty ? province : '',
            provinceEn: province.isNotEmpty ? province : '',
            countryAr: country.isNotEmpty ? country : '',
            countryEn: country.isNotEmpty ? country : '',
            countryCode: cc,
          );
          return storage.getSavedLocation();
        }
      }
    }
  } catch (_) {}

  // Tier 2: BigDataCloud — reliable, returns Arabic & English
  try {
    final resAr = await http
        .get(
          Uri.parse(
              'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lng&localityLanguage=ar'),
        )
        .timeout(const Duration(seconds: 5));
    if (resAr.statusCode == 200) {
      final dataAr = jsonDecode(resAr.body) as Map<String, dynamic>;
      final cityAr = (dataAr['city'] as String?)?.isNotEmpty == true
          ? dataAr['city'] as String
          : ((dataAr['locality'] as String?)?.isNotEmpty == true
              ? dataAr['locality'] as String
              : ((dataAr['principalSubdivision'] as String?) ?? ''));
      final provinceAr = (dataAr['principalSubdivision'] as String?) ?? '';
      final countryAr = (dataAr['countryName'] as String?) ?? '';
      final cc = ((dataAr['countryCode'] as String?) ?? '').trim().toUpperCase();

      String cityEn = cityAr;
      String provinceEn = provinceAr;
      String countryEn = countryAr;
      try {
        final resEn = await http
            .get(
              Uri.parse(
                  'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lng&localityLanguage=en'),
            )
            .timeout(const Duration(seconds: 4));
        if (resEn.statusCode == 200) {
          final dataEn = jsonDecode(resEn.body) as Map<String, dynamic>;
          cityEn = (dataEn['city'] as String?)?.isNotEmpty == true
              ? dataEn['city'] as String
              : ((dataEn['locality'] as String?)?.isNotEmpty == true
                  ? dataEn['locality'] as String
                  : cityAr);
          provinceEn = (dataEn['principalSubdivision'] as String?) ?? provinceAr;
          countryEn = (dataEn['countryName'] as String?) ?? countryAr;
        }
      } catch (_) {}

      await storage.saveLocation(
        lat: lat,
        lng: lng,
        cityAr: cityAr.isNotEmpty ? cityAr : 'موقعي الحالي',
        cityEn: cityEn.isNotEmpty ? cityEn : 'Current Location',
        provinceAr: provinceAr,
        provinceEn: provinceEn,
        countryAr: countryAr,
        countryEn: countryEn,
        countryCode: cc,
      );
      return storage.getSavedLocation();
    }
  } catch (_) {}

  // Tier 3: Absolute fallback — save coordinates without city name
  await storage.saveLocation(
    lat: lat,
    lng: lng,
    cityAr: 'موقعي الحالي',
    cityEn: 'Current Location',
    countryAr: '',
    countryEn: '',
  );
  return storage.getSavedLocation();
}