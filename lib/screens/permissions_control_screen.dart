import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../services/location_label.dart';
import '../services/prayer_alert_service.dart';
import '../services/prayer_times.dart';
import '../services/quran_radio.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';

/// الشاشة الجديدة المخصصة للتحكم في كافة أذونات النظام (التحكم في الأذونات)
/// تقرأ الحالة الحية من نظام أندرويد مباشرة وتتيح تجربة الأذان والاهتزاز فوراً.
class PermissionsControlScreen extends StatefulWidget {
  const PermissionsControlScreen({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  State<PermissionsControlScreen> createState() =>
      _PermissionsControlScreenState();
}

class _PermissionsControlScreenState extends State<PermissionsControlScreen>
    with WidgetsBindingObserver {
  bool _notificationsGranted = false;
  bool _locationGranted = false;
  bool _batteryExempted = false;
  bool _exactAlarmGranted = false;
  bool _backgroundAudioEnabled = true;

  bool _isLocating = false;
  bool _isEnablingAll = false;
  String? _currentCityAr;
  String? _currentCityEn;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _backgroundAudioEnabled = context.read<AppState>().audioEnabled;
    _refreshAllStatuses();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAllStatuses();
    }
  }

  /// قراءة الحالة الحية والفعلية من نظام التشغيل لجميع الصلاحيات
  Future<void> _refreshAllStatuses() async {
    if (!mounted) return;
    final storage = context.read<AppState>().storage;

    final isBatteryIgnored =
        await PlatformPermissions.isIgnoringBatteryOptimizations();
    final canExact = await PlatformPermissions.canScheduleExactAlarms();
    final notifsEnabled = await PrayerAlertService.instance
        .areNotificationsEnabled();

    // فحص صلاحية الموقع
    bool locGranted = false;
    try {
      final locPerm = await Geolocator.checkPermission();
      locGranted =
          locPerm == LocationPermission.always ||
          locPerm == LocationPermission.whileInUse;
    } catch (_) {}

    final savedLoc = storage.getSavedLocation();
    final cityAr = ((savedLoc?['cityAr'] as String?) ?? '').trim();
    final cityEn = ((savedLoc?['cityEn'] as String?) ?? cityAr).trim();
    final provinceAr = ((savedLoc?['provinceAr'] as String?) ?? '').trim();
    final provinceEn = ((savedLoc?['provinceEn'] as String?) ?? '').trim();
    final countryAr = ((savedLoc?['countryAr'] as String?) ?? '').trim();
    final countryEn = ((savedLoc?['countryEn'] as String?) ?? '').trim();
    final labelAr = locationLabel(
      city: cityAr,
      province: provinceAr,
      country: countryAr,
    );
    final labelEn = locationLabel(
      city: cityEn,
      province: provinceEn,
      country: countryEn,
    );

    if (!mounted) return;
    setState(() {
      _notificationsGranted = notifsEnabled;
      _batteryExempted = isBatteryIgnored;
      _exactAlarmGranted = canExact;
      _locationGranted = locGranted;
      _currentCityAr = labelAr.isNotEmpty ? labelAr : null;
      _currentCityEn = labelEn.isNotEmpty ? labelEn : null;
    });
  }

  Future<void> _requestNotificationPermission() async {
    HapticFeedback.selectionClick();
    await PrayerAlertService.instance.requestNotificationPermission();
    await _refreshAllStatuses();

    // تأكيد جدولة تنبيهات الصلوات فور تفعيل الإشعارات
    if (await PrayerAlertService.instance.areNotificationsEnabled()) {
      await _schedulePrayersNow();
    }
  }

  Future<void> _setNotificationPermission(bool enabled) async {
    HapticFeedback.selectionClick();
    if (enabled) {
      await _requestNotificationPermission();
    } else {
      await PlatformPermissions.openNotificationSettings();
      await _refreshAllStatuses();
    }
  }

  Future<void> _requestLocationPermission() async {
    HapticFeedback.selectionClick();
    if (!mounted) return;
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 7),
          ),
        );
        if (!mounted) return;
        final storage = context.read<AppState>().storage;
        // Resolve the GPS coordinates to a country + ISO code so the
        // zakat/nisab calculator can pick the correct local currency.
        String countryAr = '';
        String countryEn = '';
        String provinceAr = '';
        String provinceEn = '';
        String cc = '';
        try {
          final res = await http
              .get(
                Uri.parse(
                    'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${pos.latitude}&longitude=${pos.longitude}&localityLanguage=ar'),
              )
              .timeout(const Duration(seconds: 5));
          if (res.statusCode == 200) {
            final data = jsonDecode(res.body) as Map<String, dynamic>;
            countryAr = (data['countryName'] as String?) ?? '';
            provinceAr = (data['principalSubdivision'] as String?) ?? '';
            cc = ((data['countryCode'] as String?) ?? '').trim().toUpperCase();
          }
        } catch (_) {}
        if (cc.isEmpty) {
          try {
            final res = await http
                .get(
                  Uri.parse(
                      'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${pos.latitude}&longitude=${pos.longitude}&localityLanguage=en'),
                )
                .timeout(const Duration(seconds: 4));
            if (res.statusCode == 200) {
              final data = jsonDecode(res.body) as Map<String, dynamic>;
              countryEn = (data['countryName'] as String?) ?? '';
              provinceEn = (data['principalSubdivision'] as String?) ?? '';
              cc = ((data['countryCode'] as String?) ?? '').trim().toUpperCase();
            }
          } catch (_) {}
        }
        await storage.saveLocation(
          lat: pos.latitude,
          lng: pos.longitude,
          cityAr: 'موقعي الحالي',
          cityEn: 'Current Location',
          provinceAr: provinceAr,
          provinceEn: provinceEn,
          countryAr: countryAr,
          countryEn: countryEn,
          countryCode: cc,
        );
        await _schedulePrayersNow();
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLocating = false);
      await _refreshAllStatuses();
    }
  }

  Future<void> _setLocationPermission(bool enabled) async {
    HapticFeedback.selectionClick();
    if (enabled) {
      await _requestLocationPermission();
    } else {
      await Geolocator.openAppSettings();
      await _refreshAllStatuses();
    }
  }

  Future<void> _requestBatteryOptimization() async {
    HapticFeedback.selectionClick();
    await PlatformPermissions.requestIgnoreBatteryOptimizations();
    await Future.delayed(const Duration(milliseconds: 500));
    await _refreshAllStatuses();
  }

  Future<void> _setBatteryOptimization(bool enabled) async {
    HapticFeedback.selectionClick();
    if (enabled) {
      await _requestBatteryOptimization();
    } else {
      await PlatformPermissions.openBatteryOptimizationSettings();
      await _refreshAllStatuses();
    }
  }

  Future<void> _requestExactAlarms() async {
    HapticFeedback.selectionClick();
    await PlatformPermissions.openExactAlarmSettings();
    await Future.delayed(const Duration(milliseconds: 500));
    await _refreshAllStatuses();
  }

  Future<void> _setExactAlarms(bool enabled) async {
    HapticFeedback.selectionClick();
    await _requestExactAlarms();
  }

  Future<void> _toggleBackgroundAudio(bool enabled) async {
    HapticFeedback.selectionClick();
    await context.read<AppState>().setAudioEnabled(enabled);
    setState(() => _backgroundAudioEnabled = enabled);
    if (!enabled) {
      final radio = QuranRadioService.instance;
      if (radio.isPlaying) radio.stop();
    }
  }

  Future<void> _schedulePrayersNow() async {
    final storage = context.read<AppState>().storage;
    final saved = storage.getSavedLocation();
    final lat = (saved?['lat'] as num?)?.toDouble() ?? 30.0444;
    final lng = (saved?['lng'] as num?)?.toDouble() ?? 31.2357;
    final isAr = context.read<AppState>().language == AppLanguage.arabic;

    final now = DateTime.now();
    final pTimes = PrayerCalculator.calculate(date: now, lat: lat, lng: lng);
    final timesMap = {
      'fajr': pTimes.fajr,
      'dhuhr': pTimes.dhuhr,
      'asr': pTimes.asr,
      'maghrib': pTimes.maghrib,
      'isha': pTimes.isha,
    };

    await PrayerAlertService.instance.saveAlertPreferences(
      enabled: true,
      fajr: true,
      dhuhr: true,
      asr: true,
      maghrib: true,
      isha: true,
      sound: 'adhan',
      vibration: true,
      isArabic: isAr,
    );

    await PrayerAlertService.instance.schedulePrayerNotifications(
      prayerTimes: timesMap,
      isArabic: isAr,
      lat: lat,
      lng: lng,
    );
  }

  Future<void> _enableAllPermissions() async {
    if (_isEnablingAll || !mounted) return;
    setState(() => _isEnablingAll = true);

    try {
      // 1. Request Notifications
      await _requestNotificationPermission();
      await Future.delayed(const Duration(milliseconds: 500));

      // 2. Request Location
      await _requestLocationPermission();
      await Future.delayed(const Duration(milliseconds: 500));

      // 3. Request Battery Optimization
      await _requestBatteryOptimization();
      await Future.delayed(const Duration(milliseconds: 500));

      // 4. Request Exact Alarms
      await _requestExactAlarms();
      await Future.delayed(const Duration(milliseconds: 500));

      // 5. Schedule the prayer alerts so the user leaves onboarding with a
      //    working pre-prayer reminder + full-screen adhan.
      await _schedulePrayersNow();

      await _refreshAllStatuses();
    } catch (_) {
      await _refreshAllStatuses();
    }

    if (mounted) {
      setState(() => _isEnablingAll = false);
    }
  }

  /// First-run gate has no route to pop; hide the dead back arrow.
  /// Settings opens this screen as a pushed route, so back is shown there.
  bool get _canGoBack =>
      widget.onFinished != null || Navigator.of(context).canPop();

  /// Completes the onboarding permissions step so the app opens the home
  /// screen — used by both bottom buttons. Also seeds prayer alerts now that
  /// first-run permission gates are done (main.dart skipped this on cold start).
  Future<void> _finish() async {
    HapticFeedback.lightImpact();
    final nav = Navigator.of(context);
    final appState = context.read<AppState>();
    await appState.completePermissionsSetup();
    // Fire-and-forget: init may request OS notification permission on iOS;
    // Android schedules silently. Failures must not block navigation.
    unawaited(_seedPrayerAlertsAfterSetup(appState));
    if (widget.onFinished != null) {
      widget.onFinished!();
    } else if (nav.canPop()) {
      nav.pop();
    }
  }

  Future<void> _seedPrayerAlertsAfterSetup(AppState appState) async {
    try {
      await PrayerAlertService.instance.init();
      // Only schedule when a location was already saved during this setup
      // (or a previous run) — never invent coordinates or hit the network here.
      final saved = appState.storage.getSavedLocation();
      if (saved == null) return;
      if (!_notificationsGranted) return;
      final lat = (saved['lat'] as num?)?.toDouble();
      final lng = (saved['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return;
      await PrayerAlertService.instance.scheduleUpcomingPrayers(
        lat: lat,
        lng: lng,
        isArabic: appState.language == AppLanguage.arabic,
        daysToSchedule: PrayerAlertService.scheduleWindowDays,
      );
    } catch (_) {}
  }

  /// Primary action: request every permission, then move on to the app.
  Future<void> _enableAllAndContinue() async {
    await _enableAllPermissions();
    if (!mounted) return;
    await _finish();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().language;
    final isAr = lang == AppLanguage.arabic;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: dark
            ? DhikrColors.darkBg
            : DhikrColors.ivory,
        appBar: AppBar(
          backgroundColor: dark ? const Color(0xFF13221B) : Colors.white,
          elevation: 0,
          leading: _canGoBack
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
                  onPressed: () {
                    if (widget.onFinished != null) {
                      widget.onFinished!();
                    } else {
                      Navigator.of(context).maybePop();
                    }
                  },
                )
              : null,
          title: Text(
            isAr ? 'التحكم في الأذونات' : 'Permissions Control',
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: dark ? Colors.white : const Color(0xFF163E32),
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                physics: const BouncingScrollPhysics(),
                children: [
                  // عنوان قسم الصلاحيات
                  Text(
                    isAr
                        ? 'الأذونات الأساسية للتطبيق'
                        : 'Essential System Permissions',
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      color: dark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ═══ قائمة الصلاحيات الحية ═══
                  _buildPermissionCard(
                    title: isAr
                        ? 'إشعار اقتراب الصلاة (قبل ١٠ دقائق)'
                        : 'Pre-Prayer Reminder (10 min)',
                    subtitle: isAr
                        ? 'تنبيه صوتي «اقتربت الصلاة، أقم صلاتك» قبل موعد الأذان بعشر دقائق'
                        : 'Audio reminder 10 minutes before every prayer',
                    isGranted: _notificationsGranted,
                    onChanged: _setNotificationPermission,
                    dark: dark,
                  ),

                  _buildPermissionCard(
                    title: isAr
                        ? 'الأذان لكل الصلوات الخمس'
                        : 'Adhan for All Five Prayers',
                    subtitle: isAr
                        ? 'شاشة الأذان الكاملة تفتح تلقائياً في وقت كل فريضة مع الاهتزاز، وتُغلق تلقائياً بعد انتهاء الأذان'
                        : 'Full-screen Adhan opens automatically at prayer time with vibration',
                    isGranted: _notificationsGranted,
                    onChanged: _setNotificationPermission,
                    dark: dark,
                  ),

                  _buildPermissionCard(
                    title: isAr ? 'الموقع الجغرافي (GPS)' : 'Location & GPS',
                    subtitle: _locationGranted
                        ? (isAr
                              ? 'مفعل • الموقع: ${_currentCityAr ?? 'موقعي الحالي'}'
                              : 'Active • Location: ${_currentCityEn ?? 'Current'}')
                        : (isAr
                              ? 'مطلوب لحساب مواقيت الصلاة واتجاه القبلة'
                              : 'Required to calculate prayer times'),
                    isGranted: _locationGranted,
                    isLoading: _isLocating,
                    onChanged: _setLocationPermission,
                    dark: dark,
                  ),

                  _buildPermissionCard(
                    title: isAr
                        ? 'استثناء تحسين البطارية'
                        : 'Battery Optimization Exemption',
                    subtitle: isAr
                        ? 'يمنع نظام الهاتف من إيقاف الأذان عند قفل الشاشة'
                        : 'Prevents OS from killing alerts during sleep',
                    isGranted: _batteryExempted,
                    onChanged: _setBatteryOptimization,
                    dark: dark,
                  ),

                  _buildPermissionCard(
                    title: isAr
                        ? 'المنبهات الدقيقة (Exact Alarms)'
                        : 'Exact Alarms (Alarms & Reminders)',
                    subtitle: isAr
                        ? 'لضمان انطلاق الأذان في الدقيقة والثانية المحددة'
                        : 'Fires alarm at exact second even in Doze mode',
                    isGranted: _exactAlarmGranted,
                    onChanged: _setExactAlarms,
                    dark: dark,
                  ),

                  _buildPermissionCard(
                    title: isAr
                        ? 'التشغيل في الخلفية'
                        : 'Background Audio Radio',
                    subtitle: isAr
                        ? 'الاستماع لإذاعة القرآن أثناء قفل الشاشة أو تصفح التطبيقات'
                        : 'Keep playing radio while screen is locked',
                    isGranted: _backgroundAudioEnabled,
                    onChanged: _toggleBackgroundAudio,
                    dark: dark,
                  ),

                  const SizedBox(height: 16),

                  // ── زر ١: تفعيل الكل + متابعة ──
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isEnablingAll ? null : _enableAllAndContinue,
                      icon: _isEnablingAll
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  dark ? Colors.white : Colors.black,
                                ),
                              ),
                            )
                          : const Icon(Icons.done_all_rounded, size: 20),
                      label: Text(
                        isAr
                            ? 'تفعيل الكل ومتابعة'
                            : 'Enable All & Continue',
                        style: const TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DhikrColors.forest,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: DhikrColors.forest.withValues(
                          alpha: 0.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── زر ٢: المتابعة بالمتاح فقط ──
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _finish,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                      label: Text(
                        isAr
                            ? 'المتابعة بالمتاح فقط'
                            : 'Continue with Available Only',
                        style: const TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: dark
                            ? Colors.white
                            : const Color(0xFF163E32),
                        backgroundColor: dark
                            ? const Color(0xFF1A2E26)
                            : const Color(0xFFE5F3EE),
                        side: BorderSide(
                          color: dark
                              ? Colors.white24
                              : DhikrColors.forest.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    isAr
                        ? 'يمكنك تعديل كل إذن لاحقاً من الإعدادات ← التحكم في الأذونات'
                        : 'You can change every permission later from Settings → Permissions',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontSize: 11.5,
                      height: 1.5,
                      color: dark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required String subtitle,
    required bool isGranted,
    required ValueChanged<bool> onChanged,
    required bool dark,
    bool isLoading = false,
  }) {
    const activeGreen = DhikrColors.forest;
    final borderActive = dark
        ? const Color(0xFF34D399).withValues(alpha: 0.35)
        : const Color(0xFF10B981).withValues(alpha: 0.3);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF13221B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isGranted
              ? borderActive
              : (dark ? Colors.white10 : const Color(0xFFE5E7EB)),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isGranted
                ? activeGreen.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: dark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => onChanged(!isGranted),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: dark ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: 11.5,
                          color: dark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (isLoading)
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: activeGreen,
                    ),
                  )
                else
                  Switch.adaptive(
                    value: isGranted,
                    activeThumbColor: activeGreen,
                    activeTrackColor: activeGreen.withValues(alpha: 0.38),
                    inactiveThumbColor: const Color(0xFF9CA3AF),
                    inactiveTrackColor: dark
                        ? const Color(0xFF26332C)
                        : const Color(0xFFE5E7EB),
                    onChanged: onChanged,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
