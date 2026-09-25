import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_theme.dart';

/// One card inside a home-screen section.
///
/// Every section on the home screen renders these, so a card can never end up
/// with a different width, height, gutter or type scale than its neighbours —
/// the inconsistency that made the old mixed grid look ragged.
class HomeCardSpec {
  const HomeCardSpec({
    required this.title,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.imageAsset,
    this.pastelStart,
    this.pastelEnd,
    this.badgeText,
    this.progress,
    this.remoteKey,
  });

  /// Optional RemoteContentService homeCards key (e.g. 'shaarawi').
  /// When set, the admin dashboard can show/hide this card remotely.
  /// Null means always visible.
  final String? remoteKey;

  /// Label under the artwork. Wraps to two lines before it is ellipsised.
  final String title;

  /// Fallback glyph when [imageAsset] is missing or fails to load.
  final IconData icon;

  /// Accent used for the clay badge, badge text and progress line.
  final Color accent;

  final VoidCallback onTap;

  final String? imageAsset;

  /// Pastel gradient behind the fallback glyph (light mode).
  final Color? pastelStart;
  final Color? pastelEnd;

  /// Optional short corner badge such as `42%` or `✓`.
  final String? badgeText;

  /// Optional 0..1 progress line pinned to the bottom of the card.
  final double? progress;
}

/// A uniform grid of [HomeCardSpec] cards.
///
/// [columns] fixes the cell width. A partially filled last row is padded with
/// empty slots so the cards that do exist keep exactly the same width instead
/// of stretching across the leftover space — the «wrong gaps» the previous
/// rows of bare `Expanded` widgets produced.
class HomeCardGrid extends StatelessWidget {
  const HomeCardGrid({
    super.key,
    required this.cards,
    required this.dark,
    this.columns = 3,
    this.gutter = 8,
    this.cellHeight = 134,
    this.imageSize = 58,
  });

  final List<HomeCardSpec> cards;
  final bool dark;
  final int columns;

  /// Space between cells, used for both the horizontal and vertical gaps so
  /// the grid reads as one evenly spaced block.
  final double gutter;

  final double cellHeight;
  final double imageSize;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();

    final rows = <Widget>[];
    for (var start = 0; start < cards.length; start += columns) {
      final rowCards = cards.sublist(
        start,
        (start + columns).clamp(0, cards.length),
      );
      final cells = <Widget>[];
      for (var column = 0; column < columns; column++) {
        if (column > 0) cells.add(SizedBox(width: gutter));
        cells.add(
          Expanded(
            child: column < rowCards.length
                ? HomeCard(
                    card: rowCards[column],
                    dark: dark,
                    height: cellHeight,
                    imageSize: imageSize,
                  )
                // Keeps the width of the neighbours identical in a short row.
                : const SizedBox.shrink(),
          ),
        );
      }
      if (start > 0) rows.add(SizedBox(height: gutter));
      rows.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: cells));
    }

    return Column(children: rows);
  }
}

/// The single card style used across every home-screen section.
///
/// Strict vertical hierarchy: pastel clay artwork on top, title underneath it,
/// optional progress line at the very bottom.
class HomeCard extends StatelessWidget {
  const HomeCard({
    super.key,
    required this.card,
    required this.dark,
    required this.height,
    required this.imageSize,
  });

  final HomeCardSpec card;
  final bool dark;
  final double height;
  final double imageSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: card.title,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: card.onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: card.accent.withValues(alpha: 0.10),
          highlightColor: card.accent.withValues(alpha: 0.04),
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF132A23) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: dark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.25 : 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              // توسيط رأسي وأفقي: من غيره الـ Stack يحاذي المحتوى فوق
              // ويسيب الفراغ كله تحت — وهذا كان «البادنج من تحت».
              alignment: Alignment.center,
              children: [
                // لا بد من توسيع العمود لعرض الكارد كاملاً: الـ Stack يمنح
                // أبناءه قيوداً مرنة، ولو سبناه يصغّر نفسه لعرض أوسع ابن
                // فسيلتصق بمحاذاة البداية بدل أن يتوسط — وهذا هو البگ.
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _clayBadge(
                        imageAsset: card.imageAsset,
                        icon: card.icon,
                        accentColor: card.accent,
                        dark: dark,
                        size: imageSize,
                        pastelLightStart: card.pastelStart,
                        pastelLightEnd: card.pastelEnd,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        card.title,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                          color: dark ? Colors.white : DhikrColors.charcoal,
                        ),
                      ),
                      if (card.progress != null) ...[
                        const SizedBox(height: 8),
                        // شريط ضيق متمركز بدل خط بعرض الكارد — يقرأ كجزء
                        // من الكارت لا كعنصر منفصل.
                        SizedBox(
                          width: 56,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: card.progress,
                              minHeight: 4,
                              backgroundColor: dark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.06),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(card.accent),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (card.badgeText != null)
                  Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: card.accent.withValues(alpha: dark ? 0.22 : 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        card.badgeText!,
                        style: TextStyle(
                          fontFamily: DhikrTheme.arabicFont,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: dark ? Colors.white : card.accent,
                        ),
                      ),
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

/// 3D pastel clay artwork: the bundled asset when available, otherwise a soft
/// dimensional badge built from the card accent.
Widget _clayBadge({
  String? imageAsset,
  IconData? icon,
  required Color accentColor,
  required bool dark,
  double size = 58,
  Color? pastelLightStart,
  Color? pastelLightEnd,
}) {
  if (imageAsset != null) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        imageAsset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (ctx, err, stack) => Icon(
          icon ?? LucideIcons.sparkles,
          size: size * 0.45,
          color: dark ? Colors.white : accentColor,
        ),
      ),
    );
  }

  final bgStart = dark
      ? accentColor.withValues(alpha: 0.35)
      : (pastelLightStart ?? Color.lerp(Colors.white, accentColor, 0.14)!);
  final bgEnd = dark
      ? accentColor.withValues(alpha: 0.14)
      : (pastelLightEnd ?? Color.lerp(Colors.white, accentColor, 0.30)!);

  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(size * 0.35),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [bgStart, bgEnd],
      ),
      border: Border.all(
        color: dark ? Colors.white.withValues(alpha: 0.22) : Colors.white,
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: dark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.95),
          blurRadius: 4,
          offset: const Offset(-2, -2),
        ),
        BoxShadow(
          color: accentColor.withValues(alpha: dark ? 0.35 : 0.28),
          blurRadius: 10,
          offset: const Offset(3, 4),
        ),
        BoxShadow(
          color: accentColor.withValues(alpha: dark ? 0.15 : 0.12),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Center(
      child: Container(
        width: size * 0.70,
        height: size * 0.70,
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
            icon ?? LucideIcons.sparkles,
            size: size * 0.42,
            color: dark ? Colors.white : accentColor,
            shadows: [
              Shadow(
                color: accentColor.withValues(alpha: dark ? 0.60 : 0.38),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
