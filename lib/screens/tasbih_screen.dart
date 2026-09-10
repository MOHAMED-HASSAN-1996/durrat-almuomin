import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';

/// Electronic Tasbih — independent from morning/evening progress.
/// Persistent, haptic, custom dhikr support, and fully offline.
class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  int _count = 0;
  int _total = 0;
  int _target = 33;
  final bool _vibrate = true;
  int _phraseIndex = 0;

  final List<String> _customPhrasesAr = [];
  final List<String> _customPhrasesEn = [];

  static const _basePhrasesAr = [
    'سبحان الله',
    'الحمد لله',
    'الله أكبر',
    'لا إله إلا الله',
    'أستغفر الله',
    'لا حول ولا قوة إلا بالله',
  ];
  static const _basePhrasesEn = [
    'SubhanAllah',
    'Alhamdulillah',
    'Allahu Akbar',
    'La ilaha illa Allah',
    'Astaghfirullah',
    'La hawla wa la quwwata illa billah',
  ];

  List<String> get _allPhrasesAr => [..._basePhrasesAr, ..._customPhrasesAr];
  List<String> get _allPhrasesEn => [..._basePhrasesEn, ..._customPhrasesEn];

  void _increment() {
    setState(() {
      _count++;
      _total++;
      if (_target > 0 && _count >= _target) {
        HapticFeedback.heavyImpact();
        if (_vibrate) {
          HapticFeedback.vibrate();
        }
        // auto reset cycle but keep total
        _count = 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.t(
                context.read<AppState>().language, 'completed')),
            duration: const Duration(milliseconds: 900),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        HapticFeedback.selectionClick();
        if (_vibrate) {
          HapticFeedback.vibrate();
        }
      }
    });
  }

  void _reset() {
    setState(() {
      _count = 0;
    });
    HapticFeedback.mediumImpact();
  }

  void _resetAll() {
    setState(() {
      _count = 0;
      _total = 0;
    });
    HapticFeedback.mediumImpact();
  }

  void _showAddDhikrSheet(BuildContext context, AppLanguage lang, bool dark) {
    final isAr = lang == AppLanguage.arabic;
    final textCtrl = TextEditingController();

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
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: (dark ? DhikrColors.sage : DhikrColors.forest)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.add_circle_outline_rounded,
                    color: dark ? DhikrColors.sage : DhikrColors.forest,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isAr ? 'إضافة ذكر جديد' : 'Add Custom Dhikr',
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textCtrl,
              autofocus: true,
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontWeight: FontWeight.w600,
                color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
              ),
              decoration: InputDecoration(
                hintText: isAr
                    ? 'مثال: سبحان الله وبحمده، الصلاة على النبي...'
                    : 'e.g. SubhanAllahi wa bihamdih...',
                hintStyle: TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontSize: 13,
                  color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                ),
                filled: true,
                fillColor: (dark ? Colors.white : DhikrColors.forest)
                    .withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: dark
                        ? Colors.white.withValues(alpha: 0.1)
                        : DhikrColors.charcoal.withValues(alpha: 0.08),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: dark
                        ? Colors.white.withValues(alpha: 0.1)
                        : DhikrColors.charcoal.withValues(alpha: 0.08),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: dark ? DhikrColors.sage : DhikrColors.forest,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                final text = textCtrl.text.trim();
                if (text.isNotEmpty) {
                  setState(() {
                    _customPhrasesAr.add(text);
                    _customPhrasesEn.add(text);
                    _phraseIndex = _allPhrasesAr.length - 1;
                    _count = 0;
                  });
                  HapticFeedback.mediumImpact();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isAr ? 'تمت إضافة الذكر بنجاح ✨' : 'Dhikr added successfully ✨',
                        style: const TextStyle(fontFamily: DhikrTheme.arabicFont),
                      ),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: Text(
                isAr ? 'حفظ الذكر والبدء' : 'Save & Start',
                style: const TextStyle(
                  fontFamily: DhikrTheme.arabicFont,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: dark ? DhikrColors.sage : DhikrColors.forest,
                foregroundColor: dark ? DhikrColors.darkBg : Colors.white,
                minimumSize: const Size.fromHeight(54),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().language;
    final isAr = lang == AppLanguage.arabic;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final currentPhrases = isAr ? _allPhrasesAr : _allPhrasesEn;
    if (_phraseIndex >= currentPhrases.length) {
      _phraseIndex = 0;
    }
    final phrase = currentPhrases[_phraseIndex];
    final muted = dark ? DhikrColors.darkMuted : DhikrColors.forestLight;
    final totalTarget = _target == 0 ? '∞' : '$_target';

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: AppBar(
              title: Text(AppStrings.t(lang, 'tasbih_title')),
              centerTitle: true,
              actions: [
                IconButton(
                  tooltip: AppStrings.t(lang, 'reset'),
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _resetAll,
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
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                const SizedBox(height: 12),

                // Phrase selector with + button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Dropdown Menu Container
                      Expanded(
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: (dark ? DhikrColors.sage : DhikrColors.forest)
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: (dark ? DhikrColors.sage : DhikrColors.forest)
                                  .withValues(alpha: 0.15),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _phraseIndex,
                              isExpanded: true,
                              icon: Icon(Icons.expand_more_rounded, color: muted),
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                              ),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() {
                                    _phraseIndex = v;
                                    _count = 0;
                                  });
                                }
                              },
                              items: List.generate(currentPhrases.length, (i) {
                                return DropdownMenuItem(
                                  value: i,
                                  child: Text(
                                    currentPhrases[i],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Small '+' Button to Add Custom Dhikr
                      Material(
                        color: dark ? DhikrColors.sage : DhikrColors.forest,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: () => _showAddDhikrSheet(context, lang, dark),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 52,
                            height: 52,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.add_rounded,
                              size: 26,
                              color: dark ? DhikrColors.darkBg : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Target selector — evenly distributed cards spanning full width
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: dark ? DhikrColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: dark
                            ? Colors.white.withValues(alpha: 0.08)
                            : DhikrColors.charcoal.withValues(alpha: 0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: dark ? 0.2 : 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.flag_rounded,
                              size: 15,
                              color: dark ? DhikrColors.sage : DhikrColors.forest,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              AppStrings.t(lang, 'target'),
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [33, 66, 99, 100, 0].map((t) {
                            final isSelected = _target == t;
                            final label = t == 0 ? '∞' : '$t';
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                child: Material(
                                  color: isSelected
                                      ? (dark ? DhikrColors.sage : DhikrColors.forest)
                                      : (dark
                                          ? Colors.white.withValues(alpha: 0.08)
                                          : (dark ? DhikrColors.sage : DhikrColors.forest)
                                              .withValues(alpha: 0.08)),
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _target = t);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      height: 38,
                                      alignment: Alignment.center,
                                      child: Text(
                                        label,
                                        style: TextStyle(
                                          fontFamily: DhikrTheme.arabicFont,
                                          fontSize: t == 0 ? 18 : 14,
                                          fontWeight: isSelected
                                              ? FontWeight.w800
                                              : FontWeight.w700,
                                          color: isSelected
                                              ? (dark ? DhikrColors.darkBg : Colors.white)
                                              : (dark
                                                  ? DhikrColors.darkText
                                                  : DhikrColors.charcoal),
                                          height: 1.1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                Text(
                  '${AppStrings.t(lang, 'total_count')}: $_total',
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 13,
                    color: muted,
                    height: 1.2,
                  ),
                ),

                Expanded(
                  child: GestureDetector(
                    onTap: _increment,
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Main counter circle
                          GestureDetector(
                            onTap: _increment,
                            child: Container(
                              width: 240,
                              height: 240,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: dark
                                    ? DhikrColors.darkSurface
                                    : DhikrColors.cream,
                                border: Border.all(
                                  color: (dark
                                          ? DhikrColors.sage
                                          : DhikrColors.forest)
                                      .withValues(alpha: 0.18),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: dark ? 0.25 : 0.07),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Progress ring
                                  SizedBox(
                                    width: 240,
                                    height: 240,
                                    child: CircularProgressIndicator(
                                      value: _target == 0
                                          ? 0
                                          : (_count / _target).clamp(0, 1),
                                      strokeWidth: 7,
                                      strokeCap: StrokeCap.round,
                                      backgroundColor: (dark
                                              ? DhikrColors.sage
                                              : DhikrColors.forest)
                                          .withValues(alpha: 0.12),
                                      valueColor: AlwaysStoppedAnimation(
                                        dark
                                            ? DhikrColors.sage
                                            : DhikrColors.forest,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          phrase,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: DhikrTheme.arabicFont,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 17,
                                            color: dark
                                                ? DhikrColors.darkText
                                                : DhikrColors.charcoal,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '$_count',
                                          style: TextStyle(
                                            fontFamily: DhikrTheme.arabicFont,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 54,
                                            height: 1.1,
                                            color: dark
                                                ? DhikrColors.darkText
                                                : DhikrColors.charcoal,
                                          ),
                                        ),
                                        Text(
                                          '/ $totalTarget',
                                          style: TextStyle(
                                            fontFamily: DhikrTheme.arabicFont,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: muted,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          AppStrings.t(lang, 'tap_anywhere'),
                                          style: TextStyle(
                                            fontFamily: DhikrTheme.arabicFont,
                                            fontSize: 11,
                                            color: muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppStrings.t(lang, 'count'),
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontSize: 12,
                              color: muted,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Controls — Reset
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Center(
                    child: FilledButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: Text(AppStrings.t(lang, 'reset')),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            dark ? DhikrColors.sage : DhikrColors.forest,
                        foregroundColor: dark ? DhikrColors.darkBg : Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
