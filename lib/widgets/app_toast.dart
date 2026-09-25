import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Top-of-screen toast/snackbar used across the app so feedback never hides
/// behind bottom navigation or system UI.
class AppToast {
  static OverlayEntry? _entry;
  static int _token = 0;

  /// Shows [snackBar]'s content anchored to the top of the screen.
  /// Accepts a standard [SnackBar] so existing call sites keep duration,
  /// content, backgroundColor, and action.
  static void show(BuildContext context, SnackBar snackBar) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      // Fallback: no overlay available (should not happen in normal app).
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(snackBar);
      return;
    }

    hide(context);

    final token = ++_token;
    final duration = snackBar.duration;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _TopToast(snackBar: snackBar, onDismissed: () {
        if (_entry == entry) _entry = null;
      }),
    );
    _entry = entry;
    overlay.insert(entry);

    Future<void>.delayed(duration, () {
      if (_token == token && _entry == entry) {
        entry.remove();
        if (_entry == entry) _entry = null;
      }
    });
  }

  /// Convenience for plain text messages (defaults: 2.5s, dark surface).
  static void message(
    BuildContext context,
    String text, {
    Duration duration = const Duration(milliseconds: 2500),
    Color? backgroundColor,
    SnackBarAction? action,
  }) {
    show(
      context,
      SnackBar(
        content: Text(text),
        duration: duration,
        backgroundColor: backgroundColor,
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Removes the current top toast, if any.
  static void hide(BuildContext context) {
    final entry = _entry;
    _token++;
    if (entry != null) {
      entry.remove();
      _entry = null;
    }
    ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
  }
}

class _TopToast extends StatefulWidget {
  const _TopToast({required this.snackBar, required this.onDismissed});

  final SnackBar snackBar;
  final VoidCallback onDismissed;

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    reverseDuration: const Duration(milliseconds: 180),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final snack = widget.snackBar;
    // Prefer explicit content Text color when present; default white on toast bg.
    Color contentColor = Colors.white;
    final content = snack.content;
    if (content is Text && content.style?.color != null) {
      contentColor = content.style!.color!;
    }

    return Positioned(
      top: media.padding.top + 8,
      left: 12,
      right: 12,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic)),
        child: FadeTransition(
          opacity: _controller,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                snack.action != null ? 4 : 16,
                12,
              ),
              decoration: BoxDecoration(
                color: snack.backgroundColor ?? const Color(0xFF142B22),
                borderRadius: BorderRadius.circular(snack.shape is RoundedRectangleBorder
                    ? 14
                    : 14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: snack.action != null
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DefaultTextStyle(
                      style: TextStyle(
                        fontFamily: DhikrTheme.arabicFont,
                        color: contentColor,
                        fontSize: 13.5,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                      child: snack.content,
                    ),
                  ),
                  if (snack.action != null) ...[
                    const SizedBox(width: 8),
                    snack.action!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
