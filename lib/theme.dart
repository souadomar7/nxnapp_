import 'package:flutter/material.dart';

/// NXN Hub Design System — Minimalist Navy Blue Palette
class AppColors {
  // Primary palette
  static const bluePrimary  = Color(0xFF003C8E); // Deep navy — buttons, active states
  static const blueMid      = Color(0xFF3D73BC); // Mid navy — icons, borders, accents
  static const blueLight    = Color(0xFFA6BFE2); // Pale blue — chips, inactive, muted
  static const blueGlow     = Color(0xFFDEEAF8); // Lightest blue — hover tints, backgrounds

  // Surface & background
  static const bg           = Color(0xFFF4F6FA); // Scaffold background
  static const surface      = Colors.white;       // Card surfaces

  // Text
  static const textPrimary  = Color(0xFF0D1B36); // Headings
  static const textSecondary= Color(0xFF6B7C99); // Subtitles / captions

  // Borders & dividers
  static const border       = Color(0xFFE4EAF4);

  // Status — used sparingly
  static const success      = Color(0xFF1A9E6C); // Paid / Verified
  static const error        = Color(0xFFC0392B); // Failed / Error
  static const warning      = Color(0xFFD97706); // Pending / Warning

  // Legacy aliases kept for backward compat
  static const bluePrimaryLegacy = bluePrimary;
  static const blueSecondary     = blueMid;
  static const orangeAccent      = warning;
  static const greenSuccess      = success;
}

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.bg,
  primaryColor: AppColors.bluePrimary,
  colorScheme: const ColorScheme.light(
    primary: AppColors.bluePrimary,
    secondary: AppColors.blueMid,
    surface: AppColors.surface,
    error: AppColors.error,
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.bluePrimary,
    foregroundColor: Colors.white,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      letterSpacing: -0.2,
    ),
  ),

  textTheme: const TextTheme(
    titleLarge : TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.4),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: -0.2),
    bodyMedium : TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
    bodySmall  : TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
    labelLarge : TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
  ),

  cardTheme: CardThemeData(
    color: AppColors.surface,
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      side: BorderSide(color: AppColors.border, width: 1),
    ),
    shadowColor: const Color(0xFF003C8E).withValues(alpha: 0.06),
    surfaceTintColor: Colors.transparent,
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.bluePrimary, width: 1.5),
    ),
    labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
    hintStyle: const TextStyle(color: AppColors.blueLight, fontSize: 14),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.bluePrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.1),
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.bluePrimary,
      side: const BorderSide(color: AppColors.bluePrimary, width: 1.5),
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    ),
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.bluePrimary,
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    ),
  ),

  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.bluePrimary,
    foregroundColor: Colors.white,
    elevation: 3,
    shape: CircleBorder(),
  ),

  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: AppColors.bluePrimary,
    unselectedItemColor: AppColors.blueLight,
    showUnselectedLabels: true,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
    selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
    unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
  ),

  dividerTheme: const DividerThemeData(
    color: AppColors.border,
    thickness: 1,
    space: 1,
  ),

  chipTheme: ChipThemeData(
    backgroundColor: AppColors.blueGlow,
    labelStyle: const TextStyle(color: AppColors.bluePrimary, fontWeight: FontWeight.w600, fontSize: 12),
    side: BorderSide.none,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  ),
);

final ThemeData darkAppTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF0F172A),
  primaryColor: const Color(0xFF3B82F6),
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF3B82F6),
    secondary: Color(0xFF60A5FA),
    surface: Color(0xFF1E293B),
    error: Color(0xFFEF4444),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0F172A),
    foregroundColor: Colors.white,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  cardTheme: const CardThemeData(
    color: Color(0xFF1E293B),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      side: BorderSide(color: Color(0xFF334155), width: 1),
    ),
  ),
);
