import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // ─── Color Palette ───────────────────────────────────────────────
  static const Color primaryPurple = Color(0xFF7C6EF8);
  static const Color primaryPurpleLight = Color(0xFF9B8FF9);
  static const Color primaryPurpleDark = Color(0xFF5B4FD4);

  static const Color accentTeal = Color(0xFF00D9C5);
  static const Color accentAmber = Color(0xFFFFB84C);
  static const Color accentRed = Color(0xFFFF6B6B);
  static const Color accentGreen = Color(0xFF4CAF83);

  // Dark theme colors
  static const Color darkBg = Color(0xFF0D0D1A);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkCard = Color(0xFF1E1E35);
  static const Color darkDivider = Color(0xFF2A2A45);
  static const Color darkText = Color(0xFFF0F0FF);
  static const Color darkTextSecondary = Color(0xFF9898B8);

  // Light theme colors
  static const Color lightBg = Color(0xFFF8F7FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF0EEFF);
  static const Color lightText = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6868A0);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryPurple, Color(0xFF5B8FF9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkBgGradient = LinearGradient(
    colors: [darkBg, Color(0xFF12122A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Dark Theme ──────────────────────────────────────────────────
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,
    colorScheme: const ColorScheme.dark(
      primary: primaryPurple,
      secondary: accentTeal,
      tertiary: accentAmber,
      error: accentRed,
      surface: darkSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: darkText,
    ),
    textTheme: _buildTextTheme(darkText, darkTextSecondary),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.poppins(
        color: darkText,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: darkText),
    ),
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: darkDivider, width: 1),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: primaryPurple,
      unselectedItemColor: darkTextSecondary,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryPurple,
      foregroundColor: Colors.white,
      elevation: 8,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: darkDivider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: darkDivider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryPurple, width: 2),
      ),
      hintStyle: GoogleFonts.poppins(color: darkTextSecondary, fontSize: 14),
      labelStyle: GoogleFonts.poppins(color: darkTextSecondary, fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: darkCard,
      selectedColor: primaryPurple.withValues(alpha: 0.3),
      labelStyle: GoogleFonts.poppins(color: darkText, fontSize: 12),
      side: const BorderSide(color: darkDivider),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dividerTheme: const DividerThemeData(
      color: darkDivider,
      thickness: 1,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkCard,
      contentTextStyle: GoogleFonts.poppins(color: darkText),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
  );

  // ─── Light Theme ─────────────────────────────────────────────────
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBg,
    colorScheme: const ColorScheme.light(
      primary: primaryPurple,
      secondary: accentTeal,
      tertiary: accentAmber,
      error: accentRed,
      surface: lightSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: lightText,
    ),
    textTheme: _buildTextTheme(lightText, lightTextSecondary),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.poppins(
        color: lightText,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: lightText),
    ),
    cardTheme: CardThemeData(
      color: lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: primaryPurple.withValues(alpha: 0.15), width: 1),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: lightSurface,
      selectedItemColor: primaryPurple,
      unselectedItemColor: lightTextSecondary,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryPurple,
      foregroundColor: Colors.white,
      elevation: 8,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightCard,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primaryPurple.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primaryPurple.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryPurple, width: 2),
      ),
      hintStyle: GoogleFonts.poppins(color: lightTextSecondary, fontSize: 14),
      labelStyle: GoogleFonts.poppins(color: lightTextSecondary, fontSize: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: lightCard,
      selectedColor: primaryPurple.withValues(alpha: 0.2),
      labelStyle: GoogleFonts.poppins(color: lightText, fontSize: 12),
      side: BorderSide(color: primaryPurple.withValues(alpha: 0.2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dividerTheme: DividerThemeData(
      color: primaryPurple.withValues(alpha: 0.1),
      thickness: 1,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: lightCard,
      contentTextStyle: GoogleFonts.poppins(color: lightText),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
  );

  // ─── Text Theme Builder ───────────────────────────────────────────
  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: GoogleFonts.poppins(color: primary, fontWeight: FontWeight.w700),
      displayMedium: GoogleFonts.poppins(color: primary, fontWeight: FontWeight.w700),
      displaySmall: GoogleFonts.poppins(color: primary, fontWeight: FontWeight.w600),
      headlineLarge: GoogleFonts.poppins(color: primary, fontWeight: FontWeight.w600),
      headlineMedium: GoogleFonts.poppins(color: primary, fontWeight: FontWeight.w600),
      headlineSmall: GoogleFonts.poppins(color: primary, fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.poppins(color: primary, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.poppins(color: primary, fontWeight: FontWeight.w500),
      titleSmall: GoogleFonts.poppins(color: primary, fontWeight: FontWeight.w500),
      bodyLarge: GoogleFonts.poppins(color: primary, fontWeight: FontWeight.w400),
      bodyMedium: GoogleFonts.poppins(color: primary, fontWeight: FontWeight.w400),
      bodySmall: GoogleFonts.poppins(color: secondary, fontWeight: FontWeight.w400),
      labelLarge: GoogleFonts.poppins(color: primary, fontWeight: FontWeight.w600),
      labelMedium: GoogleFonts.poppins(color: secondary, fontWeight: FontWeight.w500),
      labelSmall: GoogleFonts.poppins(color: secondary, fontWeight: FontWeight.w400),
    );
  }
}
