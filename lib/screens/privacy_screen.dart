import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';

/// Full-page Privacy & Security Policy screen.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().language;
    final isAr = lang == AppLanguage.arabic;
    final dark = Theme.of(context).brightness == Brightness.dark;

    final points = isAr
        ? [
            {
              'icon': LucideIcons.shieldCheck,
              'title': 'حفظ محلي وأمان مطلق (100% Offline-First)',
              'desc':
                  'جميع أذكارك، تسبيحاتك، تقدمك، ومفضلاتك القرآنية مخزنة على جهازك فقط. التطبيق لا يسجل ولا يرسل أي بيانات شخصية إلى أي خوادم خارجية.',
            },
            {
              'icon': LucideIcons.mapPin,
              'title': 'إذن الموقع الجغرافي (حساب الصلاة والقبلة فقط)',
              'desc':
                  'يُطلب إذن الموقع لغرض وحيد وحصري وهو حساب مواقيت الصلاة بدقة فلكية حسب مدينتك وتحديد اتجاه القبلة المشرفة. لا يتم تتبع حركتك ولا مشاركة إحداثياتك.',
            },
            {
              'icon': LucideIcons.ban,
              'title': 'خالٍ تماماً من الإعلانات ومن أدوات التعقب',
              'desc':
                  'التطبيق وقف إسلامي خالص لوجه الله، لا يحتوي على إعلانات تجارية مزعجة، ولا يحتوي على برمجيات استهداف إعلاني أو بيع بيانات.',
            },
            {
              'icon': LucideIcons.bellRing,
              'title': 'جدولة التنبيهات والأذان محلياً',
              'desc':
                  'تنبيهات الأذان والأذكار تُجدول محلياً على هاتفك الذكي وتعمل حتى في حال انقطاع الإنترنت أو قفل الشاشة دون الاعتماد على خدمات تتبع.',
            },
            {
              'icon': LucideIcons.heartHandshake,
              'title': 'تصميم وإشراف مستقل لوجه الله',
              'desc':
                  'صُمم تطبيق «درة المؤمن» بعناية فائقة بواسطة محمد (Mohamed UX/UI) بأعلى معايير الإتقان والتجربة الهادئة لنيل الأجر والثواب.',
            },
          ]
        : [
            {
              'icon': LucideIcons.shieldCheck,
              'title': '100% Offline & Absolute Privacy',
              'desc':
                  'All your dhikr counts, tasbih logs, Quran bookmarks, and favorites stay strictly on your local device. We never harvest or transmit your personal data.',
            },
            {
              'icon': LucideIcons.mapPin,
              'title': 'Location Used Exclusively for Prayer & Qibla',
              'desc':
                  'Location permission is used strictly to calculate accurate prayer timings and determine Qibla direction. It is never tracked or shared.',
            },
            {
              'icon': LucideIcons.ban,
              'title': 'Zero Ads & Zero Tracking SDKs',
              'desc':
                  'The app is completely ad-free and tracking-free. No commercial trackers or data brokers are embedded.',
            },
            {
              'icon': LucideIcons.bellRing,
              'title': 'Local Offline Azan Scheduling',
              'desc':
                  'Prayer calls and alerts run locally through your device operating system without requiring persistent background telemetry.',
            },
            {
              'icon': LucideIcons.heartHandshake,
              'title': 'Artisanal Craftsmanship',
              'desc':
                  'Designed and crafted by Mohamed (UX/UI Designer) to provide a serene, premium Islamic companion.',
            },
          ];

    return Scaffold(
      backgroundColor: dark ? const Color(0xFF0D1B14) : Colors.white,
      appBar: AppBar(
        backgroundColor: dark ? const Color(0xFF0D1B14) : Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: dark ? Colors.white70 : DhikrColors.charcoal,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isAr ? 'سياسة الخصوصية والأمان' : 'Privacy & Security Policy',
          style: TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: dark ? Colors.white : DhikrColors.charcoal,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E5243).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.shieldCheck,
                  color: Color(0xFF1E5243),
                  size: 24,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                isAr ? 'وثيقة سياسة الخصوصية والأمان' : 'Privacy & Security Policy',
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: dark ? Colors.white : DhikrColors.charcoal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isAr
                ? 'تطبيق «درة المؤمن» — أمانك وسكينتك في المقام الأول'
                : 'Durrat Al-Mu\u2019min — Your Privacy & Peace of Mind First',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontSize: 12.5,
              color: dark ? Colors.white54 : DhikrColors.charcoalSoft,
            ),
          ),
          const SizedBox(height: 20),
          ...points.map((p) => Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: dark
                      ? const Color(0xFF1A2822)
                      : const Color(0xFFF3F8F5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF1E5243).withValues(
                      alpha: dark ? 0.25 : 0.12,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E5243).withValues(
                          alpha: dark ? 0.3 : 0.15,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        p['icon'] as IconData,
                        size: 18,
                        color: dark
                            ? const Color(0xFF5EEAD4)
                            : const Color(0xFF1E5243),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['title'] as String,
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: dark
                                  ? Colors.white
                                  : DhikrColors.charcoal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p['desc'] as String,
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontSize: 12,
                              height: 1.5,
                              color: dark
                                  ? Colors.white70
                                  : DhikrColors.charcoalSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1E5243),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              isAr ? 'فهمت وأوافق' : 'Understood & Agreed',
              style: const TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
