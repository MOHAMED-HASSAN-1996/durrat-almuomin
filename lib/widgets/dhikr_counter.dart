import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Large circular tap counter with reliable increment behavior.
///
/// The counter never exceeds [target]; when [current] reaches [target] the
/// widget displays a completed state. State lives in the parent so it survives
/// rebuilds and navigation.
class DhikrCounter extends StatelessWidget {
  const DhikrCounter({
    super.key,
    required this.current,
    required this.target,
    required this.onTap,
    required this.languageLabel,
    this.size = 250,
  });

  final int current;
  final int target;
  final VoidCallback onTap;
  final double size;

  /// Accessibility label, e.g. "Repetition 2 of 3" / "التكرار ٢ من ٣".
  final String languageLabel;

  double get _fraction => target == 0 ? 0 : current / target;
  bool get _done => current >= target;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final done = _done;
    final s = size / 250;

    return Semantics(
      button: true,
      label: languageLabel,
      value: done ? '$current of $target (complete)' : '$current of $target',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(2),
          child: Stack(
            children: [
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: _fraction),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return CircularProgressIndicator(
                      value: value.clamp(0.0, 1.0),
                      strokeWidth: 10 * s,
                      strokeCap: StrokeCap.round,
                      backgroundColor: dark
                          ? DhikrColors.darkSurfaceHigh
                          : DhikrColors.sageSoft,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        done
                            ? (dark ? DhikrColors.sage : DhikrColors.success)
                            : (dark ? DhikrColors.sage : DhikrColors.forest),
                      ),
                    );
                  },
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 12 * s),
                    Text(
                      '$current',
                      key: ValueKey(current),
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontWeight: FontWeight.w700,
                        fontSize: 72 * s,
                        height: 1.1,
                        color: done
                            ? (dark ? DhikrColors.sage : DhikrColors.success)
                            : (dark ? DhikrColors.darkText : DhikrColors.charcoal),
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '/ ',
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontSize: 20 * s,
                              color: dark
                                  ? DhikrColors.darkMuted
                                  : DhikrColors.charcoalSoft,
                            ),
                          ),
                          TextSpan(
                            text: target.toString(),
                            style: TextStyle(
                              fontFamily: DhikrTheme.arabicFont,
                              fontSize: 20 * s,
                              fontWeight: FontWeight.w600,
                              color: dark
                                  ? DhikrColors.darkMuted
                                  : DhikrColors.charcoalSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16 * s),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: done
                          ? Icon(Icons.check_circle_rounded,
                              key: const ValueKey('done'),
                              color: dark
                                  ? DhikrColors.sage
                                  : DhikrColors.success,
                              size: 40 * s)
                          : Text(
                              'اضغط',
                              key: const ValueKey('tap'),
                              style: TextStyle(
                                fontFamily: DhikrTheme.arabicFont,
                                fontSize: 20 * s,
                                color: dark
                                    ? DhikrColors.darkMuted
                                    : DhikrColors.charcoalSoft,
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
    );
  }
}