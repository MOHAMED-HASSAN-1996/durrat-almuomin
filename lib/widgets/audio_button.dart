import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Large, accessible audio player control.
///
/// Handles three states: idle (play), playing (pause), and unavailable.
class AudioButton extends StatelessWidget {
  const AudioButton({
    super.key,
    required this.isPlaying,
    required this.unavailable,
    required this.onPressed,
    required this.listenLabel,
    required this.pauseLabel,
    required this.unavailableLabel,
  });

  final bool isPlaying;
  final bool unavailable;
  final VoidCallback onPressed;
  final String listenLabel;
  final String pauseLabel;
  final String unavailableLabel;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    if (unavailable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: dark
              ? DhikrColors.darkSurfaceHigh
              : DhikrColors.sageSoft.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.volume_off_rounded,
                size: 18,
                color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft),
            const SizedBox(width: 8),
            Text(
              unavailableLabel,
              style: TextStyle(
                fontFamily: DhikrTheme.arabicFont,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: dark ? DhikrColors.darkMuted : DhikrColors.charcoalSoft,
              ),
            ),
          ],
        ),
      );
    }

    return Semantics(
      button: true,
      label: isPlaying ? pauseLabel : listenLabel,
      child: Material(
        color: isPlaying
            ? (dark ? DhikrColors.sage : DhikrColors.forest)
            : (dark
                ? DhikrColors.darkSurfaceHigh
                : DhikrColors.sageSoft.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPlaying ? Icons.pause_rounded : Icons.volume_up_rounded,
                  size: 22,
                  color: isPlaying
                      ? (dark ? DhikrColors.darkBg : Colors.white)
                      : (dark ? DhikrColors.sage : DhikrColors.forest),
                ),
                const SizedBox(width: 8),
                Text(
                  isPlaying ? pauseLabel : listenLabel,
                  style: TextStyle(
                    fontFamily: DhikrTheme.arabicFont,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isPlaying
                        ? (dark ? DhikrColors.darkBg : Colors.white)
                        : (dark ? DhikrColors.sage : DhikrColors.forest),
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