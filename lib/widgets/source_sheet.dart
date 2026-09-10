import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';

/// Shows the source/reference of a Dhikr in a bottom sheet.
class SourceSheet {
  SourceSheet._();

  static void show(BuildContext context, Dhikr dhikr, AppLanguage language) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final virtue = language == AppLanguage.arabic ? dhikr.virtue : dhikr.virtueEn ?? dhikr.virtue;
    showModalBottomSheet(
      context: context,
      backgroundColor: dark ? DhikrColors.darkSurface : DhikrColors.ivory,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: dark
                          ? DhikrColors.darkMuted
                          : DhikrColors.charcoalSoft,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (virtue != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (dark ? DhikrColors.sage : DhikrColors.forest)
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (dark ? DhikrColors.sage : DhikrColors.forest)
                            .withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.star_rounded,
                                size: 16,
                                color: dark
                                    ? DhikrColors.sage
                                    : DhikrColors.forest),
                            const SizedBox(width: 6),
                            Text(
                              AppStrings.t(language, 'virtue'),
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: dark
                                    ? DhikrColors.sage
                                    : DhikrColors.forest,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          virtue,
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            height: 1.6,
                            color: dark
                                ? DhikrColors.darkText
                                : DhikrColors.charcoal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  AppStrings.t(language, 'content_note'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 13,
                    height: 1.5,
                    color: dark
                        ? DhikrColors.darkMuted
                        : DhikrColors.charcoalSoft,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}