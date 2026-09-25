import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../types/adhkar.dart';

/// Home screen category card (Morning / Evening / Ruqyah / etc.) with DGA Minimalist styling.
class DhikrCategoryCard extends StatelessWidget {
  const DhikrCategoryCard({
    super.key,
    required this.category,
    required this.progress,
    required this.language,
    required this.onTap,
    this.compact = false,
  });

  final DhikrCategory category;
  final ({int completed, int total}) progress;
  final AppLanguage language;
  final VoidCallback onTap;

  /// Compact half-width variant used to show categories side by side.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isAr = language == AppLanguage.arabic;
    final percent = progress.total == 0
        ? 0
        : (progress.completed * 100 / progress.total).round();
    final remaining = progress.total - progress.completed;
    final isCompleted = progress.total > 0 && progress.completed >= progress.total;

    final (title, subtitle, icon) = switch (category) {
      DhikrCategory.morning => (
          AppStrings.t(language, 'morning'),
          isAr ? '٢١ ذكراً مباركاً' : '21 Morning Adhkar',
          LucideIcons.sunrise,
        ),
      DhikrCategory.evening => (
          AppStrings.t(language, 'evening'),
          isAr ? '١٨ ذكراً مباركاً' : '18 Evening Adhkar',
          LucideIcons.sunset,
        ),
      DhikrCategory.ruqyah => (
          AppStrings.t(language, 'ruqyah'),
          isAr ? 'تحصين وشفاء' : 'Protection & Healing',
          LucideIcons.shieldCheck,
        ),
      DhikrCategory.sleep => (
          AppStrings.t(language, 'sleep'),
          isAr ? '١٠ أذكار مباركة' : '10 Sleep Adhkar',
          LucideIcons.moonStar,
        ),
      DhikrCategory.waking => (
          AppStrings.t(language, 'waking'),
          isAr ? '٤ أذكار مباركة' : '4 Waking Adhkar',
          LucideIcons.sunMedium,
        ),
      DhikrCategory.afterPrayer => (
          AppStrings.t(language, 'afterPrayer'),
          isAr ? '٨ أذكار مأثورة' : '8 Post-Prayer Adhkar',
          LucideIcons.sparkles,
        ),
      DhikrCategory.tasbeeh => (
          AppStrings.t(language, 'tasbeeh_dhikr'),
          isAr ? '٩ تسابيح وأدعية' : '9 Praise & Tasbeeh',
          LucideIcons.circleDot,
        ),
    };

    final actionLabel = isCompleted
        ? (isAr ? 'تمت' : 'Done')
        : (progress.completed > 0
            ? AppStrings.t(language, 'continue')
            : AppStrings.t(language, 'start'));

    final (cardAccent, pastelStart, pastelEnd, imageAsset) = switch (category) {
      DhikrCategory.morning => (
          dark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
          const Color(0xFFFFFBEB),
          const Color(0xFFFDE68A),
          'assets/images/clay_3d_morning.webp',
        ),
      DhikrCategory.evening => (
          dark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED),
          const Color(0xFFF5F3FF),
          const Color(0xFFDDD6FE),
          'assets/images/clay_3d_evening.webp',
        ),
      DhikrCategory.afterPrayer => (
          dark ? const Color(0xFF34D399) : const Color(0xFF059669),
          const Color(0xFFECFDF5),
          const Color(0xFFA7F3D0),
          'assets/images/clay_3d_after_prayer.webp',
        ),
      DhikrCategory.ruqyah => (
          dark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
          const Color(0xFFF0F9FF),
          const Color(0xFFBAE6FD),
          'assets/images/clay_3d_ruqyah.webp',
        ),
      DhikrCategory.sleep => (
          dark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
          const Color(0xFFF8FAFC),
          const Color(0xFFCBD5E1),
          null,
        ),
      DhikrCategory.waking => (
          dark ? const Color(0xFFFB923C) : const Color(0xFFEA580C),
          const Color(0xFFFFF7ED),
          const Color(0xFFFED7AA),
          null,
        ),
      DhikrCategory.tasbeeh => (
          dark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488),
          const Color(0xFFF0FDFA),
          const Color(0xFF99F6E4),
          'assets/images/clay_3d_after_prayer.webp',
        ),
    };

    final primaryAccent = cardAccent;

    if (compact) {
      return _buildCompact(
        context: context,
        title: title,
        subtitle: subtitle,
        imageAsset: imageAsset,
        icon: icon,
        primaryAccent: primaryAccent,
        pastelStart: pastelStart,
        pastelEnd: pastelEnd,
        dark: dark,
        isAr: isAr,
        actionLabel: actionLabel,
        percent: percent,
        isCompleted: isCompleted,
      );
    }

    return _buildFull(
      context: context,
      title: title,
      subtitle: subtitle,
      imageAsset: imageAsset,
      icon: icon,
      primaryAccent: primaryAccent,
      pastelStart: pastelStart,
      pastelEnd: pastelEnd,
      dark: dark,
      isAr: isAr,
      actionLabel: actionLabel,
      percent: percent,
      remaining: remaining,
      isCompleted: isCompleted,
    );
  }

  /// Compact DGA-styled card (Half-width for 2x2 grid)
  Widget _buildCompact({
    required BuildContext context,
    required String title,
    required String subtitle,
    String? imageAsset,
    required IconData icon,
    required Color primaryAccent,
    required Color pastelStart,
    required Color pastelEnd,
    required bool dark,
    required bool isAr,
    required String actionLabel,
    required int percent,
    required bool isCompleted,
  }) {
    final calc = progress.total == 0
        ? 0.0
        : (progress.completed / progress.total).clamp(0.0, 1.0);

    return Semantics(
      button: true,
      label: '$title — $percent%',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: primaryAccent.withValues(alpha: 0.10),
          highlightColor: primaryAccent.withValues(alpha: 0.04),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: dark ? DhikrColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: dark
                    ? Colors.white.withValues(alpha: 0.08)
                    : DhikrColors.charcoal.withValues(alpha: 0.08),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.25 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: DGA Icon Badge + Status Pill
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (imageAsset != null)
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: Image.asset(
                          imageAsset,
                          width: 48,
                          height: 48,
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, stack) => Icon(icon, size: 22, color: primaryAccent),
                        ),
                      )
                    else
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: dark
                                ? [
                                    primaryAccent.withValues(alpha: 0.35),
                                    primaryAccent.withValues(alpha: 0.14),
                                  ]
                                : [pastelStart, pastelEnd],
                          ),
                          border: Border.all(
                            color: dark ? Colors.white.withValues(alpha: 0.22) : Colors.white,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.95),
                              blurRadius: 4,
                              offset: const Offset(-2, -2),
                            ),
                            BoxShadow(
                              color: primaryAccent.withValues(alpha: dark ? 0.35 : 0.28),
                              blurRadius: 10,
                              offset: const Offset(3, 4),
                            ),
                            BoxShadow(
                              color: primaryAccent.withValues(alpha: dark ? 0.15 : 0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: dark ? 0.07 : 0.45),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: dark ? 0.12 : 0.60),
                                width: 1.0,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                icon,
                                size: 20,
                                color: dark ? Colors.white : primaryAccent,
                                shadows: [
                                  Shadow(
                                    color: primaryAccent.withValues(alpha: dark ? 0.60 : 0.38),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? primaryAccent.withValues(alpha: dark ? 0.25 : 0.12)
                            : (dark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F2)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isCompleted ? (isAr ? 'مكتمل ✓' : 'Done ✓') : '$percent%',
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isCompleted
                              ? primaryAccent
                              : (dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Title
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    height: 1.25,
                    color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                  ),
                ),
                const SizedBox(height: 3),

                // Subtitle / Counter
                Row(
                  children: [
                    Text(
                      '${progress.completed}/${progress.total}',
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: primaryAccent,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '•',
                      style: TextStyle(
                        fontSize: 10,
                        color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Sleek Clean Progress Bar
                Container(
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: primaryAccent.withValues(alpha: dark ? 0.12 : 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                            width: constraints.maxWidth * calc,
                            decoration: BoxDecoration(
                              color: primaryAccent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      );
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

  /// Full-width DGA-styled variant
  Widget _buildFull({
    required BuildContext context,
    required String title,
    required String subtitle,
    String? imageAsset,
    required IconData icon,
    required Color primaryAccent,
    required Color pastelStart,
    required Color pastelEnd,
    required bool dark,
    required bool isAr,
    required String actionLabel,
    required int percent,
    required int remaining,
    required bool isCompleted,
  }) {
    final calc = progress.total == 0
        ? 0.0
        : (progress.completed / progress.total).clamp(0.0, 1.0);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        splashColor: primaryAccent.withValues(alpha: 0.10),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: dark ? DhikrColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: dark
                  ? Colors.white.withValues(alpha: 0.08)
                  : DhikrColors.charcoal.withValues(alpha: 0.08),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.25 : 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (imageAsset != null)
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: Image.asset(
                        imageAsset,
                        width: 52,
                        height: 52,
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, err, stack) => Icon(icon, size: 24, color: primaryAccent),
                      ),
                    )
                  else
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: dark
                              ? [
                                  primaryAccent.withValues(alpha: 0.35),
                                  primaryAccent.withValues(alpha: 0.14),
                                ]
                              : [pastelStart, pastelEnd],
                        ),
                        border: Border.all(
                          color: dark ? Colors.white.withValues(alpha: 0.22) : Colors.white,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: dark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.95),
                            blurRadius: 4,
                            offset: const Offset(-2, -2),
                          ),
                          BoxShadow(
                            color: primaryAccent.withValues(alpha: dark ? 0.35 : 0.28),
                            blurRadius: 10,
                            offset: const Offset(3, 4),
                          ),
                          BoxShadow(
                            color: primaryAccent.withValues(alpha: dark ? 0.15 : 0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: dark ? 0.07 : 0.45),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: dark ? 0.12 : 0.60),
                              width: 1.0,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              icon,
                              size: 22,
                              color: dark ? Colors.white : primaryAccent,
                              shadows: [
                                Shadow(
                                  color: primaryAccent.withValues(alpha: dark ? 0.60 : 0.38),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontSize: 12.5,
                            color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? primaryAccent.withValues(alpha: dark ? 0.25 : 0.12)
                          : (dark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F2)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isCompleted ? (isAr ? 'مكتمل' : 'Done') : '$percent%',
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isCompleted
                            ? primaryAccent
                            : (dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: primaryAccent.withValues(alpha: dark ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          width: constraints.maxWidth * calc,
                          decoration: BoxDecoration(
                            color: primaryAccent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}