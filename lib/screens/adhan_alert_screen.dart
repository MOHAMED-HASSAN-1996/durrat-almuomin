import 'package:flutter/material.dart';

import '../services/adhan_alert.dart';
import '../services/prayer_alert_service.dart';
import '../theme/app_theme.dart';

/// Screen opened by the system full-screen prayer notification.
class AdhanAlertScreen extends StatelessWidget {
  const AdhanAlertScreen({super.key, required this.alert});

  final AdhanAlert alert;

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
                  'حان الآن موعد أذان ${alert.prayerNameAr}',
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
                  alert.prayerNameEn,
                  style: const TextStyle(
                    color: Color(0xFFA7D8BA),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 42),
                FilledButton.icon(
                  onPressed: () async {
                    PrayerAlertService.instance.stopAzan();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('إيقاف الأذان'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFC5A059),
                    foregroundColor: const Color(0xFF10281D),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
