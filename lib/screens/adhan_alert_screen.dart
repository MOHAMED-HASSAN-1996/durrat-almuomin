import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/adhan_alert.dart';
import '../services/prayer_alert_service.dart';
import '../theme/app_theme.dart';

/// Screen opened by the system full-screen prayer notification.
/// Plays powerful continuous vibration and automatically closes when the Azan finishes.
class AdhanAlertScreen extends StatefulWidget {
  const AdhanAlertScreen({
    super.key,
    required this.alert,
    this.isStandalone = true,
  });

  final AdhanAlert alert;
  final bool isStandalone;

  @override
  State<AdhanAlertScreen> createState() => _AdhanAlertScreenState();
}

class _AdhanAlertScreenState extends State<AdhanAlertScreen> {
  Timer? _vibrationTimer;
  Timer? _autoCloseTimer;
  StreamSubscription<void>? _finishedSub;
  bool _closing = false;

  @override
  void initState() {
    super.initState();

    // الصوت الوحيد هو صوت قناة الإشعار الشغال فعلاً — لا نعيد التشغيل
    // من الأول (كان playAzan هنا بيلغي القناة ويشغل من الصفر).

    // Self-renewal: while the app is alive, push the 30-day window forward so
    // the schedule never runs out (e.g. the user opens the app once a month
    // and adhans still keep firing). Throttled inside the service.
    PrayerAlertService.instance.ensureScheduleToppedUp();

    // 1. اهتزاز عتادي قوي ومستمر عبر محرك الجهاز الأصلي (Alarm Vibration)
    PlatformPermissions.startAdhanVibration();
    HapticFeedback.heavyImpact();
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 1600), (_) {
      PlatformPermissions.startAdhanVibration();
      HapticFeedback.heavyImpact();
    });

    // 2. الاستماع لانتهاء صوت الأذان لإغلاق الشاشة تلقائياً
    _finishedSub = PrayerAlertService.instance.onAzanFinished.listen((_) {
      _dismiss();
    });

    // 3. مؤقت أمان لغلق الشاشة وقفلها تلقائياً بعد انتهاء مدة الأذان الفعلية (216 ثانية)
    _autoCloseTimer = Timer(const Duration(seconds: 216), () {
      _dismiss();
    });
  }

  void _dismiss() async {
    if (_closing) return;
    _closing = true;
    _vibrationTimer?.cancel();
    _autoCloseTimer?.cancel();
    _finishedSub?.cancel();

    // إيقاف الصوت والاهتزاز فوراً
    await PrayerAlertService.instance.stopAzan();
    await PlatformPermissions.stopAdhanVibration();

    if (widget.isStandalone) {
      // إغلاق الشاشة وقفلها فوراً دون كشف واجهة التطبيق
      await PlatformPermissions.closeAdhanScreen();
      try {
        SystemNavigator.pop();
      } catch (_) {}
    } else {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _vibrationTimer?.cancel();
    _autoCloseTimer?.cancel();
    _finishedSub?.cancel();
    PlatformPermissions.stopAdhanVibration();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B2118),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFC5A059).withValues(alpha: .16),
                    border: Border.all(
                      color: const Color(0xFFC5A059),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.mosque_rounded,
                    color: Color(0xFFC5A059),
                    size: 54,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'الله أكبر',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: DhikrTheme.arabicFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 32,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'حان الآن موعد أذان ${widget.alert.prayerNameAr}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFE8F4ED),
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.alert.prayerNameEn,
                  style: const TextStyle(
                    color: Color(0xFFA7D8BA),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 34),
                FilledButton.icon(
                  onPressed: _dismiss,
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('إيقاف الأذان'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFC5A059),
                    foregroundColor: const Color(0xFF10281D),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    textStyle: const TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.volume_down_rounded, color: Color(0xFF6E8E80), size: 15),
                    SizedBox(width: 6),
                    Text(
                      'أو اضغط زر الصوت للإيقاف',
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        color: Color(0xFF6E8E80),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
