import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'app.dart';
import 'data/content_validation.dart';
import 'services/home_widget_service.dart';
import 'services/prayer_alert_service.dart';
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

  // Run app immediately
  runApp(DhikrApp(appState: appState));

  // Initialize notifications & location & widgets in background
  if (!kIsWeb) {
    Future.microtask(() async {
      try {
        await PrayerAlertService.instance.init();
        var savedLoc = storage.getSavedLocation();
        if (savedLoc == null) {
          savedLoc = await _tryAutoLocate(storage);
        }
        final lat = (savedLoc?['lat'] as num?)?.toDouble() ?? 33.3152;
        final lng = (savedLoc?['lng'] as num?)?.toDouble() ?? 44.3661;
        final isAr = appState.language == AppLanguage.arabic;
        PrayerAlertService.instance.scheduleUpcomingPrayers(
          lat: lat,
          lng: lng,
          isArabic: isAr,
          daysToSchedule: 7,
        );
      } catch (_) {}

      try {
        await HomeWidgetService.instance.syncDefaultDhikr();
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
  // Provider 1: ip-api.com — fast, free, global
  try {
    final res = await http
        .get(Uri.parse(
            'http://ip-api.com/json/?fields=status,country,countryCode,city,lat,lon'))
        .timeout(const Duration(seconds: 4));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['status'] == 'success') {
        final lat = (data['lat'] as num?)?.toDouble();
        final lon = (data['lon'] as num?)?.toDouble();
        if (lat != null && lon != null) {
          return await _resolveAndSave(storage, lat, lon);
        }
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
        final city = (props['name'] as String?) ??
            (props['city'] as String?) ??
            (props['state'] as String?) ??
            '';
        final country = (props['country'] as String?) ?? '';
        if (city.isNotEmpty || country.isNotEmpty) {
          await storage.saveLocation(
            lat: lat,
            lng: lng,
            cityAr: city.isNotEmpty ? city : 'موقعي الحالي',
            cityEn: city.isNotEmpty ? city : 'Current Location',
            countryAr: country.isNotEmpty ? country : '',
            countryEn: country.isNotEmpty ? country : '',
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
      final countryAr = (dataAr['countryName'] as String?) ?? '';

      String cityEn = cityAr;
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
          countryEn = (dataEn['countryName'] as String?) ?? countryAr;
        }
      } catch (_) {}

      await storage.saveLocation(
        lat: lat,
        lng: lng,
        cityAr: cityAr.isNotEmpty ? cityAr : 'موقعي الحالي',
        cityEn: cityEn.isNotEmpty ? cityEn : 'Current Location',
        countryAr: countryAr,
        countryEn: countryEn,
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