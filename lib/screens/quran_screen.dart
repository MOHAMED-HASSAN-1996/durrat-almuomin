import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/quran_surahs.dart';
import '../services/quran_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';
import 'quran_mushaf_screen.dart';

/// The full Quran Surahs directory (114 Surahs) with search,
/// Meccan/Medinan filters, and last read resume banner.
class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  String _searchQuery = '';
  int _filterIndex = 0; // 0 = الكل, 1 = مكية, 2 = مدنية
  Map<String, dynamic>? _lastRead;

  @override
  void initState() {
    super.initState();
    _loadLastRead();
  }

  Future<void> _loadLastRead() async {
    final lr = await QuranService.instance.getLastRead();
    if (mounted) {
      setState(() => _lastRead = lr);
    }
  }

  String _toArabicNum(int n) {
    const arDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => arDigits[int.parse(c)]).join();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().language;
    final isAr = lang == AppLanguage.arabic;
    final dark = Theme.of(context).brightness == Brightness.dark;

    final filteredSurahs = quranSurahs.where((s) {
      // Type filter
      if (_filterIndex == 1 && !s.isMeccan) return false;
      if (_filterIndex == 2 && s.isMeccan) return false;

      // Search filter
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();
      final numMatch = s.number.toString() == q;
      final nameMatch = s.name.toLowerCase().contains(q) ||
          s.englishName.toLowerCase().contains(q) ||
          s.englishTranslation.toLowerCase().contains(q);
      return numMatch || nameMatch;
    }).toList();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: AppBar(
              title: Text(isAr ? 'القرآن الكريم' : 'The Holy Quran'),
              centerTitle: true,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                // Top Header / Search / Filters
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    children: [
                      // Search field
                      TextField(
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: isAr
                              ? 'ابحث باسم السورة أو رقمها...'
                              : 'Search by surah name or number...',
                          hintStyle: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontSize: 14,
                            color: dark
                                ? DhikrColors.darkMuted
                                : DhikrColors.charcoalSoft,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: dark
                                ? DhikrColors.darkMuted
                                : DhikrColors.charcoalSoft,
                          ),
                          filled: true,
                          fillColor: dark
                              ? DhikrColors.darkSurface
                              : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: dark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : DhikrColors.charcoal.withValues(alpha: 0.06),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: dark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : DhikrColors.charcoal.withValues(alpha: 0.06),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Filter chips: الكل / مكية / مدنية
                      Row(
                        children: [
                          _buildFilterChip('الكل (114)', 0, dark),
                          const SizedBox(width: 8),
                          _buildFilterChip('مكية (86)', 1, dark),
                          const SizedBox(width: 8),
                          _buildFilterChip('مدنية (28)', 2, dark),
                        ],
                      ),
                    ],
                  ),
                ),

                // Last Read Banner (if exists and no search query)
                if (_lastRead != null && _searchQuery.isEmpty && _filterIndex == 0) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: _buildLastReadCard(context, dark, isAr),
                  ),
                ],

                // Surahs List
                Expanded(
                  child: filteredSurahs.isEmpty
                      ? Center(
                          child: Text(
                            isAr ? 'لم يتم العثور على سور' : 'No Surahs found',
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              color: dark
                                  ? DhikrColors.darkMuted
                                  : DhikrColors.charcoalSoft,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                          itemCount: filteredSurahs.length,
                          itemBuilder: (context, index) {
                            final surah = filteredSurahs[index];
                            return _buildSurahTile(context, surah, dark, isAr);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int index, bool dark) {
    final selected = _filterIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _filterIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? (dark ? DhikrColors.sage : DhikrColors.forest)
              : (dark ? DhikrColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : (dark
                    ? Colors.white.withValues(alpha: 0.08)
                    : DhikrColors.charcoal.withValues(alpha: 0.08)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected
                ? (dark ? DhikrColors.darkBg : Colors.white)
                : (dark ? DhikrColors.darkText : DhikrColors.charcoal),
          ),
        ),
      ),
    );
  }

  Widget _buildLastReadCard(BuildContext context, bool dark, bool isAr) {
    final surahNum = _lastRead!['surahNumber'] as int? ?? 1;
    final surahName = _lastRead!['surahName'] as String? ?? '';
    final meta = quranSurahs.firstWhere(
      (s) => s.number == surahNum,
      orElse: () => quranSurahs.first,
    );

    final page = _lastRead!['page'] as int? ?? meta.page;

    return Material(
      color: (dark ? DhikrColors.sage : DhikrColors.forest).withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: (dark ? DhikrColors.sage : DhikrColors.forest).withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => QuranMushafScreen(initialPage: page),
            ),
          ).then((_) => _loadLastRead());
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: dark ? DhikrColors.sage : DhikrColors.forest,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bookmark_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'متابعة القراءة' : 'Continue Reading',
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: dark ? DhikrColors.sage : DhikrColors.forest,
                      ),
                    ),
                    Text(
                      'سُورَةُ $surahName • صفحة ${_toArabicNum(page)}',
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: dark ? DhikrColors.sage : DhikrColors.forest,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurahTile(
      BuildContext context, QuranSurahMeta surah, bool dark, bool isAr) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: dark ? DhikrColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: dark
              ? Colors.white.withValues(alpha: 0.08)
              : DhikrColors.charcoal.withValues(alpha: 0.06),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => QuranMushafScreen(initialPage: surah.page),
            ),
          ).then((_) => _loadLastRead());
        },
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: (dark ? DhikrColors.sage : DhikrColors.forest)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: (dark ? DhikrColors.sage : DhikrColors.forest)
                  .withValues(alpha: 0.25),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            _toArabicNum(surah.number),
            style: TextStyle(
              fontFamily: DhikrTheme.arabicFont,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: dark ? DhikrColors.sage : DhikrColors.forest,
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              'سُورَةُ ${surah.name}',
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: surah.isMeccan
                    ? const Color(0xFFD4AF37).withValues(alpha: 0.12)
                    : (dark ? DhikrColors.sage : DhikrColors.forest)
                        .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                surah.typeAr,
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: surah.isMeccan
                      ? const Color(0xFFB8860B)
                      : (dark ? DhikrColors.sage : DhikrColors.forest),
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(
                '${surah.englishName} • ${_toArabicNum(surah.numberOfAyahs)} آية',
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontSize: 11.5,
                  color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                ),
              ),
              const Spacer(),
              Text(
                'ص ${_toArabicNum(surah.page)}',
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
