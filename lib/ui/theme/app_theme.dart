import 'package:flutter/material.dart';

import '../../config/app_palette.dart';

/// Builds Hörspiel's Material 3 themes from [AppPalette] so every screen matches
/// the Stitch mockups (warm paper, Bernstein amber, serif headings).
class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppPalette.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppPalette.primary,
      secondary: AppPalette.secondary,
      surface: AppPalette.surface,
      error: AppPalette.error,
    );
    return _base(scheme, AppPalette.background, AppPalette.ink);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppPalette.primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AppPalette.darkPrimary,
      secondary: AppPalette.secondary,
      surface: AppPalette.darkSurface,
      error: AppPalette.error,
    );
    return _base(scheme, AppPalette.darkBackground, AppPalette.darkText);
  }

  static ThemeData _base(ColorScheme scheme, Color background, Color onBg) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      textTheme: base.textTheme.copyWith(
        // Serif for headings (a system serif stands in until a bundled font is
        // added; the Stitch designs specify Fraunces/Lora).
        displaySmall: base.textTheme.displaySmall
            ?.copyWith(fontFamily: 'serif', fontWeight: FontWeight.w700, color: onBg),
        headlineMedium: base.textTheme.headlineMedium
            ?.copyWith(fontFamily: 'serif', fontWeight: FontWeight.w700, color: onBg),
        titleLarge: base.textTheme.titleLarge
            ?.copyWith(fontFamily: 'serif', fontWeight: FontWeight.w600, color: onBg),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: AppPalette.primary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontFamily: 'serif',
          fontWeight: FontWeight.w700,
          fontSize: 22,
          color: AppPalette.primary,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: const StadiumBorder(),
        side: const BorderSide(color: AppPalette.border),
      ),
      cardTheme: base.cardTheme.copyWith(
        color: scheme.surface,
        elevation: 1.5,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppPalette.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          textStyle:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
