import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextTheme buildTextTheme(ColorScheme colorScheme) {
    final base = GoogleFonts.montserratTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onBackground,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onBackground,
      ),
      displaySmall: base.displaySmall?.copyWith(
        letterSpacing: 1.2,
        color: colorScheme.onBackground,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: colorScheme.onBackground,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        height: 1.4,
        color: colorScheme.onBackground,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        height: 1.5,
        color: colorScheme.onBackground.withOpacity(0.9),
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onBackground,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 1.1,
        color: colorScheme.onBackground,
      ),
    );
  }
}
