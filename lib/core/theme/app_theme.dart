import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme => withTextTheme(
      GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme));

  static ThemeData withTextTheme(TextTheme textTheme) {
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    final text = textTheme
        .apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary)
        .copyWith(
          headlineLarge: textTheme.headlineLarge?.copyWith(
              fontSize: 34,
              height: 1.12,
              letterSpacing: -1.3,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary),
          headlineMedium: textTheme.headlineMedium?.copyWith(
              fontSize: 28,
              height: 1.18,
              letterSpacing: -0.9,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary),
          titleLarge: textTheme.titleLarge?.copyWith(
              fontSize: 21,
              height: 1.25,
              letterSpacing: -0.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
          titleMedium: textTheme.titleMedium?.copyWith(
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
          bodyLarge: textTheme.bodyLarge?.copyWith(
              fontSize: 15, height: 1.55, color: AppColors.textPrimary),
          bodyMedium: textTheme.bodyMedium?.copyWith(
              fontSize: 14, height: 1.5, color: AppColors.textSecondary),
          bodySmall: textTheme.bodySmall?.copyWith(
              fontSize: 12, height: 1.45, color: AppColors.textSecondary),
        );
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          error: AppColors.error,
          primaryContainer: AppColors.primaryLight,
          onSurface: AppColors.textPrimary),
      textTheme: text,
      appBarTheme: AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: text.titleLarge?.copyWith(fontSize: 19)),
      cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: shape),
      dividerTheme:
          const DividerThemeData(color: AppColors.cardBorder, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorder)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorder)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.8)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error)),
          hintStyle: text.bodyMedium?.copyWith(color: AppColors.textMuted),
          prefixIconColor: AppColors.textSecondary,
          suffixIconColor: AppColors.textSecondary),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: AppColors.primary,
              elevation: 0,
              minimumSize: const Size(48, 52),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: shape,
              textStyle: text.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w700, fontSize: 14))),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
              shape: shape,
              minimumSize: const Size(48, 48),
              textStyle: text.labelLarge)),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
              shape: shape,
              minimumSize: const Size(48, 48),
              textStyle: text.labelLarge)),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
              textStyle:
                  text.labelLarge?.copyWith(fontWeight: FontWeight.w700))),
      chipTheme: ChipThemeData(
          backgroundColor: AppColors.surface,
          selectedColor: AppColors.primaryLight,
          side: BorderSide.none,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          labelStyle: text.labelMedium,
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7)),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: text.labelSmall
              ?.copyWith(fontSize: 10, fontWeight: FontWeight.w700),
          unselectedLabelStyle: text.labelSmall?.copyWith(fontSize: 10)),
      snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: shape,
          backgroundColor: AppColors.secondary,
          contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white)),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2),
    );
  }
}
