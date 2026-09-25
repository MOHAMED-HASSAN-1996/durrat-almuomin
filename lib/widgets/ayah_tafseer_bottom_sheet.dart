import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../data/quran_surahs.dart';
import '../services/tafseer_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';
import 'app_toast.dart';

class AyahTafseerBottomSheet extends StatefulWidget {
  final int surahNumber;
  final int verseNumber;
  final String? ayahText;

  const AyahTafseerBottomSheet({
    super.key,
    required this.surahNumber,
    required this.verseNumber,
    this.ayahText,
  });

  static Future<void> show(
    BuildContext context, {
    required int surahNumber,
    required int verseNumber,
    String? ayahText,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AyahTafseerBottomSheet(
        surahNumber: surahNumber,
        verseNumber: verseNumber,
        ayahText: ayahText,
      ),
    );
  }

  @override
  State<AyahTafseerBottomSheet> createState() => _AyahTafseerBottomSheetState();
}

class _AyahTafseerBottomSheetState extends State<AyahTafseerBottomSheet> {
  // 0 = التفسير الميسر, 1 = معاني الكلمات
  int _selectedTabIndex = 0;
  bool _isLoading = true;
  AyahTafseerResult? _result;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final res = await TafseerService.instance.getAyahTafseerAndWords(
      surah: widget.surahNumber,
      ayah: widget.verseNumber,
      fallbackAyahText: widget.ayahText,
    );
    if (mounted) {
      setState(() {
        _result = res;
        _isLoading = false;
      });
    }
  }

  String _toArabicNum(int n) {
    const arDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => arDigits[int.parse(c)]).join();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isAr = context.watch<AppState>().language == AppLanguage.arabic;
    final surahMeta = quranSurahs.firstWhere(
      (s) => s.number == widget.surahNumber,
      orElse: () => quranSurahs.first,
    );

    final bgCol = dark ? const Color(0xFF13221B) : Colors.white;
    final cardCol = dark ? const Color(0xFF1B2E25) : const Color(0xFFF7F6F2);
    final borderCol = dark ? Colors.white12 : const Color(0xFFE5E7EB);
    final accentCol = const Color(0xFFC5A059);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.78,
        decoration: BoxDecoration(
          color: bgCol,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 25,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Drag Handle ──
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: dark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ── Header: Surah, Ayah Number & Copy ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentCol.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accentCol.withValues(alpha: 0.35), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.bookOpen, size: 16, color: Color(0xFFC5A059)),
                        const SizedBox(width: 6),
                        Text(
                          'سورة ${surahMeta.name} • آية ${_toArabicNum(widget.verseNumber)}',
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontWeight: FontWeight.w900,
                            fontSize: 13.5,
                            color: dark ? const Color(0xFFA7F3D0) : const Color(0xFF0F766E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(LucideIcons.copy, size: 18),
                    tooltip: 'نسخ الآية والتفسير',
                    color: dark ? Colors.white70 : Colors.black87,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      if (_result != null) {
                        Clipboard.setData(
                          ClipboardData(
                            text:
                                '«${_result!.ayahText}» [سورة ${surahMeta.name}: ${widget.verseNumber}]\n\nالتفسير:\n${_result!.tafseerText}',
                          ),
                        );
                        AppToast.show(context, 
                          const SnackBar(
                            content: Text(
                              'تم نسخ الآية وتفسيرها بنجاح ✓',
                              style: TextStyle(fontFamily: DhikrTheme.arabicFont),
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    color: dark ? Colors.white60 : Colors.black54,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // ── Top Switch Button / Segmented Control ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF0B1712) : const Color(0xFFF1F0EC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderCol, width: 0.9),
                ),
                child: Row(
                  children: [
                    // Tab 0: التفسير الميسر
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedTabIndex = 0);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 0
                                ? (dark ? const Color(0xFF1E3A2E) : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _selectedTabIndex == 0
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.fileText,
                                size: 16,
                                color: _selectedTabIndex == 0
                                    ? const Color(0xFFC5A059)
                                    : (dark ? Colors.white54 : Colors.black45),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'تفسير الآية (الميسر)',
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 13,
                                  fontWeight: _selectedTabIndex == 0 ? FontWeight.w900 : FontWeight.w600,
                                  color: _selectedTabIndex == 0
                                      ? (dark ? Colors.white : const Color(0xFF0F766E))
                                      : (dark ? Colors.white54 : Colors.black54),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Tab 1: معاني الكلمات
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedTabIndex = 1);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _selectedTabIndex == 1
                                ? (dark ? const Color(0xFF1E3A2E) : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _selectedTabIndex == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.languages,
                                size: 16,
                                color: _selectedTabIndex == 1
                                    ? const Color(0xFFC5A059)
                                    : (dark ? Colors.white54 : Colors.black45),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'معاني الكلمات وغريبها',
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 13,
                                  fontWeight: _selectedTabIndex == 1 ? FontWeight.w900 : FontWeight.w600,
                                  color: _selectedTabIndex == 1
                                      ? (dark ? Colors.white : const Color(0xFF0F766E))
                                      : (dark ? Colors.white54 : Colors.black54),
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
            ),

            const SizedBox(height: 12),

            // ── Body Content ──
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFFC5A059)),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                      children: [
                        // 1. صندوق نص الآية الكريمة
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: cardCol,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: accentCol.withValues(alpha: 0.25),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _result?.ayahText.isNotEmpty == true
                                    ? _result!.ayahText
                                    : TafseerService.cleanQuranText(widget.ayahText ?? ''),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: DhikrTheme.arabicFont,
                                  fontSize: 20,
                                  height: 1.9,
                                  fontWeight: FontWeight.w700,
                                  color: dark ? Colors.white : const Color(0xFF163E32),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Center(
                                child: Text(
                                  '﴿ ${widget.verseNumber} ﴾',
                                  style: const TextStyle(
                                    fontFamily: DhikrTheme.arabicFont,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFC5A059),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // 2. المحتوى بناءً على الـ Switch المختار
                        if (_selectedTabIndex == 0)
                          // عرض التفسير الميسر
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: dark ? const Color(0xFF0F1A14) : const Color(0xFFFAFAF8),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderCol, width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(LucideIcons.sparkles, size: 16, color: Color(0xFFC5A059)),
                                    const SizedBox(width: 6),
                                    Text(
                                      _result?.tafseerSource ?? 'التفسير الميسر',
                                      style: TextStyle(
                                        fontFamily: DhikrTheme.arabicFont,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: dark ? const Color(0xFFA7F3D0) : const Color(0xFF0F766E),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _result?.tafseerText ?? '',
                                  style: TextStyle(
                                    fontFamily: DhikrTheme.arabicFont,
                                    fontSize: 15.5,
                                    height: 1.85,
                                    color: dark ? const Color(0xFFE2E8F0) : const Color(0xFF27272A),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          // عرض معاني الكلمات
                          if (_result?.wordMeanings.isEmpty ?? true)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: dark ? const Color(0xFF0F1A14) : const Color(0xFFFAFAF8),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  'جميع ألفاظ الآية الكريمة واضحة ومبينة في التفسير الميسر',
                                  style: TextStyle(
                                    fontFamily: DhikrTheme.arabicFont,
                                    fontSize: 13.5,
                                    color: dark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _result!.wordMeanings.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 8),
                              itemBuilder: (ctx, i) {
                                final w = _result!.wordMeanings[i];
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: dark ? const Color(0xFF0F1A14) : const Color(0xFFFAFAF8),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: borderCol, width: 0.9),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: accentCol.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          w.word,
                                          style: const TextStyle(
                                            fontFamily: DhikrTheme.arabicFont,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 15,
                                            color: Color(0xFFC5A059),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          w.meaning,
                                          style: TextStyle(
                                            fontFamily: DhikrTheme.arabicFont,
                                            fontSize: 13.5,
                                            color: dark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
