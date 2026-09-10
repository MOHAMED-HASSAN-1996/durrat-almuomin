import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/soul_remedies_data.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';

/// الشاشة الأولى: استعراض بطاقات صيدلية الروح وبوصلة المشاعر
class SoulRemedyScreen extends StatelessWidget {
  const SoulRemedyScreen({super.key, this.initialFeelingId});

  final String? initialFeelingId;

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().language;
    final isAr = lang == AppLanguage.arabic;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: AppBar(
              title: Text(
                isAr ? 'صيدلية الروح ودواء القلوب' : 'Soul Sanctuary',
                style: const TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontWeight: FontWeight.w700,
                ),
              ),
              centerTitle: true,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 96),
              children: [
                // بطاقة المقدمة التوجيهية
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: dark
                          ? [const Color(0xFF152620), const Color(0xFF0F1A16)]
                          : [const Color(0xFFF0FDF4), const Color(0xFFE6F5EF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.22),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F766E).withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F766E).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.spa_rounded,
                            size: 28,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr ? 'بماذا يشعر قلبك اليوم؟' : 'How does your heart feel today?',
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: dark ? Colors.white : const Color(0xFF134E4A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isAr
                                  ? 'اختر الحالة التي تَمُرّ بها لتجد البلسم القرآني والسكينة النبوية'
                                  : 'Select your state to find Quranic remedies & prophetic peace',
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: 12.5,
                                color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // شبكة كروت الحالات (كرتان في الصف الواحد - الأيقونة والشعور فقط)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: soulRemediesList.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.12,
                  ),
                  itemBuilder: (context, index) {
                    final remedy = soulRemediesList[index];
                    return _buildCompactRemedyTile(context, remedy, isAr, dark);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactRemedyTile(
    BuildContext context,
    SoulRemedy remedy,
    bool isAr,
    bool dark,
  ) {
    final feelingName = isAr ? remedy.feelingAr : remedy.feelingEn;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SoulRemedyDetailScreen(remedy: remedy),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: dark
                  ? [const Color(0xFF1E2824), const Color(0xFF16201C)]
                  : [Colors.white, const Color(0xFFF7FAF8)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: (dark ? DhikrColors.sage : DhikrColors.forest).withValues(alpha: 0.18),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (dark ? Colors.black : DhikrColors.forest).withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: dark
                        ? [
                            remedy.accentColor.withValues(alpha: 0.30),
                            remedy.accentColor.withValues(alpha: 0.10),
                          ]
                        : [
                            remedy.accentColor.withValues(alpha: 0.18),
                            remedy.accentColor.withValues(alpha: 0.06),
                          ],
                  ),
                  border: Border.all(
                    color: remedy.accentColor.withValues(alpha: dark ? 0.35 : 0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: remedy.accentColor.withValues(alpha: dark ? 0.22 : 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    remedy.iconData,
                    size: 23,
                    color: dark ? Color.lerp(Colors.white, remedy.accentColor, 0.45) : remedy.accentColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  feelingName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    height: 1.25,
                    color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// الشاشة الثانية: صفحة تفاصيل الكارت المختار
class SoulRemedyDetailScreen extends StatefulWidget {
  const SoulRemedyDetailScreen({super.key, required this.remedy});

  final SoulRemedy remedy;

  @override
  State<SoulRemedyDetailScreen> createState() => _SoulRemedyDetailScreenState();
}

class _SoulRemedyDetailScreenState extends State<SoulRemedyDetailScreen> {
  final Map<String, int> _duaCounts = {};

  void _incrementDua(String duaKey, int target) {
    HapticFeedback.lightImpact();
    setState(() {
      final current = _duaCounts[duaKey] ?? 0;
      final next = current >= target ? target : current + 1;
      _duaCounts[duaKey] = next;

      if (next == target) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'أتممت الذكر.. تقبل الله وطمأن قلبك 🤍',
                    style: TextStyle(fontFamily: DhikrTheme.arabicFont),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0F766E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _shareRemedy(bool isAr) {
    HapticFeedback.selectionClick();
    final r = widget.remedy;

    final buffer = StringBuffer();
    buffer.writeln(isAr
        ? '«صيدلية الروح: دواء القلب حين تشعر بـ ${r.feelingAr}» 🌿'
        : '«Soul Sanctuary: Heart Solace for ${r.feelingEn}» 🌿');
    buffer.writeln();

    buffer.writeln(isAr ? '📖 الآيات القرآنية الشافية:' : '📖 Quranic Solace:');
    for (final a in r.ayahs) {
      buffer.writeln('${a.ayah} (${a.surah})');
    }
    buffer.writeln();

    buffer.writeln(isAr ? '🤲 الأدعية النبوية المأثورة:' : '🤲 Prophetic Duas:');
    for (final d in r.duas) {
      buffer.writeln('«${d.dua}»');
      buffer.writeln('[${d.source}]');
    }
    buffer.writeln();

    buffer.writeln(isAr ? '🕊️ همسات لراحة قلبك:' : '🕊️ Heart Solace:');
    for (final p in (isAr ? r.solacePointsAr : r.solacePointsEn)) {
      buffer.writeln('• $p');
    }
    buffer.writeln();
    buffer.writeln('— من تطبيق ذكر (DHIKR)');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr ? 'تم نسخ بطاقة العلاج للمشاركة بنجاح ✓' : 'Remedy card copied to share ✓',
          style: const TextStyle(fontFamily: DhikrTheme.arabicFont),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().language;
    final isAr = lang == AppLanguage.arabic;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final r = widget.remedy;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: AppBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: r.accentColor.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(r.iconData, size: 17, color: r.accentColor),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      isAr ? 'حين تشعر بـ ${r.feelingAr}' : 'When you feel ${r.feelingEn}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  tooltip: isAr ? 'مشاركة الوصفة' : 'Share Remedy',
                  icon: const Icon(Icons.share_rounded),
                  onPressed: () => _shareRemedy(isAr),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 96),
              children: [
                // 1. قسم الآيات القرآنية
                _buildSectionHeader(
                  title: isAr ? 'الآيات القرآنية الشافية' : 'Quranic Solace',
                  icon: Icons.menu_book_rounded,
                  color: const Color(0xFF0F766E),
                  dark: dark,
                ),
                const SizedBox(height: 10),
                ...r.ayahs.map((ayahItem) => _buildAyahCard(ayahItem, isAr, dark)),
                const SizedBox(height: 20),

                // 2. قسم الأدعية النبوية مع العداد
                _buildSectionHeader(
                  title: isAr ? 'الأدعية النبوية المأثورة' : 'Prophetic Supplications',
                  icon: Icons.volunteer_activism_rounded,
                  color: const Color(0xFFD97706),
                  dark: dark,
                ),
                const SizedBox(height: 10),
                ...r.duas.map((duaItem) => _buildDuaCard(duaItem, isAr, dark)),
                const SizedBox(height: 20),

                // 3. قسم الوصايا والبلسم القلبي
                _buildSectionHeader(
                  title: isAr ? 'همسات وبلسم لراحة قلبك' : 'Heart Solace & Reminders',
                  icon: Icons.spa_rounded,
                  color: const Color(0xFF4F46E5),
                  dark: dark,
                ),
                const SizedBox(height: 10),
                _buildSolaceCard(r, isAr, dark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
    required bool dark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
          ),
        ),
      ],
    );
  }

  Widget _buildAyahCard(QuranAyahItem item, bool isAr, bool dark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (dark ? const Color(0xFF18231F) : const Color(0xFFF9FCFA)),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF0F766E).withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.surah,
                    softWrap: true,
                    style: const TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                color: dark ? DhikrColors.sage : DhikrColors.forest,
                tooltip: isAr ? 'نسخ الآية' : 'Copy Ayah',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Clipboard.setData(ClipboardData(text: '${item.ayah} [${item.surah}]'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isAr ? 'تم نسخ الآية ✓' : 'Ayah copied ✓',
                          style: const TextStyle(fontFamily: DhikrTheme.arabicFont)),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.ayah,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontSize: 18,
              height: 1.8,
              fontWeight: FontWeight.w700,
              color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
            ),
          ),
          if (item.translation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.translation,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 12.5,
                color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDuaCard(PropheticDuaItem item, bool isAr, bool dark) {
    final count = _duaCounts[item.dua] ?? 0;
    final isDone = count >= item.targetRepeat;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (dark ? const Color(0xFF221F18) : const Color(0xFFFFFDF8)),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDone
              ? const Color(0xFF0F766E)
              : const Color(0xFFD97706).withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.source,
                    softWrap: true,
                    style: const TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                color: dark ? DhikrColors.sage : DhikrColors.forest,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Clipboard.setData(ClipboardData(text: '«${item.dua}» [${item.source}]'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isAr ? 'تم نسخ الدعاء ✓' : 'Dua copied ✓',
                          style: const TextStyle(fontFamily: DhikrTheme.arabicFont)),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '«${item.dua}»',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontSize: 17,
              height: 1.75,
              fontWeight: FontWeight.w700,
              color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
            ),
          ),
          if (item.note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.note,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 12,
                color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
              ),
            ),
          ],
          const SizedBox(height: 12),
          // زر العداد التفاعلي للدعاء
          Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _incrementDua(item.dua, item.targetRepeat),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDone
                        ? const Color(0xFF0F766E)
                        : (dark ? const Color(0xFF352A18) : const Color(0xFFFEF3C7)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDone
                          ? const Color(0xFF0F766E)
                          : const Color(0xFFD97706).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDone ? Icons.check_circle_rounded : Icons.touch_app_rounded,
                        size: 18,
                        color: isDone ? Colors.white : const Color(0xFFB45309),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isDone
                            ? (isAr ? 'تم الذكر ($count/${item.targetRepeat})' : 'Completed')
                            : (isAr
                                ? 'التكرار: $count من ${item.targetRepeat}'
                                : 'Repeat: $count / ${item.targetRepeat}'),
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: isDone ? Colors.white : const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolaceCard(SoulRemedy remedy, bool isAr, bool dark) {
    final points = isAr ? remedy.solacePointsAr : remedy.solacePointsEn;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (dark ? const Color(0xFF1E212E) : const Color(0xFFF7F8FE)),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF4F46E5).withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: points.map((p) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•', style: TextStyle(fontSize: 18, color: Color(0xFF4F46E5))),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    p,
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontSize: 13.5,
                      height: 1.6,
                      color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
