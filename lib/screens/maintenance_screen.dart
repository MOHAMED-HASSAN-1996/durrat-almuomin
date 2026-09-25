import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/remote_content_service.dart';
import '../theme/app_theme.dart';

/// Full-screen respectful maintenance gate.
/// Triggered whenever `maintenanceMode == true` in remote config.
class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  bool _isChecking = false;

  Future<void> _checkStatus() async {
    setState(() => _isChecking = true);
    await RemoteContentService.instance.refreshConfig();
    if (mounted) {
      setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final message = RemoteContentService.instance.maintenanceMessage;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: dark ? DhikrColors.darkBg : const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Emblem / Mosque icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: dark
                            ? [const Color(0xFF064E3B), const Color(0xFF022C22)]
                            : [const Color(0xFFD1FAE5), const Color(0xFFA7F3D0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.25),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        LucideIcons.hammer,
                        size: 44,
                        color: dark ? const Color(0xFF34D399) : const Color(0xFF059669),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Title
                  Text(
                    'أعمال صيانة وتطوير 🌿',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: dark ? Colors.white : DhikrColors.charcoal,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // App Subtitle
                  Text(
                    'تطبيق درة المؤمن',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF10B981),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Dynamic Admin Message Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: dark ? DhikrColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: dark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: dark ? 0.2 : 0.04),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          message.isNotEmpty
                              ? message
                              : 'نقوم حالياً ببعض التحسينات والصيانة الدورية لتقديم تجربة أفضل، وسيعود التطبيق للعمل خلال وقت وجيز بإذن الله.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontSize: 15,
                            height: 1.8,
                            fontWeight: FontWeight.w500,
                            color: dark ? DhikrColors.darkMuted : const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.heartHandshake,
                              size: 16,
                              color: dark ? const Color(0xFF34D399) : const Color(0xFF059669),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'شكراً لصبركم وحسن تفهمكم',
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: dark ? const Color(0xFF34D399) : const Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Retry / Check button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isChecking ? null : _checkStatus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isChecking
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(LucideIcons.refreshCw, size: 18),
                                const SizedBox(width: 10),
                                Text(
                                  'التحقق من حالة التطبيق',
                                  style: TextStyle(
                                    fontFamily: DhikrTheme.arabicFont,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
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
}
