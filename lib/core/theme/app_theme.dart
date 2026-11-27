import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

final ColorScheme appColorScheme =
    ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.aqua,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      outline: AppColors.outline,
    );

final TextTheme appTextTheme = GoogleFonts.manropeTextTheme().copyWith(
  displayLarge: GoogleFonts.manrope(
    fontSize: 57,
    fontWeight: FontWeight.w700,
    height: 1.12,
    letterSpacing: -1.2,
  ),
  displayMedium: GoogleFonts.manrope(
    fontSize: 45,
    fontWeight: FontWeight.w700,
    height: 1.16,
    letterSpacing: -0.8,
  ),
  displaySmall: GoogleFonts.manrope(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  ),
  headlineLarge: GoogleFonts.manrope(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.4,
  ),
  headlineMedium: GoogleFonts.manrope(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.3,
  ),
  headlineSmall: GoogleFonts.manrope(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.33,
  ),
  titleLarge: GoogleFonts.manrope(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.3,
  ),
  titleMedium: GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.5,
    letterSpacing: 0.1,
  ),
  titleSmall: GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.43,
    letterSpacing: 0.1,
  ),
  bodyLarge: GoogleFonts.manrope(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.2,
  ),
  bodyMedium: GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    letterSpacing: 0.2,
  ),
  bodySmall: GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.3,
  ),
  labelLarge: GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.43,
    letterSpacing: 0.1,
  ),
  labelMedium: GoogleFonts.manrope(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.33,
    letterSpacing: 0.3,
  ),
  labelSmall: GoogleFonts.manrope(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.45,
    letterSpacing: 0.4,
  ),
);

final ThemeData appTheme = ThemeData(
  colorScheme: appColorScheme,
  textTheme: appTextTheme,
  scaffoldBackgroundColor: AppColors.background,
  useMaterial3: true,
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.background,
    foregroundColor: AppColors.onSurface,
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleTextStyle: appTextTheme.titleLarge?.copyWith(
      color: AppColors.onSurface,
    ),
  ),
  cardTheme: CardThemeData(
    color: AppColors.surface,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: AppColors.outline),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppColors.outline,
      disabledForegroundColor: AppColors.onSurfaceVariant,
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      textStyle: appTextTheme.labelLarge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      textStyle: appTextTheme.labelLarge,
      side: const BorderSide(color: AppColors.outline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      minimumSize: const Size(0, 48),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      textStyle: appTextTheme.labelLarge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    labelStyle: appTextTheme.bodyMedium?.copyWith(
      color: AppColors.onSurfaceVariant,
    ),
    hintStyle: appTextTheme.bodyMedium?.copyWith(
      color: AppColors.onSurfaceVariant,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.outline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.outline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.error, width: 2),
    ),
  ),
);
