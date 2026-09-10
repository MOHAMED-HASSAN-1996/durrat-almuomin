import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';

/// Modern floating pill bottom navigation — DGA clean outline icon system.
/// 5 tabs: Home · Tasbih · Radio · Prayer · Settings
class BottomNav extends StatelessWidget {
  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.language,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final labels = [
      AppStrings.t(language, 'home'),
      AppStrings.t(language, 'tasbih'),
      AppStrings.t(language, 'radio_nav'),
      AppStrings.t(language, 'prayer'),
      AppStrings.t(language, 'settings'),
    ];
    final icons = [
      LucideIcons.house,
      LucideIcons.disc,
      LucideIcons.radio,
      LucideIcons.clock,
      LucideIcons.settings,
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: dark
                    ? DhikrColors.darkSurface.withValues(alpha: 0.86)
                    : Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: dark
                      ? Colors.white.withValues(alpha: 0.08)
                      : DhikrColors.charcoal.withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? 0.35 : 0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: List.generate(5, (i) {
                  final selected = i == currentIndex;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onTap(i);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? (dark
                                  ? const Color(0xFF15382E)
                                  : const Color(0xFFE8F2ED))
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? (dark
                                    ? const Color(0xFF2D6E5A)
                                    : const Color(0xFFB5D4C7))
                                : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              icons[i],
                              size: selected ? 21 : 19,
                              color: selected
                                  ? (dark ? const Color(0xFFA5E6C7) : DhikrColors.forest)
                                  : (dark
                                      ? Colors.white.withValues(alpha: 0.45)
                                      : DhikrColors.charcoalSoft),
                            ),
                            const SizedBox(height: 3),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 180),
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: selected ? 11.5 : 10.5,
                                fontWeight:
                                    selected ? FontWeight.w800 : FontWeight.w600,
                                color: selected
                                    ? (dark ? const Color(0xFFA5E6C7) : DhikrColors.forest)
                                    : (dark
                                        ? Colors.white.withValues(alpha: 0.45)
                                        : DhikrColors.charcoalSoft),
                                height: 1.15,
                              ),
                              child: Text(
                                labels[i],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
