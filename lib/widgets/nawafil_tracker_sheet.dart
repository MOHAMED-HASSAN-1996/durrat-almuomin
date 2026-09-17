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
                  // Settings
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: goldAccent.withValues(alpha: dark ? 0.18 : 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.settings, size: 18, color: goldAccent),
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
}
