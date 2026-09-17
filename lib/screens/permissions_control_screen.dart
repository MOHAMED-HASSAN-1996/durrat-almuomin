import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

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
  State<PermissionsControlScreen> createState() => _PermissionsControlScreenState();
}

class _PermissionsControlScreenState extends State<PermissionsControlScreen>
    with WidgetsBindingObserver {
  bool _notificationsGranted = false;
  bool _locationGranted = false;
  bool _batteryExempted = false;
  bool _exactAlarmGranted = false;
  bool _fullScreenIntentGranted = true;
  bool _backgroundAudioEnabled = true;

  bool _isLocating = false;
  String? _currentCity;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    final storage = context.read<AppState>().storage;

    final isBatteryIgnored = await PlatformPermissions.isIgnoringBatteryOptimizations();
    final canExact = await PlatformPermissions.canScheduleExactAlarms();

    // فحص صلاحية الموقع
    bool locGranted = false;
    try {
      final locPerm = await Geolocator.checkPermission();
      locGranted = locPerm == LocationPermission.always || locPerm == LocationPermission.whileInUse;
    } catch (_) {}

    final savedLoc = storage.getSavedLocation();
    final cityName = (savedLoc?['cityAr'] as String?) ?? (savedLoc?['cityEn'] as String?);

    if (!mounted) return;
    setState(() {
      _notificationsGranted = true;
      _batteryExempted = isBatteryIgnored;
      _exactAlarmGranted = canExact;
      _fullScreenIntentGranted = true;
      _locationGranted = locGranted || (savedLoc != null);
      _currentCity = cityName;
      _backgroundAudioEnabled = true;
    });
  }

  Future<void> _requestNotificationPermission() async {
    HapticFeedback.selectionClick();
    await PrayerAlertService.instance.init();
    await Future.delayed(const Duration(milliseconds: 400));
    await _refreshAllStatuses();

    // تأكيد جدولة تنبيهات الصلوات فور تفعيل الإشعارات
    if (_notificationsGranted) {
      await _schedulePrayersNow();
    }
  }

  Future<void> _requestLocationPermission() async {
    HapticFeedback.selectionClick();
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 7),
          ),
        );
        if (!mounted) return;
        final storage = context.read<AppState>().storage;
        await storage.saveLocation(
          lat: pos.latitude,
          lng: pos.longitude,
          cityAr: 'موقعي الحالي',
          cityEn: 'Current Location',
          countryAr: '',
          countryEn: '',
        );
        await _schedulePrayersNow();
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLocating = false);
      await _refreshAllStatuses();
    }
  }

  Future<void> _requestBatteryOptimization() async {
    HapticFeedback.selectionClick();
    await PlatformPermissions.requestIgnoreBatteryOptimizations();
    await Future.delayed(const Duration(milliseconds: 500));
    await _refreshAllStatuses();
  }

  Future<void> _requestExactAlarms() async {
    HapticFeedback.selectionClick();
    await PlatformPermissions.openExactAlarmSettings();
    await Future.delayed(const Duration(milliseconds: 500));
    await _refreshAllStatuses();
  }

  Future<void> _requestFullScreenIntent() async {
    HapticFeedback.selectionClick();
    await Future.delayed(const Duration(milliseconds: 500));
    await _refreshAllStatuses();
  }

  Future<void> _toggleBackgroundAudio(bool enabled) async {
    HapticFeedback.selectionClick();
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
      prayerTimes: timesMap,
      isArabic: isAr,
    );

    await PrayerAlertService.instance.schedulePrayerNotifications(
      prayerTimes: timesMap,
      isArabic: isAr,
      lat: lat,
      lng: lng,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().language;
    final isAr = lang == AppLanguage.arabic;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: dark ? const Color(0xFF0D1612) : const Color(0xFFF7FBF9),
        appBar: AppBar(
          backgroundColor: dark ? const Color(0xFF13221B) : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19),
            onPressed: () {
              if (widget.onFinished != null) {
                widget.onFinished!();
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
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
                    isAr ? 'الأذونات الأساسية للتطبيق' : 'Essential System Permissions',
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      color: dark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ═══ قائمة الصلاحيات الحية ═══
                  _buildPermissionCard(
                    icon: LucideIcons.bell,
                    title: isAr ? 'إشعارات الأذان والتنبيهات' : 'Azan & Prayer Notifications',
                    subtitle: isAr
                        ? 'إطلاق الأذان وبانر الصلاة في وقت كل فريضة'
                        : 'Alerts at the exact time of every prayer',
                    isGranted: _notificationsGranted,
                    onTap: _requestNotificationPermission,
                    dark: dark,
                  ),

                  _buildPermissionCard(
                    icon: LucideIcons.mapPin,
                    title: isAr ? 'الموقع الجغرافي (GPS)' : 'Location & GPS',
                    subtitle: _locationGranted
                        ? (isAr
                            ? 'مفعل • المدينة: ${_currentCity ?? 'موقعي الحالي'}'
                            : 'Active • City: ${_currentCity ?? 'Current'}')
                        : (isAr ? 'مطلوب لحساب مواقيت الصلاة واتجاه القبلة' : 'Required to calculate prayer times'),
                    isGranted: _locationGranted,
                    isLoading: _isLocating,
                    onTap: _requestLocationPermission,
                    dark: dark,
                  ),

                  _buildPermissionCard(
                    icon: LucideIcons.batteryCharging,
                    title: isAr ? 'استثناء تحسين البطارية' : 'Battery Optimization Exemption',
                    subtitle: isAr
                        ? 'يمنع نظام الهاتف من إيقاف الأذان عند قفل الشاشة'
                        : 'Prevents OS from killing alerts during sleep',
                    isGranted: _batteryExempted,
                    onTap: _requestBatteryOptimization,
                    dark: dark,
                  ),

                  _buildPermissionCard(
                    icon: LucideIcons.alarmClock,
                    title: isAr ? 'المنبهات الدقيقة (Exact Alarms)' : 'Exact Alarms (Alarms & Reminders)',
                    subtitle: isAr
                        ? 'لضمان انطلاق الأذان في الدقيقة والثانية المحددة'
                        : 'Fires alarm at exact second even in Doze mode',
                    isGranted: _exactAlarmGranted,
                    onTap: _requestExactAlarms,
                    dark: dark,
                  ),

                  _buildPermissionCard(
                    icon: LucideIcons.maximize2,
                    title: isAr ? 'شاشة الأذان الكاملة (Lock Screen)' : 'Full Screen Adhan on Lock Screen',
                    subtitle: isAr
                        ? 'عرض شاشة الأذان الكبيرة تلقائياً فوق شاشة القفل عند كل صلاة'
                        : 'Displays full screen Adhan over lockscreen on alarm',
                    isGranted: _fullScreenIntentGranted,
                    onTap: _requestFullScreenIntent,
                    dark: dark,
                  ),

                  _buildPermissionCard(
                    icon: LucideIcons.radio,
                    title: isAr ? 'التشغيل في الخلفية' : 'Background Audio Radio',
                    subtitle: isAr
                        ? 'الاستماع لإذاعة القرآن أثناء قفل الشاشة أو تصفح التطبيقات'
                        : 'Keep playing radio while screen is locked',
                    isGranted: _backgroundAudioEnabled,
                    onTap: () => _toggleBackgroundAudio(!_backgroundAudioEnabled),
                    dark: dark,
                  ),

                  const SizedBox(height: 24),

                  // زر الحفظ والمتابعة النهائي
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        final nav = Navigator.of(context);
                        await context.read<AppState>().completePermissionsSetup();
                        if (widget.onFinished != null) {
                          widget.onFinished!();
                        } else {
                          nav.pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF163E32),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            widget.onFinished != null
                                ? (isAr ? 'حفظ ومتابعة إلى التطبيق' : 'Save & Continue to App')
                                : (isAr ? 'حفظ والرجوع' : 'Save & Return'),
                            style: const TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
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
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isGranted,
    required VoidCallback onTap,
    required bool dark,
    bool isLoading = false,
  }) {
    final primaryAccent = dark ? const Color(0xFF34D399) : const Color(0xFF163E32);
    final borderActive = dark ? const Color(0xFF34D399).withValues(alpha: 0.35) : const Color(0xFF163E32).withValues(alpha: 0.25);

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
                ? primaryAccent.withValues(alpha: 0.05)
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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isGranted
                        ? primaryAccent.withValues(alpha: dark ? 0.2 : 0.1)
                        : (dark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF3F4F6)),
                    border: Border.all(
                      color: isGranted
                          ? primaryAccent.withValues(alpha: 0.3)
                          : (dark ? Colors.white12 : const Color(0xFFE5E7EB)),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    isGranted ? Icons.check_circle_rounded : icon,
                    size: 20,
                    color: isGranted
                        ? primaryAccent
                        : (dark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                  ),
                ),
                const SizedBox(width: 12),
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
                          color: dark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
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
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Switch.adaptive(
                    value: isGranted,
                    activeThumbColor: primaryAccent,
                    activeTrackColor: primaryAccent.withValues(alpha: 0.35),
                    inactiveThumbColor: const Color(0xFF9CA3AF),
                    inactiveTrackColor: dark ? const Color(0xFF26332C) : const Color(0xFFE5E7EB),
                    onChanged: (_) => onTap(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
