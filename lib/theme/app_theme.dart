import 'package:flutter/material.dart';

/// Color system for DHIKR — calm, natural, premium.
///
/// Primary: deep forest green.
/// Secondary: muted sage.
/// Background: warm ivory / off-white.
/// Text: deep charcoal.
/// Accent: soft sand.
/// Dark: deep charcoal / forest.
class DhikrColors {
  DhikrColors._();

  // Core palette
  static const Color forest = Color(0xFF23423B); // deep forest green
  static const Color forestDeep = Color(0xFF16302B);
  static const Color forestLight = Color(0xFF3A6B5F);
  static const Color sage = Color(0xFF9DB8A8); // muted sage
  static const Color sageSoft = Color(0xFFD6E2DA);
  static const Color ivory = Color(0xFFFAF6EF); // warm ivory
  static const Color ivoryWarm = Color(0xFFF2ECDF);
  static const Color charcoal = Color(0xFF2B2F2C); // deep charcoal
  static const Color charcoalSoft = Color(0xFF4A514C);
  static const Color sand = Color(0xFFE5D9BD); // soft sand
  static const Color sandDeep = Color(0xFFCBB98F);
  static const Color cream = Color(0xFFF5F0E6); // light surface
  static const Color success = Color(0xFF4E8E6A);

  // Dark mode surfaces
  static const Color darkBg = Color(0xFF161D1A); // deep charcoal-forest
  static const Color darkSurface = Color(0xFF1F2A25);
  static const Color darkSurfaceHigh = Color(0xFF29362F);
  static const Color darkText = Color(0xFFF1EBDD); // soft cream
  static const Color darkMuted = Color(0xFFA9B8AF);
}

/// ThemeData builders for light and dark modes using the DHIKR palette.
class DhikrTheme {
  DhikrTheme._();

  static const String arabicFont = 'ThmanyahSerifText';

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: arabicFont,
      fontFamilyFallback: const [arabicFont, 'TheYearOfHandicrafts'],
      colorScheme: ColorScheme.light(
        primary: DhikrColors.forest,
        onPrimary: Colors.white,
        secondary: DhikrColors.forestLight,
        onSecondary: Colors.white,
        surface: DhikrColors.cream,
        onSurface: DhikrColors.charcoal,
        surfaceContainerHighest: DhikrColors.sageSoft,
        error: const Color(0xFFB3261E),
      ),
      scaffoldBackgroundColor: DhikrColors.ivory,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: DhikrColors.charcoal),
        titleTextStyle: TextStyle(
          fontFamily: arabicFont,
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: DhikrColors.charcoal,
        ),
      ),
      cardTheme: CardThemeData(
        color: DhikrColors.cream,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: DhikrColors.forest,
        foregroundColor: Colors.white,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: DhikrColors.forest,
      ),
      dividerTheme: DividerThemeData(
        color: DhikrColors.charcoal.withValues(alpha: 0.08),
        thickness: 1,
      ),
      textTheme: base.textTheme.apply(fontFamily: arabicFont, fontFamilyFallback: const [arabicFont]).copyWith(
        displaySmall: const TextStyle(
          fontFamily: arabicFont,
          fontWeight: FontWeight.w700,
          fontSize: 38,
          height: 1.4,
          color: DhikrColors.charcoal,
        ),
        headlineMedium: const TextStyle(
          fontFamily: arabicFont,
          fontWeight: FontWeight.w700,
          fontSize: 26,
          height: 1.4,
          color: DhikrColors.charcoal,
        ),
        titleLarge: const TextStyle(
          fontFamily: arabicFont,
          fontWeight: FontWeight.w600,
          fontSize: 18,
          height: 1.4,
          color: DhikrColors.charcoal,
        ),
        bodyLarge: TextStyle(
          fontFamily: arabicFont,
          fontSize: 16,
          height: 1.6,
          color: DhikrColors.charcoal.withValues(alpha: 0.92),
        ),
        bodyMedium: TextStyle(
          fontFamily: arabicFont,
          fontSize: 14,
          height: 1.5,
          color: DhikrColors.charcoalSoft.withValues(alpha: 0.9),
        ),
        labelLarge: const TextStyle(
          fontFamily: arabicFont,
          fontWeight: FontWeight.w600,
          fontSize: 15,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: arabicFont,
      fontFamilyFallback: const [arabicFont],
      colorScheme: ColorScheme.dark(
        primary: DhikrColors.sage,
        onPrimary: DhikrColors.darkBg,
        secondary: const Color(0xFF6FA085),
        onSecondary: DhikrColors.darkBg,
        surface: DhikrColors.darkSurface,
        onSurface: DhikrColors.darkText,
        surfaceContainerHighest: DhikrColors.darkSurfaceHigh,
        error: const Color(0xFFF2B8B5),
      ),
      scaffoldBackgroundColor: DhikrColors.darkBg,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: DhikrColors.darkText),
        titleTextStyle: TextStyle(
          fontFamily: arabicFont,
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: DhikrColors.darkText,
        ),
      ),
      cardTheme: const CardThemeData(
        color: DhikrColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(24))),
        margin: EdgeInsets.zero,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: DhikrColors.sage,
        foregroundColor: DhikrColors.darkBg,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: DhikrColors.sage,
      ),
      dividerTheme: DividerThemeData(
        color: DhikrColors.darkText.withValues(alpha: 0.1),
        thickness: 1,
      ),
      textTheme: base.textTheme.apply(fontFamily: arabicFont, fontFamilyFallback: const [arabicFont]).copyWith(
        displaySmall: const TextStyle(
          fontFamily: arabicFont,
          fontWeight: FontWeight.w700,
          fontSize: 38,
          height: 1.4,
          color: DhikrColors.darkText,
        ),
        headlineMedium: const TextStyle(
          fontFamily: arabicFont,
          fontWeight: FontWeight.w700,
          fontSize: 26,
          height: 1.4,
          color: DhikrColors.darkText,
        ),
        titleLarge: const TextStyle(
          fontFamily: arabicFont,
          fontWeight: FontWeight.w600,
          fontSize: 18,
          height: 1.4,
          color: DhikrColors.darkText,
        ),
        bodyLarge: TextStyle(
          fontFamily: arabicFont,
          fontSize: 16,
          height: 1.6,
          color: DhikrColors.darkText.withValues(alpha: 0.92),
        ),
        bodyMedium: TextStyle(
          fontFamily: arabicFont,
          fontSize: 14,
          height: 1.5,
          color: DhikrColors.darkMuted.withValues(alpha: 0.92),
        ),
        labelLarge: const TextStyle(
          fontFamily: arabicFont,
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: DhikrColors.darkText,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}