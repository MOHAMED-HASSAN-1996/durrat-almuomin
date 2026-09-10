import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Full-screen completion state with a subtle fade/scale animation.
/// No confetti, no loud gamification, no sound.
class CompletionScreen extends StatefulWidget {
  const CompletionScreen({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.backLabel,
    required this.onBackHome,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final String backLabel;
  final VoidCallback onBackHome;

  @override
  State<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<CompletionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ).drive(Tween(begin: 0.85, end: 1.0));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: dark ? DhikrColors.darkBg : DhikrColors.ivory,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: (dark ? DhikrColors.sage : DhikrColors.forest)
                            .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        widget.emoji,
                        style: const TextStyle(fontSize: 56),
                      ),
                    ),
                    const SizedBox(height: 36),
                    Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontWeight: FontWeight.w700,
                        fontSize: 27,
                        height: 1.5,
                        color: dark ? DhikrColors.darkText : DhikrColors.charcoal,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        fontSize: 19,
                        height: 1.6,
                        color: dark
                            ? DhikrColors.darkMuted
                            : DhikrColors.forestLight,
                      ),
                    ),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: widget.onBackHome,
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              dark ? DhikrColors.sage : DhikrColors.forest,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          widget.backLabel,
                          style: const TextStyle(
                            fontFamily: DhikrTheme.arabicFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}