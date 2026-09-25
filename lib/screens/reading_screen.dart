import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../services/arabic_text_utils.dart';
import '../services/audio.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';
import '../widgets/completion_screen.dart';
import '../widgets/dhikr_counter.dart';
import '../widgets/progress_bar.dart';
import '../widgets/source_sheet.dart';
import '../widgets/app_toast.dart';

/// The reading screen. Shows ONE Dhikr at a time with a large counter,
/// audio button, source link, and progress. Advancing is always explicit
/// (the "Next" action after a Dhikr completes) — never forced navigation.
///
/// Interaction model (reachable without scrolling):
///  * Tapping anywhere on the dhikr card counts a repetition.
///  * The counter stays pinned at the bottom and never scrolls away.
class ReadingScreen extends StatefulWidget {
  const ReadingScreen({
    super.key,
    required this.category,
    required this.language,
  });

  final DhikrCategory category;
  final AppLanguage language;

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  late final DhikrAudio _audio = DhikrAudio();
  late int _index = 0;
  int? _lastCompletedIndex;

  List<Dhikr> get _adhkar =>
      context.read<AppState>().adhkarFor(widget.category);

  int get _total => _adhkar.length;

  int get _safeIndex => _index.clamp(0, _total - 1);

  bool get _isSimplifiedCategory =>
      widget.category == DhikrCategory.morning ||
      widget.category == DhikrCategory.evening ||
      widget.category == DhikrCategory.afterPrayer ||
      widget.category == DhikrCategory.ruqyah;

  static String _removeTashkeel(String input) {
    return ArabicTextUtils.stripTashkeel(input);
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index >= _total) return;
    _audio.stop();
    setState(() {
      _index = index;
      _lastCompletedIndex = null;
    });
  }

  Future<void> _handleCounterTap() async {    final state = context.read<AppState>();
    final dhikr = _adhkar[_safeIndex];
    final current = state.countFor(widget.category, dhikr.id);
    if (current >= dhikr.repeat) {
      // Already complete — advancing happens only via Next.
      return;
    }
    // اهتزاز فوري مع كل ضغطة على الدائرة
    HapticFeedback.mediumImpact();
    final next = state.increment(widget.category, dhikr.id);
    if (next >= dhikr.repeat) {
      setState(() {
        _lastCompletedIndex = _safeIndex;
      });
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> _next() async {
    HapticFeedback.selectionClick();
    if (_safeIndex < _total - 1) {
      _goTo(_safeIndex + 1);
    } else {
      // Finished the category — commit history and show completion.
      final state = context.read<AppState>();
      await state.commitHistory();
      if (!mounted) return;
      _showCompletion();
    }
  }

  /// السابق: يرجع الضغطة (ينقص العداد درجة)، وعند الصفر ينتقل للكارت السابق.
  void _previous() {
    final state = context.read<AppState>();
    final dhikr = _adhkar[_safeIndex];
    final current = state.countFor(widget.category, dhikr.id);
    HapticFeedback.lightImpact();
    if (current > 0) {
      state.decrement(widget.category, dhikr.id);
      if (_lastCompletedIndex == _safeIndex) {
        setState(() => _lastCompletedIndex = null);
      }
      return;
    }
    if (_safeIndex <= 0) return;
    _goTo(_safeIndex - 1);
  }

  /// صف التنقل: RTL → التالي يمين بسهمه ورجوع يسار | LTR → السابق يسار والتالي يمين
  Widget _buildNavRow({
    required AppLanguage lang,
    required bool isDone,
    required bool canPrevious,
    required bool dark,
  }) {
    final isAr = lang == AppLanguage.arabic;

    final prevBtn = Expanded(
      child: OutlinedButton(
        onPressed: canPrevious ? _previous : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: dark ? DhikrColors.sage : DhikrColors.forest,
          side: BorderSide(
            color: (dark ? DhikrColors.sage : DhikrColors.forest)
                .withValues(alpha: 0.4),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: isAr
              ? [
                  Text(AppStrings.t(lang, 'previous')),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ]
              : [
                  Icon(Icons.arrow_back_rounded, size: 20),
                  const SizedBox(width: 6),
                  Text(AppStrings.t(lang, 'previous')),
                ],
        ),
      ),
    );

    final nextBtn = Expanded(
      child: FilledButton(
        onPressed: isDone ? _next : null,
        style: FilledButton.styleFrom(
          backgroundColor: isDone
              ? (dark ? DhikrColors.sage : DhikrColors.forest)
              : (dark ? DhikrColors.darkSurface : DhikrColors.sand),
          foregroundColor: isDone
              ? Colors.white
              : (dark ? DhikrColors.darkMuted : DhikrColors.sandDeep),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: isAr
              ? [
                  Icon(Icons.arrow_back_rounded, size: 20),
                  const SizedBox(width: 6),
                  Text(AppStrings.t(lang, 'next')),
                ]
              : [
                  Text(AppStrings.t(lang, 'next')),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
        ),
      ),
    );

    return Row(
      children: [
        if (isAr) nextBtn else prevBtn,
        const SizedBox(width: 12),
        if (isAr) prevBtn else nextBtn,
      ],
    );
  }

  void _showCompletion() {
    final lang = context.read<AppState>().language;
    final (title, emoji) = switch (widget.category) {
      DhikrCategory.morning =>
        (AppStrings.t(lang, 'morning_complete'), '🌿'),
      DhikrCategory.evening =>
        (AppStrings.t(lang, 'evening_complete'), '🌙'),
      DhikrCategory.ruqyah =>
        (AppStrings.t(lang, 'ruqyah_complete'), '🛡️'),
      DhikrCategory.sleep =>
        (AppStrings.t(lang, 'sleep_complete'), '🌙'),
      DhikrCategory.waking =>
        (AppStrings.t(lang, 'waking_complete'), '☀️'),
      DhikrCategory.afterPrayer =>
        (AppStrings.t(lang, 'afterPrayer_complete'), '🕌'),
      DhikrCategory.tasbeeh =>
        (AppStrings.t(lang, 'tasbeeh_dhikr_complete'), '📿'),
    };
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, anim, sec) {
          return CompletionScreen(
            emoji: emoji,
            title: title,
            subtitle: AppStrings.t(lang, 'mayAllahAccept'),
            backLabel: AppStrings.t(lang, 'home'),
            onBackHome: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          );
        },
        transitionsBuilder: (context, anim, sec, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  Future<void> _toggleAudio(Dhikr dhikr) async {
    if (_isSimplifiedCategory) return;
    final lang = context.read<AppState>().language;
    final key = dhikr.audioKey;
    if (key == null) return;
    if (_audio.isPlaying && _audio.currentSource == key) {
      await _audio.pause();
      if (mounted) setState(() {});
      return;
    }
    if (!_audio.isPlaying && _audio.currentSource == key) {
      await _audio.resume();
      if (mounted) setState(() {});
      return;
    }
    final ok = dhikr.hasQuranAudio
        ? await _audio.playStream(dhikr.quranAudio!, sourceKey: key)
        : false;
    if (!mounted) return;
    if (ok) {
      setState(() {});
    } else {
      AppToast.show(context, 
        SnackBar(content: Text(AppStrings.t(lang, 'audio_unavailable'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_adhkar.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('-')),
      );
    }

    final state = context.watch<AppState>();
    final lang = state.language;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final dhikr = _adhkar[_safeIndex];
    final progress = state.categoryProgress(widget.category);
    final remaining = progress.total - progress.completed;
    final percent = state.categoryPercentInt(widget.category);
    final currentCount = state.countFor(widget.category, dhikr.id);
    final isDone =
        _lastCompletedIndex == _safeIndex || currentCount >= dhikr.repeat;
    final categoryTitle = switch (widget.category) {
      DhikrCategory.morning => AppStrings.t(lang, 'morning'),
      DhikrCategory.evening => AppStrings.t(lang, 'evening'),
      DhikrCategory.ruqyah => AppStrings.t(lang, 'ruqyah'),
      DhikrCategory.sleep => AppStrings.t(lang, 'sleep'),
      DhikrCategory.waking => AppStrings.t(lang, 'waking'),
      DhikrCategory.afterPrayer => AppStrings.t(lang, 'afterPrayer'),
      DhikrCategory.tasbeeh => AppStrings.t(lang, 'tasbeeh_dhikr'),
    };
    final rawArabic = dhikr.arabic;
    final displayArabic = _isSimplifiedCategory ? _removeTashkeel(rawArabic) : rawArabic;
    final mutedColor = dark ? DhikrColors.darkMuted : DhikrColors.forestLight;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: AppStrings.t(lang, 'back'),
          onPressed: () {
            _audio.stop();
            Navigator.of(context).maybePop();
          },
        ),
        title: Text(categoryTitle),
        actions: [
          if (widget.category == DhikrCategory.afterPrayer)
            IconButton(
              icon: const Icon(Icons.restart_alt_rounded),
              tooltip: lang == AppLanguage.arabic
                  ? 'إعادة البدء للصلاة التالية'
                  : 'Restart for next prayer',
              onPressed: () async {
                HapticFeedback.mediumImpact();
                await state.resetCategory(widget.category);
                setState(() {
                  _index = 0;
                  _lastCompletedIndex = null;
                });
                if (context.mounted) {
                  AppToast.show(context, 
                    SnackBar(
                      content: Text(
                        lang == AppLanguage.arabic
                            ? 'تمت إعادة تعيين الأذكار للصلاة التالية ✓'
                            : 'Reset for next prayer ✓',
                        style: const TextStyle(fontFamily: DhikrTheme.arabicFont),
                      ),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                '${progress.completed} / ${progress.total}',
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: mutedColor,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            '$remaining ${AppStrings.t(lang, 'adhkar_remaining')}',
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: mutedColor,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '$percent%',
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ProgressBar(
                        fraction: progress.total == 0
                            ? 0
                            : progress.completed / progress.total,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, zone) {
                      // مساحة الدائرة: 150px + تنفس 40px (20 فوق و20 تحت).
                      final double rawZone = zone.maxHeight - 190;
                      final double textMax = rawZone < 60 ? 60 : rawZone;
                      return Column(
                        children: [
                          Container(
                            constraints: BoxConstraints(maxHeight: textMax),
                            child: GestureDetector(
                              onTap: _handleCounterTap,
                              behavior: HitTestBehavior.opaque,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Column(
                        children: [
                          const SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: dark
                                  ? DhikrColors.darkSurface
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: dark
                                    ? Colors.white10
                                    : DhikrColors.sageSoft.withValues(alpha: 0.6),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: dark ? 0.2 : 0.04,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: lang == AppLanguage.arabic
                                  ? Text(
                                      displayArabic,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: DhikrTheme.arabicFont,
                                        fontWeight: FontWeight.w700,
                                        fontSize: _isSimplifiedCategory
                                            ? (displayArabic.length > 350
                                                ? 16.0
                                                : (displayArabic.length > 200
                                                    ? 17.5
                                                    : (displayArabic.length > 100
                                                        ? 19.0
                                                        : 20.5)))
                                            : (rawArabic.length > 350
                                                ? 22.0
                                                : (rawArabic.length > 200
                                                    ? 23.5
                                                    : (rawArabic.length > 100
                                                        ? 25.0
                                                        : 26.5))),
                                        height: _isSimplifiedCategory ? 1.75 : 1.85,
                                        letterSpacing: 0.2,
                                        color: dark
                                            ? DhikrColors.darkText
                                            : DhikrColors.charcoal,
                                      ),
                                    )
                                  : Text(
                                      dhikr.english,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: DhikrTheme.arabicFont,
                                        fontSize: dhikr.english.length > 300
                                            ? 16.5
                                            : 18.0,
                                        height: 1.65,
                                        letterSpacing: 0.1,
                                        color: dark
                                            ? DhikrColors.darkMuted
                                            : DhikrColors.charcoalSoft,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Source + Virtue + Listen in same row
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              if ((dhikr.virtue != null &&
                                      dhikr.virtue!.isNotEmpty) ||
                                  (dhikr.virtueEn != null &&
                                      dhikr.virtueEn!.isNotEmpty))
                                _SourceChip(
                                  onTap: () =>
                                      SourceSheet.show(context, dhikr, lang),
                                  label: AppStrings.t(lang, 'virtue_label'),
                                  icon: Icons.star_rounded,
                                ),
                              if (!_isSimplifiedCategory &&
                                  state.audioEnabled &&
                                  dhikr.audioKey != null)
                                _SourceChip(
                                  onTap: () => _toggleAudio(dhikr),
                                  label: (_audio.isPlaying &&
                                          _audio.currentSource == dhikr.audioKey)
                                      ? AppStrings.t(lang, 'pause')
                                      : AppStrings.t(lang, 'listen'),
                                  icon: (_audio.isPlaying &&
                                          _audio.currentSource == dhikr.audioKey)
                                      ? Icons.pause_rounded
                                      : Icons.headphones_rounded,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                            ),
                          // ── دائرة العدّاد: في منتصف الفراغ بين النص والأزرار ──
                          Expanded(
                            child: Center(
                              child: DhikrCounter(
                                size: 150,
                                current: currentCount,
                                target: dhikr.repeat,
                                onTap: _handleCounterTap,
                                languageLabel:
                                    _counterA11yLabel(dhikr, currentCount, lang),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        key: const ValueKey('next-cta'),
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isDone) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_rounded,
                                    color: dark
                                        ? DhikrColors.sage
                                        : DhikrColors.success,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    AppStrings.t(lang, 'dhikrDone'),
                                    style: TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: dark
                                          ? DhikrColors.sage
                                          : DhikrColors.success,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                            ],
                            _buildNavRow(
                              lang: lang,
                              isDone: isDone,
                              canPrevious: currentCount > 0 || _safeIndex > 0,
                              dark: dark,
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
        ),
      ),
    );
  }

  String _counterA11yLabel(Dhikr dhikr, int current, AppLanguage lang) {
    if (lang == AppLanguage.arabic) {
      return 'التكرار ${_toArabicDigits(current)} من ${_toArabicDigits(dhikr.repeat)}';
    }
    return 'Repetition $current of ${dhikr.repeat}';
  }

  String _toArabicDigits(int n) {
    const map = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((d) => map[int.parse(d)]).join();
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip(
      {required this.label, this.icon = Icons.menu_book_outlined, this.onTap});

  final VoidCallback? onTap;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final muted = dark ? DhikrColors.darkMuted : DhikrColors.forestLight;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (dark ? DhikrColors.sage : DhikrColors.forest)
                .withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: muted),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}