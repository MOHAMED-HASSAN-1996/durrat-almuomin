import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';

/// Umrah Rituals data model
class UmrahStep {
  const UmrahStep({
    required this.id,
    required this.title,
    required this.description,
    required this.details,
    this.iconData,
  });

  final String id;
  final String title;
  final String description;
  final String details;
  final IconData? iconData;
}

/// Umrah Rituals Screen - beautiful step-by-step guide
class UmrahScreen extends StatelessWidget {
  const UmrahScreen({super.key});

  static final List<UmrahStep> steps = [
    UmrahStep(
      id: 'ihram',
      title: 'الإحرام',
      description: 'نية الدخول في النسك والتلبية',
      details: 'تنوي الدخول في العمرة بقلبك، ثم تلبي قائلا: "لبيك اللهم عمرة". يستحب الغسل والطيب قبل الإحرام. يلبس الرجل إزارا ورداء أبيضين، وتلبس المرأة ما شاءت من الثياب الشرعية دون نقاب وقفازين.',
      iconData: Icons.checkroom_rounded,
    ),
    UmrahStep(
      id: 'tawaf',
      title: 'الطواف',
      description: 'الطواف بالبيت سبعة أشواط',
      details: 'تدخل المسجد الحرام، وتتوجه إلى الحجر الأسود لتبدأ الطواف. يجعل البيت عن يساره، ويطوف سبعة أشواط. يستحب استلام الحجر الأسود أو الإشارة إليه في كل شوط. يستحب الرمل (الإسراع في المشي مع تقارب الخطوات) في الأشواط الثلاثة الأولى للرجال.',
      iconData: Icons.rotate_right_rounded,
    ),
    UmrahStep(
      id: 'saee',
      title: 'السعي',
      description: 'السعي بين الصفا والمروة',
      details: 'بعد الطواف تتوجه إلى الصفا، وتقرأ قوله تعالى: {إن الصفا والمروة من شعائر الله}. ثم تسعى بين الصفا والمروة سبعة أشواط، يبدأ بالصفا وينتهي بالمروة. يستحب في السعي الإسراع بين العلمين الأخضرين للرجال.',
      iconData: Icons.directions_walk_rounded,
    ),
    UmrahStep(
      id: 'halq',
      title: 'الحلق أو التقصير',
      description: 'الحلق أو التقصير لإنهاء العمرة',
      details: 'بعد السعي يحلق رأسه أو يقصر منه. الحلق أفضل للرجال، أما المرأة فتقص من أطراف شعرها قدر أنملة. وبذلك تتحلل من إحرامك وتنتهي العمرة. قال النبي ﷺ: "اللهم ارحم المحلقين" قالوا: والمقصرين يا رسول الله، قال: "اللهم ارحم المحلقين" قالوا: والمقصرين يا رسول الله، قال: "والمقصرين".',
      iconData: Icons.content_cut_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().language;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isArabic = lang == AppLanguage.arabic;

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'مناسك العمرة' : 'Umrah Rituals'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: dark
                          ? [DhikrColors.darkSurface, DhikrColors.darkSurfaceHigh]
                          : [DhikrColors.forest.withValues(alpha: 0.08), DhikrColors.sage.withValues(alpha: 0.05)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: dark
                          ? Colors.white.withValues(alpha: 0.08)
                          : DhikrColors.charcoal.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        isArabic ? '🕋' : '🕋',
                        style: const TextStyle(fontSize: 40),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isArabic
                            ? 'رحلة العمرة'
                            : 'The Journey of Umrah',
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isArabic
                            ? 'في رحاب بيت الله الحرام، عبادة عظيمة شرف الله بها عباده'
                            : 'In the courtyards of the Sacred House of Allah — a great act of worship',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: 14,
                          height: 1.6,
                          color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Steps
                ...steps.asMap().entries.map((entry) {
                  final index = entry.key;
                  final step = entry.value;
                  final isLast = index == steps.length - 1;
                  return _buildStepCard(
                    context,
                    step,
                    index + 1,
                    isLast,
                    isArabic,
                    dark,
                  );
                }),
                const SizedBox(height: 20),
                // Hadith
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (dark ? DhikrColors.sage : DhikrColors.forest)
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: (dark ? DhikrColors.sage : DhikrColors.forest)
                          .withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.format_quote_rounded,
                        size: 24,
                        color: dark ? DhikrColors.sage : DhikrColors.forest,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isArabic
                            ? 'العمرة إلى العمرة كفارة لما بينهما'
                            : '"Umrah to Umrah is an expiation for what is between them."',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.6,
                          color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isArabic ? '— النبي ﷺ' : '— Prophet Muhammad ﷺ',
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
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard(
    BuildContext context,
    UmrahStep step,
    int stepNumber,
    bool isLast,
    bool isArabic,
    bool dark,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step number and line
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: dark ? DhikrColors.sage : DhikrColors.forest,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$stepNumber',
                  style: const TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: (dark ? DhikrColors.sage : DhikrColors.forest)
                    .withValues(alpha: 0.3),
              ),
          ],
        ),
        const SizedBox(width: 14),
        // Content
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: dark ? DhikrColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: dark
                    ? Colors.white.withValues(alpha: 0.08)
                    : DhikrColors.charcoal.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (step.iconData != null) ...[
                      Icon(
                        step.iconData,
                        size: 20,
                        color: dark ? DhikrColors.sage : DhikrColors.forest,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        step.title,
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  step.description,
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: dark ? DhikrColors.darkMuted : DhikrColors.forestLight,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  step.details,
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 13,
                    height: 1.7,
                    color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
