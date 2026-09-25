import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../services/prayer_alert_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';
import '../widgets/app_toast.dart';

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

  /// اهتزاز النقر مفعّل دائماً — الاهتزاز جزء من إحساس السبحة نفسها.
  bool get _vibrate => true;
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

  /// نبضة النقرة: انفجار قوي مُحسوس عبر الطبقة الأصلية عند الإمكان،
  /// وإلا نرجع لهزة فلاتر القوية + الاهتزاز النظامي حتى ما تفقد النقرة إحساسها.
  Future<void> _tapHaptic() async {
    if (!_vibrate) return;
    HapticFeedback.heavyImpact();
    final handled = await PlatformPermissions.tapVibration();
    if (!handled) {
      HapticFeedback.vibrate();
    }
  }

  void _increment() {
    setState(() {
      _count++;
      _total++;
      if (_target > 0 && _count >= _target) {
        _tapHaptic();
        // auto reset cycle but keep total
        _count = 0;
        AppToast.show(context, 
          SnackBar(
            content: Text(AppStrings.t(
                context.read<AppState>().language, 'completed')),
            duration: const Duration(milliseconds: 900),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _tapHaptic();
      }
    });
  }

  void _undo() {
    if (_count > 0) {
      setState(() {
        _count--;
        if (_total > 0) _total--;
      });
      _tapHaptic();
    }
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
                  AppToast.show(context, 
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
                backgroundColor: dark ? DhikrColors.sage : const Color(0xFF1E3A2F),
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
    final totalTarget = _target == 0 ? '∞' : '$_target';
    final screenBg = dark ? DhikrColors.darkBg : const Color(0xFFFAF7F2);

    return Scaffold(
      backgroundColor: screenBg,
      appBar: AppBar(
        title: Text(
          AppStrings.t(lang, 'tasbih_title'),
          style: TextStyle(
            fontFamily: DhikrTheme.arabicFont,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: dark ? DhikrColors.darkText : const Color(0xFF1D2721),
          ),
        ),
        centerTitle: true,
        backgroundColor: screenBg,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                const SizedBox(height: 8),

                // Phrase selector with + button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Dropdown Menu Container (Start in RTL -> visually on right)
                      Expanded(
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: dark
                                ? DhikrColors.darkSurface
                                : const Color(0xFFE8EDE5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: dark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : const Color(0xFFD5DFD3),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _phraseIndex,
                              isExpanded: true,
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: dark
                                    ? DhikrColors.sage
                                    : const Color(0xFF1E3A2F),
                                size: 28,
                              ),
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: dark
                                    ? DhikrColors.darkText
                                    : const Color(0xFF1D2721),
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
                      const SizedBox(width: 12),

                      // '+' Button (End in RTL -> visually on left)
                      Material(
                        color: dark
                            ? DhikrColors.sage
                            : const Color(0xFF1E3A2F),
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
                              size: 28,
                              color: dark ? DhikrColors.darkBg : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Target selector Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: dark ? DhikrColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: dark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFE8ECE6),
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.flag_rounded,
                              size: 16,
                              color: dark
                                  ? DhikrColors.sage
                                  : const Color(0xFF1E3A2F),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              AppStrings.t(lang, 'target'),
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: dark
                                    ? DhikrColors.darkText
                                    : const Color(0xFF1D2721),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [33, 66, 99, 100, 0].map((t) {
                            final isSelected = _target == t;
                            final label = t == 0 ? '∞' : '$t';
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                child: Material(
                                  color: isSelected
                                      ? (dark
                                          ? DhikrColors.sage
                                          : const Color(0xFF1E3A2F))
                                      : (dark
                                          ? Colors.white.withValues(alpha: 0.06)
                                          : const Color(0xFFEEF1EC)),
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _target = t);
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      height: 40,
                                      alignment: Alignment.center,
                                      child: Text(
                                        label,
                                        style: TextStyle(
                                          fontFamily: DhikrTheme.arabicFont,
                                          fontSize: t == 0 ? 20 : 15,
                                          fontWeight: isSelected
                                              ? FontWeight.w800
                                              : FontWeight.w700,
                                          color: isSelected
                                              ? (dark
                                                  ? DhikrColors.darkBg
                                                  : Colors.white)
                                              : (dark
                                                  ? DhikrColors.darkText
                                                  : const Color(0xFF1D2721)),
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
                const SizedBox(height: 12),

                const SizedBox.shrink(),

                // Center area with circular counter
                Expanded(
                  child: GestureDetector(
                    onTap: _increment,
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 260,
                            height: 260,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: dark
                                  ? DhikrColors.darkSurface
                                  : const Color(0xFFFAF8F5),
                              border: Border.all(
                                color: dark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : const Color(0xFFD5DFD3),
                                width: 3.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                      alpha: dark ? 0.3 : 0.05),
                                  blurRadius: 22,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    phrase,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 21,
                                      color: dark
                                          ? DhikrColors.darkText
                                          : const Color(0xFF1D2721),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$_count',
                                    style: TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 66,
                                      height: 1.05,
                                      color: dark
                                          ? DhikrColors.darkText
                                          : const Color(0xFF1D2721),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '/ $totalTarget',
                                    style: TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: dark
                                          ? DhikrColors.sage
                                          : const Color(0xFF386452),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppStrings.t(lang, 'tap_anywhere'),
                                    style: TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: dark
                                          ? DhikrColors.darkMuted
                                          : const Color(0xFF4A7360),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom Controls: "إعادة ↻" and "رجوع ↩"
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(
                    children: [
                      // Right button in RTL: "إعادة ↻"
                      Expanded(
                        child: Material(
                          color: dark
                              ? DhikrColors.sage
                              : const Color(0xFF1E3A2F),
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            onTap: _reset,
                            onLongPress: () {
                              _resetAll();
                              AppToast.show(context, 
                                SnackBar(
                                  content: Text(
                                    isAr ? 'تم تصفير العداد الإجمالي' : 'Total count reset',
                                    style: const TextStyle(fontFamily: DhikrTheme.arabicFont),
                                  ),
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              height: 52,
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    AppStrings.t(lang, 'reset'),
                                    style: TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: dark
                                          ? DhikrColors.darkBg
                                          : Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.refresh_rounded,
                                    size: 20,
                                    color: dark
                                        ? DhikrColors.darkBg
                                        : Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Left button in RTL: "رجوع ↩"
                      Expanded(
                        child: Material(
                          color: dark ? DhikrColors.darkSurface : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(
                              color: dark
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : const Color(0xFFD2DDD0),
                              width: 1.5,
                            ),
                          ),
                          child: InkWell(
                            onTap: _undo,
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              height: 52,
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    AppStrings.t(lang, 'undo'),
                                    style: TextStyle(
                                      fontFamily: DhikrTheme.arabicFont,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: dark
                                          ? DhikrColors.darkMuted
                                          : const Color(0xFF6B8074),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Transform.flip(
                                    flipX: true,
                                    child: Icon(
                                      Icons.undo_rounded,
                                      size: 20,
                                      color: dark
                                          ? DhikrColors.darkMuted
                                          : const Color(0xFF6B8074),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
