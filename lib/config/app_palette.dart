import 'package:flutter/material.dart';

/// Single source of truth for Hörspiel's brand colors.
///
/// Mirrors the tokens in `docs/design/stitch-prompts-phase1.md` and the
/// Stitch-generated designs. Keep code and design in sync: if a token changes
/// in one place, change it here too.
class AppPalette {
  const AppPalette._();

  // --- Light theme ---
  static const Color background = Color(0xFFFAF6F0); // warm paper
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE7DFD3); // hairline
  static const Color primary = Color(0xFFC8621C); // Bernstein amber
  static const Color primaryPressed = Color(0xFFA64E12);
  static const Color secondary = Color(0xFF2F5D50); // forest green
  static const Color success = Color(0xFF2E7D5B);
  static const Color error = Color(0xFFB23A2E); // brick
  static const Color ink = Color(0xFF1F1B16); // text
  static const Color mutedText = Color(0xFF6B6157);

  // --- Dark theme ---
  static const Color darkBackground = Color(0xFF16130F);
  static const Color darkSurface = Color(0xFF211C16);
  static const Color darkText = Color(0xFFF3ECE1);
  static const Color darkPrimary = Color(0xFFE0842F);
}
