import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/adhan_alert.dart';
import '../services/prayer_alert_service.dart';
import '../theme/app_theme.dart';

/// Screen opened by the system full-screen prayer notification.
/// Plays continuous vibration and automatically closes when the Azan finishes.
class AdhanAlertScreen extends StatefulWidget {
  const AdhanAlertScreen({super.key, required this.alert});

  final AdhanAlert alert;

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

    // 1. اهتزاز مستمر ينبض كل ثانية طوال مدة الأذان
    HapticFeedback.heavyImpact();
    HapticFeedback.vibrate();
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 1100), (_) {
      HapticFeedback.heavyImpact();
      HapticFeedback.vibrate();
    });

    // 2. الاستماع لانتهاء صوت الأذان لإغلاق الشاشة تلقائياً
    _finishedSub = PrayerAlertService.instance.onAzanFinished.listen((_) {
      _dismiss();
    });

    // 3. مؤقت أمان لغلق الشاشة تلقائياً بعد 3.5 دقيقة كحد أقصى (متوسط مدة الأذان)
    _autoCloseTimer = Timer(const Duration(seconds: 210), () {
      _dismiss();
    });
  }

  void _dismiss() {
    if (_closing) return;
    _closing = true;
    _vibrationTimer?.cancel();
    _autoCloseTimer?.cancel();
    _finishedSub?.cancel();
    PrayerAlertService.instance.stopAzan();
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _vibrationTimer?.cancel();
    _autoCloseTimer?.cancel();
    _finishedSub?.cancel();
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
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 116,
                  height: 116,
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
                    size: 58,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'الله أكبر',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: DhikrTheme.arabicFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 34,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'حان الآن موعد أذان ${widget.alert.prayerNameAr}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFE8F4ED),
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.alert.prayerNameEn,
                  style: const TextStyle(
                    color: Color(0xFFA7D8BA),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 42),
                FilledButton.icon(
                  onPressed: _dismiss,
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('إيقاف الأذان'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFC5A059),
                    foregroundColor: const Color(0xFF10281D),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.volume_down_rounded, color: Color(0xFF6E8E80), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'أو اضغط زر الصوت للإيقاف',
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        color: Color(0xFF6E8E80),
                        fontSize: 13,
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
