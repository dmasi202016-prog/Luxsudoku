import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_constants.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.fuchsia,
      onPrimary: Colors.white,
      secondary: AppColors.turquoise,
      onSecondary: AppColors.midnight,
      error: Colors.redAccent,
      onError: Colors.white,
      background: Color(0xFFFDF6F8),
      onBackground: AppColors.midnight,
      surface: Colors.white,
      onSurface: AppColors.midnight,
    );
    return _base(colorScheme);
  }

  static ThemeData dark() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.goldPrimary, // 골드 컬러로 변경
      onPrimary: Colors.white,
      secondary: AppColors.goldSecondary, // 골드 세컨더리로 변경
      onSecondary: Colors.black,
      error: AppColors.errorNumberColor,
      onError: Colors.white,
      background: AppColors.background,
      onBackground: Colors.white,
      surface: AppColors.darkCellBg,
      onSurface: AppColors.fixedNumberColor,
    );
    return _base(colorScheme);
  }

  static ThemeData _base(ColorScheme colorScheme) {
    final textTheme = AppTextStyles.buildTextTheme(colorScheme);
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.background.withOpacity(0.4),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: textTheme.titleMedium,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: buttonShape,
          side: BorderSide(color: colorScheme.primary.withOpacity(0.5), width: 1.5),
          textStyle: textTheme.titleMedium,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface.withOpacity(0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.secondary.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surface.withOpacity(0.6),
        selectedColor: colorScheme.primary.withOpacity(0.8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        labelStyle: textTheme.labelLarge!,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        contentTextStyle: textTheme.bodyMedium,
        backgroundColor: colorScheme.surface.withOpacity(0.85),
      ),
      fontFamily: GoogleFonts.montserrat().fontFamily,
    );
  }
}
