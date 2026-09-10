import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../types/adhkar.dart';

/// First-launch language picker — chic, full-screen, no scaffold chrome.
/// Shown before the main app when hasChosenLanguage is false.
class LanguagePickerScreen extends StatelessWidget {
  const LanguagePickerScreen({super.key, required this.onPicked});

  final ValueChanged<AppLanguage> onPicked;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                children: [
                  const Spacer(),
                  Text(
                    'ذكر',
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontWeight: FontWeight.w800,
                      fontSize: 56,
                      height: 1.1,
                      color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'DHIKR',
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 6,
                      color: dark ? DhikrColors.darkMuted : DhikrColors.forestLight,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (dark ? DhikrColors.sage : DhikrColors.forest)
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      'اختر لغة الواجهة • Choose your interface language',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 13,
                        height: 1.6,
                        color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _LangCard(
                    arabic: true,
                    selected: false,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onPicked(AppLanguage.arabic);
                    },
                  ),
                  const SizedBox(height: 14),
                  _LangCard(
                    arabic: false,
                    selected: false,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onPicked(AppLanguage.english);
                    },
                  ),
                  const Spacer(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LangCard extends StatelessWidget {
  const _LangCard({required this.arabic, required this.selected, required this.onTap});
  final bool arabic;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: dark ? DhikrColors.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: dark
                  ? Colors.white.withValues(alpha: 0.08)
                  : DhikrColors.charcoal.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (dark ? DhikrColors.sage : DhikrColors.forest)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(arabic ? 'ع' : 'En',
                    style: TextStyle(
                      fontFamily: DhikrTheme.arabicFont,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: dark ? DhikrColors.sage : DhikrColors.forest,
                    )),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      arabic ? 'العربية' : 'English',
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      arabic ? 'واجهة عربية كاملة' : 'Full English interface',
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 12,
                        color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded,
                  size: 18,
                  color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft),
            ],
          ),
        ),
      ),
    );
  }
}
