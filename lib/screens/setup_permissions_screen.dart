import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../services/prayer_alert_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';

/// Pre-entry setup & permissions screen:
/// Configures precise GPS location, Azan notifications, background playback, and battery optimization.
class SetupPermissionsScreen extends StatefulWidget {
  const SetupPermissionsScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<SetupPermissionsScreen> createState() => _SetupPermissionsScreenState();
}

class _SetupPermissionsScreenState extends State<SetupPermissionsScreen>
    with WidgetsBindingObserver {
  bool _locating = false;
  bool _locationGranted = false;
  String? _detectedCity;
  bool _notificationsGranted = false;
  bool _batteryExempted = false;
  bool _exactAlarmGranted = true;
  bool _overlayGranted = false;
  bool _backgroundAudioEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Check if location is already saved
    final storage = context.read<AppState>().storage;
    final saved = storage.getSavedLocation();
    if (saved != null) {
      _locationGranted = true;
      _detectedCity = (saved['cityAr'] as String?) ?? (saved['cityEn'] as String?);
    }
    _checkStatuses();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkStatuses();
    }
  }

  Future<void> _checkStatuses() async {
    final isBatteryIgnored = await PlatformPermissions.isIgnoringBatteryOptimizations();
    final canExact = await PlatformPermissions.canScheduleExactAlarms();
    final canOverlay = await PlatformPermissions.canDrawOverlays();
    if (mounted) {
      setState(() {
        _batteryExempted = isBatteryIgnored;
        _exactAlarmGranted = canExact;
        _overlayGranted = canOverlay;
      });
    }
  }

  Future<void> _requestLocation() async {
    setState(() => _locating = true);
    HapticFeedback.selectionClick();

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );

        // Reverse geocode via reverse API or IP lookup
        await _reverseGeocode(pos.latitude, pos.longitude);
        if (mounted) {
          setState(() {
            _locationGranted = true;
            _locating = false;
          });
        }
        return;
      }
    } catch (_) {}

    // Fallback: IP-based lookup
    await _tryIpLocate();
    if (mounted) setState(() => _locating = false);
  }

  Future<void> _reverseGeocode(double lat, double lng,
      {String fallbackCity = '', String fallbackCountry = ''}) async {
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

          final resolvedCity =
              city.isNotEmpty ? city : (fallbackCity.isNotEmpty ? fallbackCity : 'موقعي الحالي');
          final resolvedCountry =
              country.isNotEmpty ? country : fallbackCountry;

          if (!mounted) return;
          final storage = context.read<AppState>().storage;
          await storage.saveLocation(
            lat: lat,
            lng: lng,
            cityAr: resolvedCity,
            cityEn: resolvedCity,
            countryAr: resolvedCountry,
            countryEn: resolvedCountry,
          );

          if (mounted) {
            setState(() {
              _detectedCity = resolvedCity;
              _locationGranted = true;
            });
          }
          return;
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

        final resolvedCityAr = cityAr.isNotEmpty ? cityAr : (fallbackCity.isNotEmpty ? fallbackCity : 'موقعي الحالي');
        final resolvedCityEn = cityEn.isNotEmpty ? cityEn : (fallbackCity.isNotEmpty ? fallbackCity : 'Current Location');
        final resolvedCountryAr = countryAr.isNotEmpty ? countryAr : fallbackCountry;
        final resolvedCountryEn = countryEn.isNotEmpty ? countryEn : fallbackCountry;

        if (!mounted) return;
        final storage = context.read<AppState>().storage;
        await storage.saveLocation(
          lat: lat,
          lng: lng,
          cityAr: resolvedCityAr,
          cityEn: resolvedCityEn,
          countryAr: resolvedCountryAr,
          countryEn: resolvedCountryEn,
        );

        if (mounted) {
          setState(() {
            _detectedCity = resolvedCityAr;
            _locationGranted = true;
          });
        }
        return;
      }
    } catch (_) {}

    // Tier 3: Absolute fallback — save coordinates with fallback names
    if (!mounted) return;
    final storage = context.read<AppState>().storage;
    await storage.saveLocation(
      lat: lat,
      lng: lng,
      cityAr: fallbackCity.isNotEmpty ? fallbackCity : 'موقعي الحالي',
      cityEn: fallbackCity.isNotEmpty ? fallbackCity : 'Current Location',
      countryAr: fallbackCountry,
      countryEn: fallbackCountry,
    );
    if (mounted) {
      setState(() {
        _detectedCity = fallbackCity.isNotEmpty ? fallbackCity : 'موقعي الحالي';
        _locationGranted = true;
      });
    }
  }

  Future<void> _tryIpLocate() async {
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
          final rawCity = (data['city'] as String?) ?? '';
          final rawCountry = (data['country'] as String?) ?? '';
          if (lat != null && lon != null) {
            await _reverseGeocode(lat, lon,
                fallbackCity: rawCity, fallbackCountry: rawCountry);
            return;
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
          final rawCity = (data['city'] as String?) ?? '';
          final rawCountry = (data['country'] as String?) ?? '';
          if (lat != null && lon != null) {
            await _reverseGeocode(lat, lon,
                fallbackCity: rawCity, fallbackCountry: rawCountry);
            return;
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
        final rawCity = (data['city'] as String?) ?? '';
        final rawCountry = (data['country_name'] as String?) ?? '';
        if (lat != null && lon != null) {
          await _reverseGeocode(lat, lon,
              fallbackCity: rawCity, fallbackCountry: rawCountry);
          return;
        }
      }
    } catch (_) {}
  }

  Future<void> _requestNotifications() async {
    HapticFeedback.selectionClick();
    await PrayerAlertService.instance.init();
    if (mounted) {
      setState(() => _notificationsGranted = true);
    }
  }

  Future<void> _requestBatteryOptimization() async {
    HapticFeedback.selectionClick();
    await PlatformPermissions.requestIgnoreBatteryOptimizations();
    await Future.delayed(const Duration(milliseconds: 500));
    await _checkStatuses();
  }

  Future<void> _requestExactAlarms() async {
    HapticFeedback.selectionClick();
    await PlatformPermissions.openExactAlarmSettings();
    await Future.delayed(const Duration(milliseconds: 500));
    await _checkStatuses();
  }

  Future<void> _requestOverlay() async {
    HapticFeedback.selectionClick();
    await PlatformPermissions.requestOverlayPermission();
    await Future.delayed(const Duration(milliseconds: 500));
    await _checkStatuses();
  }

  Future<void> _testAdhanNotification() async {
    HapticFeedback.heavyImpact();
    final isAr = context.read<AppState>().language == AppLanguage.arabic;
    await PrayerAlertService.instance.showTestNotification(
      isArabic: isAr,
      prayerNameAr: 'المغرب',
      prayerNameEn: 'Maghrib',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? '🔊 تم إرسال إشعار الأذان التجريبي! تحقّق من شاشة القفل وشريط الإشعارات.'
                : '🔊 Test Adhan notification fired! Check lockscreen & notification bar.',
            style: const TextStyle(fontFamily: DhikrTheme.arabicFont),
          ),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _enableAllAndProceed() async {
    HapticFeedback.lightImpact();
    // 1. Location if not already granted
    if (!_locationGranted) {
      await _requestLocation();
    }
    // 2. Notifications
    await _requestNotifications();
    if (mounted) setState(() => _notificationsGranted = true);

    // 3. Battery optimization
    if (!_batteryExempted) {
      await PlatformPermissions.requestIgnoreBatteryOptimizations();
    }

    // 4. Overlay permission (Display over other apps)
    if (!_overlayGranted) {
      await PlatformPermissions.requestOverlayPermission();
    }

    if (mounted) {
      setState(() {
        _backgroundAudioEnabled = true;
      });
      await _checkStatuses();
    }

    if (!mounted) return;

    // 5. Pre-schedule upcoming 7 days of prayers
    final saved = context.read<AppState>().storage.getSavedLocation();
    final lat = (saved?['lat'] as num?)?.toDouble() ?? 33.3152;
    final lng = (saved?['lng'] as num?)?.toDouble() ?? 44.3661;
    final isAr = context.read<AppState>().language == AppLanguage.arabic;

    await PrayerAlertService.instance.scheduleUpcomingPrayers(
      lat: lat,
      lng: lng,
      isArabic: isAr,
      daysToSchedule: 7,
    );

    // Done -> Proceed to App
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().language;
    final isAr = lang == AppLanguage.arabic;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8F7),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Ambient soft light gradient backdrop
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.3,
                  colors: [
                    Color(0xFFE8F4EE),
                    Color(0xFFF6F8F7),
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
            ),

            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      children: [
                        // Top Wordmark & Skip
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isAr ? 'دُرَّةُ الْمُؤْمِن' : "Durrat Al-Mu'min",
                              style: const TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF163E32),
                              ),
                            ),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: widget.onFinished,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE5E7EB).withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFD1D5DB), width: 0.8),
                                  ),
                                  child: Text(
                                    isAr ? 'تخطي' : 'Skip',
                                    style: const TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Emblem Icon
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFE1F5EC),
                                Color(0xFFC7EBD9),
                              ],
                            ),
                            border: Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            LucideIcons.shieldCheck,
                            size: 28,
                            color: Color(0xFF165B44),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Title & Subtitle
                        Text(
                          isAr
                              ? 'إعدادات التجربة الإيمانية'
                              : 'Spiritual Setup',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isAr
                              ? 'تفعيل الصلاحيات يضمن دقة مواقيت الصلاة وسماع الأذان والبث دون انقطاع'
                              : 'Enable permissions for accurate prayer times, Azan alerts, and continuous radio',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontSize: 12.5,
                            color: Color(0xFF4B5563),
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Permission Tiles
                        Expanded(
                          child: ListView(
                            physics: const BouncingScrollPhysics(),
                            children: [
                              _buildPermissionTile(
                                icon: LucideIcons.mapPin,
                                title: isAr ? 'الموقع الجغرافي' : 'Location',
                                subtitle: _locationGranted
                                    ? (isAr ? 'تم: ${_detectedCity ?? 'موقعك'}' : 'Located: ${_detectedCity ?? 'Location'}')
                                    : (isAr ? 'حساب مواقيت الصلاة حسب مدينتك' : 'Calculate prayer times for your city'),
                                isDone: _locationGranted,
                                isLoading: _locating,
                                onToggle: (v) async {
                                  if (v) {
                                    await _requestLocation();
                                  } else {
                                    setState(() => _locationGranted = false);
                                  }
                                },
                                accentColor: const Color(0xFF059669),
                              ),
                              const SizedBox(height: 10),

                              _buildPermissionTile(
                                icon: LucideIcons.bellRing,
                                title: isAr ? 'إشعارات الأذان' : 'Azan Alerts',
                                subtitle: isAr
                                    ? 'تنبيهك عند دخول وقت الصلاة'
                                    : 'Alert you when prayer time arrives',
                                isDone: _notificationsGranted,
                                onToggle: (v) async {
                                  if (v) {
                                    await _requestNotifications();
                                  } else {
                                    setState(() => _notificationsGranted = false);
                                  }
                                },
                                accentColor: const Color(0xFFD97706),
                              ),
                              const SizedBox(height: 10),

                              _buildPermissionTile(
                                icon: LucideIcons.radio,
                                title: isAr ? 'التشغيل في الخلفية' : 'Background Radio',
                                subtitle: isAr
                                    ? 'استماع لإذاعة القرآن من شاشة القفل'
                                    : 'Listen to Quran Radio from lockscreen',
                                isDone: _backgroundAudioEnabled,
                                onToggle: (v) => setState(() => _backgroundAudioEnabled = v),
                                accentColor: const Color(0xFF0284C7),
                              ),
                              const SizedBox(height: 10),

                              _buildPermissionTile(
                                icon: LucideIcons.zap,
                                title: isAr ? 'استثناء البطارية' : 'Battery Exemption',
                                subtitle: isAr
                                    ? 'منع إيقاف الأذان في الخلفية'
                                    : 'Prevent system from killing alerts',
                                isDone: _batteryExempted,
                                onToggle: (v) async {
                                  if (v) {
                                    await _requestBatteryOptimization();
                                  } else {
                                    setState(() => _batteryExempted = false);
                                  }
                                },
                                accentColor: const Color(0xFF7C3AED),
                              ),
                              const SizedBox(height: 10),

                              _buildPermissionTile(
                                icon: LucideIcons.appWindow,
                                title: isAr ? 'الظهور فوق التطبيقات' : 'Display Over Apps',
                                subtitle: isAr
                                    ? 'لظهور شاشة الأذان فوق أي تطبيق'
                                    : 'Show Adhan alert on top of other apps',
                                isDone: _overlayGranted,
                                onToggle: (v) async {
                                  if (v) {
                                    await _requestOverlay();
                                  } else {
                                    setState(() => _overlayGranted = false);
                                  }
                                },
                                accentColor: const Color(0xFF0D9488),
                              ),
                              const SizedBox(height: 10),

                              _buildPermissionTile(
                                icon: LucideIcons.alarmClock,
                                title: isAr ? 'دقة المواعيد' : 'Exact Alarms',
                                subtitle: isAr
                                    ? 'انطلاق الأذان في الدقيقة المحددة'
                                    : 'Trigger alerts at exact prayer time',
                                isDone: _exactAlarmGranted,
                                onToggle: (v) async {
                                  if (v) {
                                    await _requestExactAlarms();
                                  } else {
                                    setState(() => _exactAlarmGranted = false);
                                  }
                                },
                                accentColor: const Color(0xFFE11D48),
                              ),
                              const SizedBox(height: 14),

                              // Test Adhan
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _testAdhanNotification,
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFBEB),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: const Color(0xFFFDE68A),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(LucideIcons.volume2, size: 18, color: Color(0xFFD97706)),
                                        const SizedBox(width: 8),
                                        Text(
                                          isAr ? 'تجربة صوت الأذان' : 'Test Adhan Sound',
                                          style: const TextStyle(
                                            fontFamily: DhikrTheme.arabicFont,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF92400E),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Bottom Actions
                        const SizedBox(height: 16),

                        // Approve All Button
                        GestureDetector(
                          onTap: _enableAllAndProceed,
                          child: Container(
                            height: 52,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF1B5E47),
                                  Color(0xFF134534),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1B5E47).withValues(alpha: 0.25),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons.checkCheck,
                                    size: 19,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isAr ? 'تفعيل الكل والمتابعة' : 'Enable All & Continue',
                                    style: const TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Skip with available only
                        GestureDetector(
                          onTap: widget.onFinished,
                          child: Container(
                            height: 44,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                                width: 1.2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x06000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                isAr ? 'متابعة بالاختيارات الحالية' : 'Continue with Current Choices',
                                style: const TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDone,
    bool isLoading = false,
    required ValueChanged<bool> onToggle,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone
              ? const Color(0xFF10B981).withValues(alpha: 0.35)
              : const Color(0xFFE5E7EB),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.12),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Icon(icon, size: 20, color: accentColor),
          ),
          const SizedBox(width: 12),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Switch Toggle
          if (isLoading)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF165B44)),
              ),
            )
          else
            Switch(
              value: isDone,
              activeThumbColor: const Color(0xFF059669),
              activeTrackColor: const Color(0xFF059669).withValues(alpha: 0.3),
              inactiveThumbColor: const Color(0xFF9CA3AF),
              inactiveTrackColor: const Color(0xFFE5E7EB),
              trackOutlineColor: WidgetStatePropertyAll(
                isDone
                    ? const Color(0xFF059669).withValues(alpha: 0.4)
                    : const Color(0xFFD1D5DB),
              ),
              onChanged: onToggle,
            ),
        ],
      ),
    );
  }
}
