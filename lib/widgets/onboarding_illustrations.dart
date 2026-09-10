import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Palette tailored for the green Islamic onboarding night scenes
class OnboardingGreenPalette {
  static const Color skyTop = Color(0xFF091411);
  static const Color skyMid = Color(0xFF0F221D);
  static const Color skyHighlight = Color(0xFF1B3D34);
  static const Color domeBack = Color(0xFF142923);
  static const Color domeMid = Color(0xFF19332C);
  static const Color domeFore = Color(0xFF0D1B17);
  static const Color glowCenter = Color(0xFF346859);
  static const Color moon = Color(0xFFA5E6C7);
  static const Color moonGlow = Color(0xFF4E9E80);
  static const Color star = Color(0xFFD6F2E5);
  static const Color archBorder = Color(0xFF38685A);
  static const Color archBorderLight = Color(0xFF72A796);
}

/// Slide 1 Illustration: Majestic central dome with crescent moon finial,
/// radiant moonlight halo, stars, and side minarets.
class MosqueDomeIllustration extends StatelessWidget {
  const MosqueDomeIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, double.infinity),
      painter: _MosqueDomePainter(),
    );
  }
}

class _MosqueDomePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Background Arch Outline (faint layered Islamic pointed arch in sky)
    final archPath = Path();
    archPath.moveTo(w * 0.1, h);
    archPath.lineTo(w * 0.1, h * 0.35);
    archPath.cubicTo(
      w * 0.1,
      h * 0.18,
      w * 0.35,
      h * 0.10,
      w * 0.5,
      h * 0.05,
    );
    archPath.cubicTo(
      w * 0.65,
      h * 0.10,
      w * 0.9,
      h * 0.18,
      w * 0.9,
      h * 0.35,
    );
    archPath.lineTo(w * 0.9, h);

    final archPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = OnboardingGreenPalette.skyHighlight.withValues(alpha: 0.35);
    canvas.drawPath(archPath, archPaint);

    // Inner arch line for decorative depth
    final innerArch = Path();
    innerArch.moveTo(w * 0.15, h);
    innerArch.lineTo(w * 0.15, h * 0.37);
    innerArch.cubicTo(
      w * 0.15,
      h * 0.22,
      w * 0.36,
      h * 0.14,
      w * 0.5,
      h * 0.09,
    );
    innerArch.cubicTo(
      w * 0.64,
      h * 0.14,
      w * 0.85,
      h * 0.22,
      w * 0.85,
      h * 0.37,
    );
    innerArch.lineTo(w * 0.85, h);
    canvas.drawPath(
      innerArch,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = OnboardingGreenPalette.skyHighlight.withValues(alpha: 0.2),
    );

    // 2. Stars scattered across the night sky
    _drawStars(canvas, [
      Offset(w * 0.22, h * 0.16),
      Offset(w * 0.32, h * 0.24),
      Offset(w * 0.18, h * 0.32),
      Offset(w * 0.40, h * 0.18),
      Offset(w * 0.78, h * 0.17),
      Offset(w * 0.68, h * 0.25),
      Offset(w * 0.82, h * 0.30),
      Offset(w * 0.62, h * 0.19),
    ]);

    // 3. Radiant Moonlight Glow behind dome finial
    final glowCenter = Offset(w * 0.5, h * 0.38);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          OnboardingGreenPalette.glowCenter.withValues(alpha: 0.45),
          OnboardingGreenPalette.skyHighlight.withValues(alpha: 0.2),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: glowCenter, radius: w * 0.42));
    canvas.drawCircle(glowCenter, w * 0.42, glowPaint);

    // 4. Background Mosque Silhouettes (Side minarets and side domes)
    final backSilhouette = Path();
    // Left side dome
    backSilhouette.moveTo(0, h);
    backSilhouette.lineTo(0, h * 0.65);
    backSilhouette.cubicTo(
      w * 0.05,
      h * 0.55,
      w * 0.2,
      h * 0.55,
      w * 0.25,
      h * 0.68,
    );
    // Left minaret base
    backSilhouette.lineTo(w * 0.25, h * 0.45);
    backSilhouette.lineTo(w * 0.28, h * 0.45);
    backSilhouette.lineTo(w * 0.265, h * 0.38); // spire
    backSilhouette.lineTo(w * 0.25, h * 0.45);
    // Right minaret
    backSilhouette.lineTo(w * 0.72, h * 0.7);
    backSilhouette.lineTo(w * 0.72, h * 0.45);
    backSilhouette.lineTo(w * 0.75, h * 0.45);
    backSilhouette.lineTo(w * 0.735, h * 0.38);
    backSilhouette.lineTo(w * 0.75, h * 0.45);
    // Right side dome
    backSilhouette.cubicTo(
      w * 0.8,
      h * 0.55,
      w * 0.95,
      h * 0.55,
      w,
      h * 0.65,
    );
    backSilhouette.lineTo(w, h);
    backSilhouette.close();

    canvas.drawPath(
      backSilhouette,
      Paint()..color = OnboardingGreenPalette.domeBack,
    );

    // 5. Main Center Dome Silhouette (Graceful pointed dome)
    final domePath = Path();
    domePath.moveTo(w * 0.12, h);
    domePath.lineTo(w * 0.12, h * 0.72);
    // Left curve towards the pointed top
    domePath.cubicTo(
      w * 0.15,
      h * 0.56,
      w * 0.35,
      h * 0.42,
      w * 0.5,
      h * 0.38,
    );
    // Right curve down
    domePath.cubicTo(
      w * 0.65,
      h * 0.42,
      w * 0.85,
      h * 0.56,
      w * 0.88,
      h * 0.72,
    );
    domePath.lineTo(w * 0.88, h);
    domePath.close();

    canvas.drawPath(
      domePath,
      Paint()..color = OnboardingGreenPalette.domeFore,
    );

    // 6. Finial (Alam) & Crescent on top of the dome
    final finialX = w * 0.5;
    final finialBaseY = h * 0.38;

    // Finial rod
    canvas.drawLine(
      Offset(finialX, finialBaseY),
      Offset(finialX, finialBaseY - h * 0.06),
      Paint()
        ..color = OnboardingGreenPalette.domeFore
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );

    // Small spheres along finial
    canvas.drawCircle(
      Offset(finialX, finialBaseY - h * 0.025),
      3.5,
      Paint()..color = OnboardingGreenPalette.domeFore,
    );
    canvas.drawCircle(
      Offset(finialX, finialBaseY - h * 0.05),
      2.5,
      Paint()..color = OnboardingGreenPalette.domeFore,
    );

    // Crescent Moon at apex
    _drawCrescentMoon(
      canvas,
      center: Offset(finialX, finialBaseY - h * 0.075),
      radius: 13,
      angle: -math.pi / 2, // Upward-pointing crescent as on mosques
      color: OnboardingGreenPalette.moon,
      glowColor: OnboardingGreenPalette.moonGlow,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Slide 2 Illustration: Ornate Islamic Mihrab Arch Frame with stars,
/// glowing mint crescent moon, and serene mosque silhouette inside.
class MihrabArchIllustration extends StatelessWidget {
  const MihrabArchIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, double.infinity),
      painter: _MihrabArchPainter(),
    );
  }
}

class _MihrabArchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Define Mihrab Arch Window Bounds
    final left = w * 0.16;
    final right = w * 0.84;
    final top = h * 0.08;
    final bottom = h * 0.88;
    final archW = right - left;
    final archH = bottom - top;

    // Reconstruct continuous closed path for clip and stroke
    final continuousArch = Path();
    continuousArch.moveTo(left, bottom - 24);
    continuousArch.quadraticBezierTo(left, bottom, left + 24, bottom);
    continuousArch.lineTo(right - 24, bottom);
    continuousArch.quadraticBezierTo(right, bottom, right, bottom - 24);
    continuousArch.lineTo(right, top + archH * 0.38);
    continuousArch.cubicTo(
      right + archW * 0.02,
      top + archH * 0.20,
      w * 0.68,
      top + archH * 0.08,
      w * 0.5,
      top,
    );
    continuousArch.cubicTo(
      w * 0.32,
      top + archH * 0.08,
      left - archW * 0.02,
      top + archH * 0.20,
      left,
      top + archH * 0.38,
    );
    continuousArch.close();

    // 1. Outer Glow around the Frame
    canvas.drawPath(
      continuousArch,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..color = OnboardingGreenPalette.glowCenter.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // 2. Thick Elegant Arch Border
    canvas.drawPath(
      continuousArch,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..color = OnboardingGreenPalette.archBorder,
    );
    // Inner fine highlight line
    canvas.drawPath(
      continuousArch,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = OnboardingGreenPalette.archBorderLight.withValues(alpha: 0.7),
    );

    // 3. Draw inside the Mihrab Arch (Clipping)
    canvas.save();
    canvas.clipPath(continuousArch);

    // Inner Deep Night Sky Gradient
    final innerSkyRect = Rect.fromLTRB(left, top, right, bottom);
    final skyShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0xFF07120F),
        Color(0xFF0C1D18),
        Color(0xFF142B24),
        Color(0xFF081410),
      ],
      stops: const [0.0, 0.4, 0.7, 1.0],
    ).createShader(innerSkyRect);
    canvas.drawRect(innerSkyRect, Paint()..shader = skyShader);

    // Inner Stars
    _drawStars(canvas, [
      Offset(w * 0.32, top + archH * 0.22),
      Offset(w * 0.42, top + archH * 0.16),
      Offset(w * 0.60, top + archH * 0.17),
      Offset(w * 0.70, top + archH * 0.24),
      Offset(w * 0.28, top + archH * 0.32),
      Offset(w * 0.72, top + archH * 0.33),
      Offset(w * 0.38, top + archH * 0.42),
      Offset(w * 0.64, top + archH * 0.40),
    ]);

    // Glowing Crescent Moon centered in the upper sky
    final moonCenter = Offset(w * 0.5, top + archH * 0.28);
    // Moon radiant halo
    canvas.drawCircle(
      moonCenter,
      30,
      Paint()
        ..shader = RadialGradient(
          colors: [
            OnboardingGreenPalette.moonGlow.withValues(alpha: 0.5),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: moonCenter, radius: 30)),
    );
    // Crescent itself
    _drawCrescentMoon(
      canvas,
      center: moonCenter,
      radius: 15,
      angle: -math.pi / 4,
      color: OnboardingGreenPalette.moon,
      glowColor: OnboardingGreenPalette.moonGlow,
    );

    // Mosque Silhouettes inside the arch
    // Background Mosque Layer
    final innerBackMosque = Path();
    innerBackMosque.moveTo(left, bottom);
    innerBackMosque.lineTo(left, bottom - archH * 0.32);
    // Side dome left
    innerBackMosque.cubicTo(
      w * 0.24,
      bottom - archH * 0.38,
      w * 0.34,
      bottom - archH * 0.38,
      w * 0.38,
      bottom - archH * 0.32,
    );
    // Side dome right
    innerBackMosque.cubicTo(
      w * 0.62,
      bottom - archH * 0.38,
      w * 0.72,
      bottom - archH * 0.38,
      right,
      bottom - archH * 0.32,
    );
    innerBackMosque.lineTo(right, bottom);
    innerBackMosque.close();

    canvas.drawPath(
      innerBackMosque,
      Paint()..color = OnboardingGreenPalette.domeBack,
    );

    // Minarets
    _drawMinaret(canvas, Offset(w * 0.36, bottom - archH * 0.48), 8, archH * 0.28);
    _drawMinaret(canvas, Offset(w * 0.44, bottom - archH * 0.56), 7, archH * 0.36);
    _drawMinaret(canvas, Offset(w * 0.56, bottom - archH * 0.56), 7, archH * 0.36);
    _drawMinaret(canvas, Offset(w * 0.64, bottom - archH * 0.48), 8, archH * 0.28);

    // Foreground Central Dome
    final innerCenterDome = Path();
    innerCenterDome.moveTo(w * 0.32, bottom);
    innerCenterDome.lineTo(w * 0.32, bottom - archH * 0.22);
    innerCenterDome.cubicTo(
      w * 0.36,
      bottom - archH * 0.42,
      w * 0.64,
      bottom - archH * 0.42,
      w * 0.68,
      bottom - archH * 0.22,
    );
    innerCenterDome.lineTo(w * 0.68, bottom);
    innerCenterDome.close();

    canvas.drawPath(
      innerCenterDome,
      Paint()..color = OnboardingGreenPalette.domeFore,
    );

    // Small crescent on center dome inside
    _drawCrescentMoon(
      canvas,
      center: Offset(w * 0.5, bottom - archH * 0.43),
      radius: 5,
      angle: -math.pi / 2,
      color: OnboardingGreenPalette.moon,
      glowColor: OnboardingGreenPalette.moonGlow,
    );

    canvas.restore();
  }

  void _drawMinaret(Canvas canvas, Offset top, double width, double height) {
    final path = Path();
    path.moveTo(top.dx - width / 2, top.dy + height);
    path.lineTo(top.dx - width / 2, top.dy + 14);
    // Balcony
    path.lineTo(top.dx - width * 0.8, top.dy + 14);
    path.lineTo(top.dx - width * 0.8, top.dy + 10);
    path.lineTo(top.dx - width / 3, top.dy + 10);
    // Spire
    path.lineTo(top.dx, top.dy);
    path.lineTo(top.dx + width / 3, top.dy + 10);
    // Right balcony
    path.lineTo(top.dx + width * 0.8, top.dy + 10);
    path.lineTo(top.dx + width * 0.8, top.dy + 14);
    path.lineTo(top.dx + width / 2, top.dy + 14);
    path.lineTo(top.dx + width / 2, top.dy + height);
    path.close();

    canvas.drawPath(path, Paint()..color = OnboardingGreenPalette.domeMid);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Slide 3 Illustration: Grand Mosque with arched drum windows,
/// towering minaret with conical spire, and glowing crescent.
class GrandMosqueIllustration extends StatelessWidget {
  const GrandMosqueIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, double.infinity),
      painter: _GrandMosquePainter(),
    );
  }
}

class _GrandMosquePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Multiple Arch Outlines in Background Sky
    for (int i = 0; i < 2; i++) {
      final factor = 1.0 + (i * 0.15);
      final p = Path();
      p.moveTo(w * 0.05 / factor, h);
      p.lineTo(w * 0.05 / factor, h * 0.35);
      p.cubicTo(
        w * 0.08 / factor,
        h * 0.16,
        w * 0.35,
        h * 0.08,
        w * 0.5,
        h * 0.05 + (i * 12),
      );
      p.cubicTo(
        w * 0.65,
        h * 0.08,
        w * (1 - 0.08 / factor),
        h * 0.16,
        w * (1 - 0.05 / factor),
        h * 0.35,
      );
      p.lineTo(w * (1 - 0.05 / factor), h);

      canvas.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = OnboardingGreenPalette.skyHighlight.withValues(alpha: 0.28 - (i * 0.1)),
      );
    }

    // 2. Stars
    _drawStars(canvas, [
      Offset(w * 0.15, h * 0.18),
      Offset(w * 0.25, h * 0.25),
      Offset(w * 0.35, h * 0.15),
      Offset(w * 0.72, h * 0.20),
      Offset(w * 0.85, h * 0.26),
      Offset(w * 0.68, h * 0.14),
    ]);

    // 3. Moonlight Glow behind the dome and minaret
    final haloCenter = Offset(w * 0.48, h * 0.36);
    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          OnboardingGreenPalette.glowCenter.withValues(alpha: 0.4),
          OnboardingGreenPalette.skyHighlight.withValues(alpha: 0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: haloCenter, radius: w * 0.45));
    canvas.drawCircle(haloCenter, w * 0.45, haloPaint);

    // 4. Background Secondary Dome & Minaret
    final backPath = Path();
    backPath.moveTo(0, h);
    backPath.lineTo(0, h * 0.68);
    backPath.cubicTo(
      w * 0.08,
      h * 0.56,
      w * 0.24,
      h * 0.56,
      w * 0.30,
      h * 0.70,
    );
    backPath.lineTo(w, h * 0.70);
    backPath.lineTo(w, h);
    backPath.close();

    canvas.drawPath(backPath, Paint()..color = OnboardingGreenPalette.domeBack);

    // 5. Main Center Grand Dome
    final domePath = Path();
    final domeLeft = w * 0.15;
    final domeRight = w * 0.85;
    final domeDrumTop = h * 0.65;
    final domeApexY = h * 0.38;

    domePath.moveTo(domeLeft, h);
    // Straight drum wall up
    domePath.lineTo(domeLeft, domeDrumTop);
    // Dome curve to apex
    domePath.cubicTo(
      domeLeft + w * 0.05,
      h * 0.46,
      w * 0.35,
      domeApexY,
      w * 0.5,
      domeApexY,
    );
    domePath.cubicTo(
      w * 0.65,
      domeApexY,
      domeRight - w * 0.05,
      h * 0.46,
      domeRight,
      domeDrumTop,
    );
    // Right drum wall down
    domePath.lineTo(domeRight, h);
    domePath.close();

    canvas.drawPath(domePath, Paint()..color = OnboardingGreenPalette.domeFore);

    // 6. Arched Windows along the Drum base (as visible in reference image)
    const windowCount = 5;
    final windowSpacing = (domeRight - domeLeft) / (windowCount + 1);
    final winPaint = Paint()
      ..color = OnboardingGreenPalette.skyHighlight.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    for (int i = 1; i <= windowCount; i++) {
      final winX = domeLeft + (i * windowSpacing);
      final winY = domeDrumTop + 8;
      const winW = 12.0;
      const winH = 22.0;

      final winPath = Path();
      winPath.moveTo(winX - winW / 2, winY + winH);
      winPath.lineTo(winX - winW / 2, winY + winW / 2);
      // Arched top
      winPath.arcTo(
        Rect.fromCircle(center: Offset(winX, winY + winW / 2), radius: winW / 2),
        math.pi,
        math.pi,
        false,
      );
      winPath.lineTo(winX + winW / 2, winY + winH);
      winPath.close();

      canvas.drawPath(winPath, winPaint);
    }

    // 7. Dome Finial & Crescent
    canvas.drawLine(
      Offset(w * 0.5, domeApexY),
      Offset(w * 0.5, domeApexY - 32),
      Paint()
        ..color = OnboardingGreenPalette.domeFore
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );
    // Finial spheres
    canvas.drawCircle(Offset(w * 0.5, domeApexY - 12), 3.5, Paint()..color = OnboardingGreenPalette.domeFore);
    canvas.drawCircle(Offset(w * 0.5, domeApexY - 24), 2.5, Paint()..color = OnboardingGreenPalette.domeFore);

    // Crescent atop the Grand Dome
    _drawCrescentMoon(
      canvas,
      center: Offset(w * 0.5, domeApexY - 42),
      radius: 12,
      angle: -math.pi / 2,
      color: OnboardingGreenPalette.moon,
      glowColor: OnboardingGreenPalette.moonGlow,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ----------------------------------------------------------------------------
// Shared Drawing Helpers
// ----------------------------------------------------------------------------

void _drawStars(Canvas canvas, List<Offset> positions) {
  final starPaint = Paint()..color = OnboardingGreenPalette.star;
  final glowPaint = Paint()
    ..color = OnboardingGreenPalette.moonGlow.withValues(alpha: 0.35)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

  for (int i = 0; i < positions.length; i++) {
    final pos = positions[i];
    final isMajor = i % 3 == 0;
    if (isMajor) {
      // Four-pointed star sparkle
      canvas.drawCircle(pos, 2.5, glowPaint);
      final p = Path();
      const s = 3.5;
      p.moveTo(pos.dx, pos.dy - s);
      p.lineTo(pos.dx + 0.8, pos.dy - 0.8);
      p.lineTo(pos.dx + s, pos.dy);
      p.lineTo(pos.dx + 0.8, pos.dy + 0.8);
      p.lineTo(pos.dx, pos.dy + s);
      p.lineTo(pos.dx - 0.8, pos.dy + 0.8);
      p.lineTo(pos.dx - s, pos.dy);
      p.lineTo(pos.dx - 0.8, pos.dy - 0.8);
      p.close();
      canvas.drawPath(p, starPaint);
    } else {
      // Soft round star point
      canvas.drawCircle(pos, 1.3, starPaint);
    }
  }
}

void _drawCrescentMoon(
  Canvas canvas, {
  required Offset center,
  required double radius,
  required double angle,
  required Color color,
  required Color glowColor,
}) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.rotate(angle);

  // Outer glow
  canvas.drawCircle(
    Offset.zero,
    radius * 1.6,
    Paint()
      ..color = glowColor.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
  );

  // Crescent Shape via path difference / clipping
  final outerRadius = radius;
  final innerRadius = radius * 0.84;
  final offset = radius * 0.38;

  final moonPath = Path.combine(
    PathOperation.difference,
    Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: outerRadius)),
    Path()..addOval(Rect.fromCircle(center: Offset(offset, 0), radius: innerRadius)),
  );

  canvas.drawPath(
    moonPath,
    Paint()
      ..color = color
      ..style = PaintingStyle.fill,
  );

  canvas.restore();
}
