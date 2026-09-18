import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';

/// بطاقة وتعريف صلاة النافلة
class NafilaItem {
  final String keyId;
  final String titleAr;
  final String titleEn;
  final String rakahsAr;
  final String rakahsEn;
  final String timingAr;
  final String timingEn;
  final bool isConfirmedSunnah; // سنة مؤكدة
  final String? hadithAr;

  const NafilaItem({
    required this.keyId,
    required this.titleAr,
    required this.titleEn,
    required this.rakahsAr,
    required this.rakahsEn,
    required this.timingAr,
    required this.timingEn,
    this.isConfirmedSunnah = true,
    this.hadithAr,
  });
}

const List<NafilaItem> allNawafilList = [
  NafilaItem(
    keyId: 'sunnah_fajr',
    titleAr: 'سُنَّة الفجر',
    titleEn: 'Fajr Sunnah',
    rakahsAr: 'ركعتان قبل الفريضة',
    rakahsEn: '2 Rak\'ahs before Fajr',
    timingAr: 'قبل صلاة الصبح مباشرة',
    timingEn: 'Before Fajr obligatory prayer',
    isConfirmedSunnah: true,
    hadithAr: '«رَكْعَتَا الْفَجْرِ خَيْرٌ مِنَ الدُّنْيَا وَمَا فِيهَا» (مسلم)',
  ),
  NafilaItem(
    keyId: 'duha',
    titleAr: 'صلاة الضحى',
    titleEn: 'Duha Prayer',
    rakahsAr: 'ركعتان إلى ٨ ركعات',
    rakahsEn: '2 to 8 Rak\'ahs',
    timingAr: 'بعد شروق الشمس بـ ١٥ دقيقة إلى قبيل الظهر',
    timingEn: '15 min after sunrise until Dhuhr',
    isConfirmedSunnah: false,
    hadithAr: '«يُصْبِحُ عَلَى كُلِّ سُلاَمَى مِنْ أَحَدِكُمْ صَدَقَةٌ... وَيُجْزِئُ مِنْ ذَلِكَ رَكْعَتَانِ يَرْكَعُهُمَا مِنَ الضُّحَى»',
  ),
  NafilaItem(
    keyId: 'sunnah_dhuhr_before',
    titleAr: 'سُنَّة الظهر القبلية',
    titleEn: 'Before Dhuhr Sunnah',
    rakahsAr: '٤ ركعات (مثنى مثنى)',
    rakahsEn: '4 Rak\'ahs (2+2)',
    timingAr: 'بعد أذان الظهر وقبل الفريضة',
    timingEn: 'After Dhuhr Adhan, before obligatory',
    isConfirmedSunnah: true,
    hadithAr: 'من السنن الرواتب الثنتي عشرة التي تبني بيتاً في الجنة',
  ),
  NafilaItem(
    keyId: 'sunnah_dhuhr_after',
    titleAr: 'سُنَّة الظهر البعدية',
    titleEn: 'After Dhuhr Sunnah',
    rakahsAr: 'ركعتان بعد الفريضة',
    rakahsEn: '2 Rak\'ahs after Dhuhr',
    timingAr: 'بعد فريضة الظهر مباشرة',
    timingEn: 'Immediately after Dhuhr',
    isConfirmedSunnah: true,
  ),
  NafilaItem(
    keyId: 'sunnah_asr',
    titleAr: 'سُنَّة العصر المستحبة',
    titleEn: 'Asr Sunnah',
    rakahsAr: '٤ ركعات قبل الفريضة',
    rakahsEn: '4 Rak\'ahs before Asr',
    timingAr: 'قبل فريضة العصر',
    timingEn: 'Before Asr prayer',
    isConfirmedSunnah: false,
    hadithAr: '«رَحِمَ اللَّهُ امْرَأً صَلَّى قَبْلَ الْعَصْرِ أَرْبَعاً» (الترمذي)',
  ),
  NafilaItem(
    keyId: 'sunnah_maghrib',
    titleAr: 'سُنَّة المغرب البعدية',
    titleEn: 'After Maghrib Sunnah',
    rakahsAr: 'ركعتان بعد الفريضة',
    rakahsEn: '2 Rak\'ahs after Maghrib',
    timingAr: 'بعد فريضة المغرب مباشرة',
    timingEn: 'Immediately after Maghrib',
    isConfirmedSunnah: true,
  ),
  NafilaItem(
    keyId: 'sunnah_isha',
    titleAr: 'سُنَّة العشاء البعدية',
    titleEn: 'After Isha Sunnah',
    rakahsAr: 'ركعتان بعد الفريضة',
    rakahsEn: '2 Rak\'ahs after Isha',
    timingAr: 'بعد فريضة العشاء مباشرة',
    timingEn: 'Immediately after Isha',
    isConfirmedSunnah: true,
  ),
  NafilaItem(
    keyId: 'qiyam_witr',
    titleAr: 'قيام الليل والشفع والوتر',
    titleEn: 'Qiyam & Witr',
    rakahsAr: 'ركعة أو ٣ أو أكثر',
    rakahsEn: '1, 3 or more Rak\'ahs',
    timingAr: 'من بعد العشاء إلى طلوع الفجر',
    timingEn: 'From Isha until Fajr',
    isConfirmedSunnah: true,
    hadithAr: '«إِنَّ اللَّهَ وِتْرٌ يُحِبُّ الْوِتْرَ فَأَوْتِرُوا يَا أَهْلَ الْقُرْآنِ»',
  ),
];

/// واجهة منبثقة راقية لمتابعة صلوات النوافل والسنن اليومية — مطابقة لتصميم الصورة
class NawafilTrackerSheet extends StatelessWidget {
  const NawafilTrackerSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NawafilTrackerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isAr = appState.language == AppLanguage.arabic;
    final dark = Theme.of(context).brightness == Brightness.dark;

    final completedCount = appState.completedNawafilTasksCount;
    final totalNawafil = allNawafilList.length;

    const goldAccent = Color(0xFFD97706);
    final greenDark = dark ? const Color(0xFF0F3B2C) : const Color(0xFF0F6B5E);
    final bgColor = dark ? const Color(0xFF0A1A14) : const Color(0xFFF5F7F5);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // ── Drag Handle ──
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: dark ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // ── AppBar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  // X Close
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Title
                  Column(
                    children: [
                      Text(
                        isAr ? 'صلوات النوافل والسنن الرواتب' : 'Nawafil & Sunnah Prayers',
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          color: dark ? Colors.white : DhikrColors.charcoal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAr
                            ? 'أجزأت اليوم $completedCount من $totalNawafil نافلة'
                            : 'Today: $completedCount of $totalNawafil completed',
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Info Guide Button
                  GestureDetector(
                    onTap: () => _showNawafilGuide(context, isAr, dark),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: goldAccent.withValues(alpha: dark ? 0.18 : 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(LucideIcons.info, size: 18, color: goldAccent),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // ── Hadith Banner ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: greenDark.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: greenDark.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '🤲',
                      style: TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '«من صلى في يوم وليلة ثنتي عشرة ركعة بنى له بيت في الجنة»',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: greenDark,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // ── Nawafil List ──
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                itemCount: allNawafilList.length,
                itemBuilder: (context, index) {
                  final item = allNawafilList[index];
                  final isDone = appState.isNawafilTaskCompleted(item.keyId);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        appState.toggleNawafilTask(item.keyId);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: dark ? DhikrColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDone
                                ? greenDark.withValues(alpha: 0.5)
                                : (dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE8ECE9)),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: dark ? 0.12 : 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Circle Checkbox
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDone ? greenDark : Colors.transparent,
                                border: Border.all(
                                  color: isDone ? greenDark : (dark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFD0D5D1)),
                                  width: 2,
                                ),
                              ),
                              child: isDone
                                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            // Text Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.titleAr,
                                          style: TextStyle(
                                            fontFamily: DhikrTheme.arabicFont,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14.5,
                                            color: isDone
                                                ? (dark ? Colors.white.withValues(alpha: 0.5) : DhikrColors.charcoal.withValues(alpha: 0.5))
                                                : (dark ? Colors.white : DhikrColors.charcoal),
                                          ),
                                        ),
                                      ),
                                      if (item.isConfirmedSunnah)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: goldAccent.withValues(alpha: dark ? 0.15 : 0.10),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'سنة مؤكدة',
                                            style: TextStyle(
                                              fontFamily: DhikrTheme.arabicFont,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 10,
                                              color: goldAccent,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.rakahsAr} . ${item.timingAr}',
                                    style: TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 11.5,
                                      color: isDone
                                          ? (dark ? Colors.white.withValues(alpha: 0.3) : DhikrColors.charcoalSoft.withValues(alpha: 0.5))
                                          : (dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNawafilGuide(BuildContext context, bool isAr, bool dark) {
    HapticFeedback.selectionClick();
    final bgColor = dark ? const Color(0xFF0F1714) : Colors.white;
    final cardColor = dark ? const Color(0xFF16231E) : const Color(0xFFF6F8F6);
    final borderColor = dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8E4);
    final textColor = dark ? Colors.white : const Color(0xFF1A241F);
    final mutedColor = dark ? const Color(0xFF9EABA2) : const Color(0xFF5A665E);
    const emerald = Color(0xFF059669);
    const gold = Color(0xFFD97706);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            height: MediaQuery.of(ctx).size.height * 0.88,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Drag handle
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: dark ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: emerald.withValues(alpha: dark ? 0.2 : 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(LucideIcons.bookOpen, size: 20, color: emerald),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isAr
                              ? 'دليل النوافل والسنن الرواتب وقيام الليل'
                              : 'Guide to Nawafil, Sunan & Qiyam',
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: textColor,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: dark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: mutedColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: borderColor),
                // Scrollable Content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
                    children: [
                      // Intro Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: emerald.withValues(alpha: dark ? 0.15 : 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: emerald.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('💡', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isAr
                                    ? 'الصلوات المذكورة كلها صلوات تطوع وليست فرضًا، لكنها تختلف في معناها ووقتها. والأصل أن يحافظ المسلم على الصلوات المفروضة أولًا، ثم يؤدي من النوافل ما يستطيع.'
                                    : 'All these prayers are voluntary and not obligatory, varying in their times and significance. A Muslim should always preserve obligatory prayers first, then perform what they can of Nawafil.',
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  height: 1.6,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Section 1: ما هي النوافل؟
                      _buildGuideCard(
                        dark: dark,
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        mutedColor: mutedColor,
                        icon: '🌿',
                        title: isAr ? 'ما هي النوافل؟' : 'What are Nawafil?',
                        body: isAr
                            ? 'النوافل هي كل صلاة زائدة على الصلوات الخمس المفروضة، ومن أمثلتها:\n'
                              '• السنن الرواتب.\n'
                              '• صلاة الضحى.\n'
                              '• قيام الليل والتهجد.\n'
                              '• صلاة الوتر.\n'
                              '• تحية المسجد، صلاة الاستخارة، صلاة التوبة وغيرها من المستحبات.\n\n'
                              '📌 قاعدة: كل سنة راتبة تُعد نافلة، لكن ليست كل نافلة سنة راتبة.'
                            : 'Nawafil are all extra voluntary prayers beyond the 5 obligatory prayers (Sunan Rawatib, Duha, Qiyam, Witr, Tahiyyat Al-Masjid, Istikhara, etc.).\n\nRule: Every Sunnah Ratibah is a Nafilah, but not every Nafilah is a Sunnah Ratibah.',
                      ),
                      const SizedBox(height: 12),

                      // Section 2: ما هي السنن الرواتب؟ (مع الجدول)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('⭐', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Text(
                                  isAr ? 'ما هي السنن الرواتب؟' : 'What are Sunan Rawatib?',
                                  style: TextStyle(
                                    fontFamily: DhikrTheme.arabicFont,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isAr
                                  ? 'هي الصلوات المرتبطة بالصلوات المفروضة، وعددها المشهور ١٢ ركعة تبني بيتاً في الجنة:'
                                  : 'They are the prayers connected to the obligatory prayers, famously 12 Rak\'ahs:',
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: mutedColor,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Table
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                              ),
                              child: Table(
                                border: TableBorder.symmetric(
                                  inside: BorderSide(color: borderColor, width: 0.8),
                                ),
                                children: [
                                  TableRow(
                                    decoration: BoxDecoration(
                                      color: emerald.withValues(alpha: dark ? 0.2 : 0.08),
                                    ),
                                    children: [
                                      _tableCell(isAr ? 'الصلاة' : 'Prayer', textColor, isHeader: true),
                                      _tableCell(isAr ? 'السنة القبلية' : 'Before', textColor, isHeader: true),
                                      _tableCell(isAr ? 'السنة البعدية' : 'After', textColor, isHeader: true),
                                    ],
                                  ),
                                  TableRow(children: [
                                    _tableCell(isAr ? 'الفجر' : 'Fajr', textColor),
                                    _tableCell(isAr ? 'ركعتان' : '2 Rak\'ahs', textColor),
                                    _tableCell('—', mutedColor),
                                  ]),
                                  TableRow(children: [
                                    _tableCell(isAr ? 'الظهر' : 'Dhuhr', textColor),
                                    _tableCell(isAr ? '٤ ركعات' : '4 Rak\'ahs', textColor),
                                    _tableCell(isAr ? 'ركعتان' : '2 Rak\'ahs', textColor),
                                  ]),
                                  TableRow(children: [
                                    _tableCell(isAr ? 'العصر' : 'Asr', textColor),
                                    _tableCell('—', mutedColor),
                                    _tableCell('—', mutedColor),
                                  ]),
                                  TableRow(children: [
                                    _tableCell(isAr ? 'المغرب' : 'Maghrib', textColor),
                                    _tableCell('—', mutedColor),
                                    _tableCell(isAr ? 'ركعتان' : '2 Rak\'ahs', textColor),
                                  ]),
                                  TableRow(children: [
                                    _tableCell(isAr ? 'العشاء' : 'Isha', textColor),
                                    _tableCell('—', mutedColor),
                                    _tableCell(isAr ? 'ركعتان' : '2 Rak\'ahs', textColor),
                                  ]),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              isAr
                                  ? '• المجموع: ١٢ ركعة (وهناك قول آخر بـ ١٠ ركعات بأداء ركعتين فقط قبل الظهر، فيصلي ركعتين أو أربعاً حسب الاستطاعة).\n'
                                    '• ركعتا الفجر من آكد السنن، فقد كان النبي ﷺ يواظب عليهما حضراً وسفراً.'
                                  : '• Total: 12 Rak\'ahs (or 10 by praying 2 before Dhuhr).\n• Fajr Sunnah is the most confirmed Sunnah.',
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                height: 1.6,
                                color: mutedColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Section 3: ما هو قيام الليل؟
                      _buildGuideCard(
                        dark: dark,
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        mutedColor: mutedColor,
                        icon: '🌙',
                        title: isAr ? 'ما هو قيام الليل؟' : 'What is Qiyam Al-Layl?',
                        body: isAr
                            ? 'هو العبادة التي تكون من بعد صلاة العشاء وحتى أذان الفجر، ولا يقتصر على الصلاة فقط، بل يشمل: الصلاة، قراءة القرآن، الذكر، الدعاء، والاستغفار.\n\n'
                              'وعندما يُقال "صلاة قيام الليل"، فالمقصود غالبًا الصلاة النافلة التي تؤدى في هذا الوقت. وتُصلّى مثنى مثنى (ركعتين ركعتين)، وليس لها عدد محدد لازم فيمكن أداء ركعتين أو أكثر حسب القدرة.'
                            : 'Worship from after Isha until Fajr. Includes prayer, Quran recitation, dhikr, dua, and istighfar. Prayed in sets of 2 Rak\'ahs with no fixed upper limit.',
                      ),
                      const SizedBox(height: 12),

                      // Section 4: ما هو التهجد؟
                      _buildGuideCard(
                        dark: dark,
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        mutedColor: mutedColor,
                        icon: '✨',
                        title: isAr ? 'ما هو التهجد؟' : 'What is Tahajjud?',
                        body: isAr
                            ? 'التهجد نوع من قيام الليل، ويُقصد به تحديداً أن ينام المسلم ثم يستيقظ ليصلي.\n\n'
                              'فإذا صلى الشخص بعد العشاء مباشرة وقبل النوم فهذا قيام ليل، أما إذا نام ثم استيقظ وصلى فهذا تهجد وهو في الوقت نفسه قيام ليل.\n\n'
                              '📌 إذن: كل تهجد هو قيام ليل، وليس كل قيام ليل تهجدًا.'
                            : 'Tahajjud is praying at night after having slept. If you sleep then wake up to pray, it is Tahajjud and Qiyam. Every Tahajjud is Qiyam, but not every Qiyam is Tahajjud.',
                      ),
                      const SizedBox(height: 12),

                      // Section 5: ما هو الوتر؟
                      _buildGuideCard(
                        dark: dark,
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        mutedColor: mutedColor,
                        icon: '🤲',
                        title: isAr ? 'ما هو الوتر؟' : 'What is Witr?',
                        body: isAr
                            ? 'الوتر صلاة تُختم بها صلاة الليل، ويمتد وقتها من بعد صلاة العشاء وحتى أذان الفجر.\n\n'
                              'ويمكن أداؤه: ركعة واحدة، أو ٣ ركعات، أو أكثر بشرط أن يكون العدد وتراً (فردياً).\n'
                              'إذا خشي المسلم ألا يستيقظ آخر الليل يوتر قبل النوم، وإذا غلب على ظنه الاستيقاظ فالأفضل تأخيره لآخر الليل.'
                            : 'Witr concludes night prayer, performed as 1, 3, or more odd Rak\'ahs. Pray before sleeping if unsure of waking up, or in the last third if waking up is likely.',
                      ),
                      const SizedBox(height: 12),

                      // Section 6: كيف نحسب الثلث الأخير من الليل؟
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: gold.withValues(alpha: dark ? 0.12 : 0.07),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: gold.withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('⏳', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Text(
                                  isAr ? 'كيف نحسب الثلث الأخير من الليل؟' : 'Calculating the Last Third',
                                  style: TextStyle(
                                    fontFamily: DhikrTheme.arabicFont,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isAr
                                  ? 'يُحسب بحساب المدة بين غروب الشمس (المغرب) وأذان الفجر، ثم تقسيم هذه المدة على ٣ أجزاء، ويكون الجزء الأخير هو الثلث الأخير.\n\n'
                                    '📊 مثال توضيحي:\n'
                                    '• وقت المغرب: 6:00 م\n'
                                    '• وقت الفجر: 5:00 ص\n'
                                    '• مدة الليل = 11 ساعة\n'
                                    '• ثلث الليل = 3 ساعات و 40 دقيقة تقريباً\n'
                                    '• بداية الثلث الأخير: 1:20 ص وحتى أذان الفجر.\n\n'
                                    'تختلف هذه الأوقات من مدينة لأخرى بحسب موعدي المغرب والفجر.'
                                  : 'Measure duration between Sunset (Maghrib) and Fajr, divide by 3. The final third is the last third of the night.',
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                height: 1.6,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Section 7: هل الثلث الأخير هو نفسه قيام الليل؟
                      _buildGuideCard(
                        dark: dark,
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        mutedColor: mutedColor,
                        icon: '⚖️',
                        title: isAr ? 'هل الثلث الأخير هو نفسه قيام الليل؟' : 'Qiyam vs Last Third',
                        body: isAr
                            ? 'لا، فهناك فرق دقيق:\n'
                              '• قيام الليل: عبادة ممتدة من بعد العشاء حتى أذان الفجر.\n'
                              '• الثلث الأخير: جزء من وقت الليل، وهو أفضل أوقات النزول الإلهي واستجابة الدعاء.\n'
                              '• التهجد: قيام الليل بعد النوم.\n'
                              '• الوتر: صلاة تُختم بها صلاة الليل.\n\n'
                              'فإذا صلى ركعتين بعد العشاء ثم أوتر فقد صلى قيام الليل، وإذا نام واستيقظ وصلى فقد أدى التهجد وهو أيضاً قيام ليل.'
                            : 'Qiyam spans the whole night from Isha to Fajr. The last third is the most virtuous portion of that time.',
                      ),
                      const SizedBox(height: 12),

                      // Section 8: طريقة بسيطة للمبتدئ
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: emerald.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('🎯', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Text(
                                  isAr ? 'طريقة بسيطة للمبتدئ' : 'Simple Beginner Plan',
                                  style: TextStyle(
                                    fontFamily: DhikrTheme.arabicFont,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    color: emerald,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isAr
                                  ? '١. المحافظة على الصلوات المفروضة في أوقاتها أولاً.\n'
                                    '٢. أداء ركعتي سنة الفجر (خير من الدنيا وما فيها).\n'
                                    '٣. المحافظة على السنن الرواتب حسب الاستطاعة.\n'
                                    '٤. صلاة ركعتين من قيام الليل بعد العشاء.\n'
                                    '٥. ختم صلاة الليل بركعة وتر.\n'
                                    '٦. إذا استيقظ في الثلث الأخير يصلي ما تيسر له، ولا يعيد الوتر إذا كان قد صلاه قبل النوم.\n\n'
                                    '✨ والأفضل أن يبدأ المسلم بالقليل الذي يستطيع المواظبة عليه، ثم يزيد تدريجيًا دون مشقة: «أَحَبُّ الْأَعْمَالِ إِلَى اللَّهِ أَدْوَمُهَا وَإِنْ قَلَّ».'
                                  : '1. Guard obligatory prayers.\n2. Pray 2 Fajr Sunnah.\n3. Keep Sunan Rawatib.\n4. Pray 2 Qiyam after Isha.\n5. Seal with 1 Witr.\nStart small and remain consistent.',
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                height: 1.6,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGuideCard({
    required bool dark,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color mutedColor,
    required String icon,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              height: 1.6,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableCell(String text, Color color, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: DhikrTheme.arabicFont,
          fontWeight: isHeader ? FontWeight.w800 : FontWeight.w600,
          fontSize: isHeader ? 12.5 : 12,
          color: color,
        ),
      ),
    );
  }
}
