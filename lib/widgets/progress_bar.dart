import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Displays progress bar for a category.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.fraction,
    this.height = 8,
    this.showLabel = false,
    this.label,
  });

  final double fraction;
  final double height;
  final bool showLabel;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final clamped = fraction.clamp(0.0, 1.0);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel && label != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label!,
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: dark ? DhikrColors.darkMuted : DhikrColors.forestLight,
              ),
            ),
          ),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: height,
            backgroundColor:
                dark ? DhikrColors.darkSurfaceHigh : DhikrColors.sageSoft,
            valueColor: AlwaysStoppedAnimation<Color>(
              dark ? DhikrColors.sage : DhikrColors.forest,
            ),
          ),
        ),
      ],
    );
  }
}