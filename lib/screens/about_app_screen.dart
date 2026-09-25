import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';

/// صفحة "حول تطبيق درة المؤمن" — تعرض معلومات التطبيق والمطوّر ومصادر الأذكار
class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().language;
    final isAr = lang == AppLanguage.arabic;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: dark ? DhikrColors.darkBg : const Color(0xFFF4F7F5),
        body: CustomScrollView(
          slivers: [
            // ─── AppBar ───
            SliverAppBar(
              expandedHeight: 220,
              floating: false,
              pinned: true,
              backgroundColor: dark ? DhikrColors.darkSurface : const Color(0xFF1E5243),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: dark
                          ? [
                              const Color(0xFF16382E),
                              const Color(0xFF0F2620),
                            ]
                          : [
                              const Color(0xFF1E5243),
                              const Color(0xFF0F2E24),
                            ],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        // App Icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.asset(
                              'assets/images/app_icon.webp',
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: const Color(0xFF2D7A5E),
                                alignment: Alignment.center,
                                child: const Text(
                                  'دُرّة',
                                  style: TextStyle(
                                    fontFamily: DhikrTheme.arabicFont,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isAr ? 'درة المؤمن' : "Durrat Al-Mu'min",
                          style: const TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'v1.0.0',
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                isAr ? 'حول التطبيق' : 'About App',
                style: const TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),

            // ─── Content ───
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // App Description Card
                  _AboutCard(
                    dark: dark,
                    icon: LucideIcons.info,
                    iconColor: const Color(0xFF0F766E),
                    title: isAr ? 'عن التطبيق' : 'About',
                    body: isAr
                        ? 'درة المؤمن هو تطبيق إسلامي شامل يهدف إلى مساعدة المسلم على إحياء وردِه اليومي من الأذكار والأدعية، ومتابعة ختماته القرآنية، ومعرفة مواقيت الصلاة بدقة، مع تنبيهات الأذان في أوقاتها المحددة. صُمِّم التطبيق بعناية ليكون رفيقاً روحانياً يومياً للمؤمن في رحلته مع الله.'
                        : 'Durrat Al-Mu\'min is a comprehensive Islamic app designed to help Muslims revive their daily dhikr routine, track their Quran khatmahs, view accurate prayer times, and receive Adhan alerts at the right moment. Crafted with care to be a daily spiritual companion.',
                  ),
                  const SizedBox(height: 12),

                  // Mission Card
                  _AboutCard(
                    dark: dark,
                    icon: LucideIcons.crosshair,
                    iconColor: const Color(0xFF7C3AED),
                    title: isAr ? 'رسالتنا' : 'Our Mission',
                    body: isAr
                        ? 'نسعى إلى بناء تجربة روحانية متكاملة تُقرّب المسلم من ربه، وتُذكّره بالأذكار في وقتها، وتُعينه على المداومة والثبات في عبادته. "ألا بذكر الله تطمئن القلوب"'
                        : 'We strive to build a complete spiritual experience that brings the Muslim closer to Allah, reminds them of adhkar at the right time, and helps them maintain consistency in worship. "Verily, in the remembrance of Allah do hearts find rest."',
                  ),
                  const SizedBox(height: 12),

                  // Features Card
                  _AboutCard(
                    dark: dark,
                    icon: LucideIcons.sparkles,
                    iconColor: const Color(0xFFF59E0B),
                    title: isAr ? 'مميزات التطبيق' : 'Features',
                    body: null,
                    customChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FeatureRow(icon: LucideIcons.mosque, text: isAr ? 'أذكار الصباح والمساء والسنن' : 'Morning, Evening & Sunnah Adhkar', dark: dark),
                        _FeatureRow(icon: LucideIcons.bookOpen, text: isAr ? 'تلاوة القرآن الكريم بالمصحف الإلكتروني' : 'Quran Reading with Digital Mushaf', dark: dark),
                        _FeatureRow(icon: LucideIcons.clock, text: isAr ? 'مواقيت الصلاة بدقة حسب الموقع' : 'Accurate Prayer Times by Location', dark: dark),
                        _FeatureRow(icon: LucideIcons.bell, text: isAr ? 'تنبيه الأذان عند دخول وقت الصلاة' : 'Adhan Alert at Prayer Time', dark: dark),
                        _FeatureRow(icon: LucideIcons.radio, text: isAr ? 'إذاعة القرآن الكريم المباشرة' : 'Live Quran Radio Streams', dark: dark),
                        _FeatureRow(icon: LucideIcons.calendarDays, text: isAr ? 'متابعة الختمات وسجل الصلوات والسنن' : 'Track Khatmahs & Prayer History', dark: dark),
                        _FeatureRow(icon: LucideIcons.calculator, text: isAr ? 'حاسبة الزكاة والنصاب ومستحقيها' : 'Zakat & Nisab Calculator', dark: dark),
                        _FeatureRow(icon: LucideIcons.moon, text: isAr ? 'التقويم الهجري وأوقات الحرص' : 'Hijri Calendar & Special Times', dark: dark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // How to use Card
                  _AboutCard(
                    dark: dark,
                    icon: LucideIcons.helpCircle,
                    iconColor: const Color(0xFF0284C7),
                    title: isAr ? 'كيفية الاستخدام' : 'How to Use',
                    body: null,
                    customChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StepRow(step: '١', text: isAr ? 'افتح التطبيق بعد صلاة الفجر وابدأ بأذكار الصباح' : 'Open after Fajr and start morning adhkar', dark: dark),
                        _StepRow(step: '٢', text: isAr ? 'تابع أوقات الصلاة من شاشة الرئيسية' : 'Track prayer times from the home screen', dark: dark),
                        _StepRow(step: '٣', text: isAr ? 'سجّل ختمتك القرآنية يومياً من قسم التلاوة' : 'Record your Quran reading daily', dark: dark),
                        _StepRow(step: '٤', text: isAr ? 'أغلق يومك بأذكار المساء قبل النوم' : 'Close your day with evening adhkar before sleep', dark: dark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Sources Card
                  _AboutCard(
                    dark: dark,
                    icon: LucideIcons.library,
                    iconColor: const Color(0xFF0F766E),
                    title: isAr ? 'مصادر الأذكار' : 'Sources',
                    body: isAr
                        ? 'صحيح البخاري ومسلم، سنن أبي داود والترمذي، مسند الإمام أحمد، حصن المسلم من أذكار الكتاب والسنة للإمام النووي، والأذكار للشيخ ابن باز والشيخ ابن عثيمين رحمهم الله.'
                        : 'Sahih al-Bukhari, Sahih Muslim, Sunan Abi Dawud, Sunan at-Tirmidhi, Musnad Ahmad, and Hisnul Muslim — verified with authentic chains of narration.',
                  ),
                  const SizedBox(height: 12),

                  // Developer Card
                  _AboutCard(
                    dark: dark,
                    icon: LucideIcons.code2,
                    iconColor: const Color(0xFF2563EB),
                    title: isAr ? 'برمجة وتصميم' : 'Development & Design',
                    body: null,
                    customChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.asset(
                                'assets/images/m_logo.webp',
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF1E5243), Color(0xFF0F2E24)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    'M',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 22,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAr ? 'محمد حسن' : 'Mohamed Hassan',
                                    style: TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isAr ? 'مطوّر ومصمم تطبيقات' : 'App Developer & Designer',
                                    style: TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontSize: 12,
                                      color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              final uri = Uri.parse('https://www.behance.net/mohameduxi');
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0057FF).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF0057FF).withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(LucideIcons.externalLink, size: 16, color: Color(0xFF0057FF)),
                                  const SizedBox(width: 8),
                                  Text(
                                    isAr ? 'معرض الأعمال على Behance' : 'View Portfolio on Behance',
                                    style: const TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0057FF),
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
                  const SizedBox(height: 12),

                  // Contact / Support Card
                  _AboutCard(
                    dark: dark,
                    icon: LucideIcons.messageCircle,
                    iconColor: const Color(0xFF059669),
                    title: isAr ? 'التواصل والدعم' : 'Contact & Support',
                    body: null,
                    customChild: Column(
                      children: [
                        _ContactButton(
                          dark: dark,
                          icon: LucideIcons.mail,
                          label: isAr ? 'تواصل معنا عبر البريد' : 'Email Us',
                          color: const Color(0xFF059669),
                          onTap: () => _showEmailFormSheet(context, isAr, dark),
                        ),
                        const SizedBox(height: 8),
                        _ContactButton(
                          dark: dark,
                          icon: LucideIcons.messageCircle,
                          label: isAr ? 'راسلنا على واتساب' : 'Chat on WhatsApp',
                          color: const Color(0xFF25D366),
                          url: 'https://wa.me/201273232035',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Legal
                  _AboutCard(
                    dark: dark,
                    icon: LucideIcons.shieldCheck,
                    iconColor: const Color(0xFF059669),
                    title: isAr ? 'الخصوصية والبيانات' : 'Privacy & Data',
                    body: isAr
                        ? 'يحترم التطبيق خصوصيتك التامة. جميع بيانات الأذكار والختمات محفوظة محلياً على جهازك. لا يتم مشاركة أي بيانات شخصية مع أطراف ثالثة دون إذنك الصريح.'
                        : 'Your privacy is fully respected. Adhkar and khatmah data is stored locally on your device. No personal data is shared with third parties without your explicit consent.',
                  ),
                  const SizedBox(height: 12),

                  // Version Info
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                    decoration: BoxDecoration(
                      color: dark ? DhikrColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: dark
                            ? Colors.white.withValues(alpha: 0.07)
                            : DhikrColors.charcoal.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: (dark ? DhikrColors.sage : DhikrColors.forest).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(LucideIcons.tag, size: 18, color: dark ? DhikrColors.sage : DhikrColors.forest),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr ? 'إصدار التطبيق' : 'App Version',
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                                ),
                              ),
                              Text(
                                'v1.0.0 — ${isAr ? "الإصدار الأول" : "Initial Release"}',
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 12,
                                  color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (dark ? DhikrColors.sage : DhikrColors.forest).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'v1.0.0',
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: dark ? DhikrColors.sage : DhikrColors.forest,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Bottom tagline
                  Center(
                    child: Column(
                      children: [
                        Text(
                          isAr
                              ? '﴿ وَاذْكُرُوا اللَّهَ كَثِيرًا لَعَلَّكُمْ تُفْلِحُونَ ﴾'
                              : '﴿ Remember Allah often that you may succeed ﴾',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: (dark ? DhikrColors.sage : DhikrColors.forest).withValues(alpha: 0.75),
                            height: 1.7,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isAr ? '— سورة الجمعة: ١٠ —' : '— Surah Al-Jumu\'ah: 10 —',
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontSize: 11,
                            color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmailFormSheet(BuildContext context, bool isAr, bool dark) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: dark ? DhikrColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  isAr ? 'راسلنا عبر البريد' : 'Email Us',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isAr
                      ? 'املأ النموذج وسنفتح تطبيق البريد لديك'
                      : 'Fill the form and we will open your email app',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 13,
                    color: dark
                        ? DhikrColors.darkMuted
                        : DhikrColors.charcoalSoft,
                  ),
                ),
                const SizedBox(height: 18),
                _FormLabeledField(
                  isAr: isAr,
                  dark: dark,
                  label: isAr ? 'الاسم' : 'Name',
                  controller: nameController,
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 12),
                _FormLabeledField(
                  isAr: isAr,
                  dark: dark,
                  label: isAr ? 'بريدك الإلكتروني' : 'Your Email',
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty || !value.contains('@')) {
                      return isAr
                          ? 'أدخل بريدًا صحيحًا'
                          : 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _FormLabeledField(
                  isAr: isAr,
                  dark: dark,
                  label: isAr ? 'الرسالة' : 'Message',
                  controller: messageController,
                  maxLines: 5,
                  validator: (v) {
                    if ((v ?? '').trim().isEmpty) {
                      return isAr ? 'اكتب رسالتك' : 'Write your message';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      HapticFeedback.mediumImpact();
                      final name = nameController.text.trim();
                      final email = emailController.text.trim();
                      final message = messageController.text.trim();
                      final subject =
                          isAr ? 'رسالة من تطبيق درة المؤمن' : 'Message from Durrat Al-Mu\'min';
                      final body = isAr
                          ? 'الاسم: $name\nالبريد: $email\n\n$message'
                          : 'Name: $name\nEmail: $email\n\n$message';
                      final uri = Uri(
                        scheme: 'mailto',
                        path: 'durratalmumin.app@gmail.com',
                        queryParameters: {
                          'subject': subject,
                          'body': body,
                        },
                      );
                      Navigator.pop(ctx);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Text(
                      isAr ? 'إرسال' : 'Send',
                      style: const TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      nameController.dispose();
      emailController.dispose();
      messageController.dispose();
    });
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({
    required this.dark,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.body,
    this.customChild,
  });

  final bool dark;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? body;
  final Widget? customChild;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? DhikrColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.07)
              : DhikrColors.charcoal.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                ),
              ),
            ],
          ),
          if (body != null || customChild != null) ...[
            const SizedBox(height: 12),
            if (body case final b?) Text(
              b,
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 13,
                height: 1.7,
                color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
              ),
            ),
            ?customChild,
          ],
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.text,
    required this.dark,
  });

  final IconData icon;
  final String text;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF0F766E),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.text,
    required this.dark,
  });

  final String step;
  final String text;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              step,
              style: const TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                color: Color(0xFF0F766E),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.dark,
    required this.icon,
    required this.label,
    required this.color,
    this.url,
    this.onTap,
  });

  final bool dark;
  final IconData icon;
  final String label;
  final Color color;
  final String? url;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          HapticFeedback.lightImpact();
          if (onTap != null) {
            onTap!();
            return;
          }
          final link = url;
          if (link == null) return;
          final uri = Uri.parse(link);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormLabeledField extends StatelessWidget {
  const _FormLabeledField({
    required this.isAr,
    required this.dark,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  final bool isAr;
  final bool dark;
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final borderColor = dark
        ? Colors.white.withValues(alpha: 0.1)
        : DhikrColors.charcoal.withValues(alpha: 0.1);
    final fillColor = dark
        ? Colors.white.withValues(alpha: 0.04)
        : const Color(0xFFF4F7F5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            fontSize: 14,
            color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF059669),
                width: 1.6,
              ),
            ),
            errorStyle: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}
