import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// NXN Hub Design System Tokens
class NXNColors {
  static const deepNavy    = Color(0xFF003C8E); // Primary dark / header
  static const cobalt      = Color(0xFF1E50FF); // Active action / interactive
  static const skyBlue     = Color(0xFF38BDF8); // Glow / accents
  static const paleBlue    = Color(0xFFA6BFE2); // Inactive / chips
  static const blueGlow    = Color(0xFFDEEAF8); // Soft surface tint
  static const slateBg     = Color(0xFFF4F6FA); // Scaffold bg
  static const cardSurface = Colors.white;
  static const border      = Color(0xFFE4EAF4);
  
  // Status tokens
  static const success     = Color(0xFF1A9E6C);
  static const warning     = Color(0xFFD97706);
  static const error       = Color(0xFFC0392B);
  
  // Text tokens
  static const textPrimary   = Color(0xFF0D1B36);
  static const textSecondary = Color(0xFF6B7C99);
}

class NXNSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class NXNShadows {
  static final soft = [
    BoxShadow(
      color: const Color(0xFF003C8E).withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  static final elevated = [
    BoxShadow(
      color: const Color(0xFF003C8E).withValues(alpha: 0.12),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}

/// AppColors compatibility layer
class AppColors {
  // Primary palette
  static const bluePrimary  = NXNColors.deepNavy;
  static const blueMid      = Color(0xFF3D73BC);
  static const blueLight    = NXNColors.paleBlue;
  static const blueGlow     = NXNColors.blueGlow;

  // Surface & background
  static const bg           = NXNColors.slateBg;
  static const surface      = NXNColors.cardSurface;

  // Text
  static const textPrimary  = NXNColors.textPrimary;
  static const textSecondary= NXNColors.textSecondary;

  // Borders & dividers
  static const border       = NXNColors.border;

  // Status
  static const success      = NXNColors.success;
  static const error        = NXNColors.error;
  static const warning      = NXNColors.warning;

  // Legacy aliases
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
      height: 1.3,
    ),
  ),

  textTheme: GoogleFonts.cairoTextTheme(ThemeData.light().textTheme).copyWith(
    titleLarge : const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.4, height: 1.4),
    titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: -0.2, height: 1.35),
    bodyLarge  : const TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.45),
    bodyMedium : const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.4),
    bodySmall  : const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.35),
    labelLarge : const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.3),
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
