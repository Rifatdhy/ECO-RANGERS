import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- PALET WARNA TERANG ---
  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color secondaryColor = Color(0xFF66BB6A);
  static const Color accentColor = Color(0xFFFFA000);
  static const Color lightBackgroundColor = Color(0xFFF5F5F5);
  static const Color lightSurfaceColor = Colors.white;
  static const Color lightTextColor = Color(0xFF333333);
  static const Color lightMutedTextColor = Color(0xFF757575);

  // --- PALET WARNA GELAP ---
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);
  static const Color darkTextColor = Colors.white70;
  static const Color darkMutedTextColor = Colors.white54;

  // --- FUNGSI TIPOGRAFI UNIVERSAL ---
  static TextTheme _getTextTheme(bool isDark) {
    final textColor = isDark ? darkTextColor : lightTextColor;
    final mutedTextColor = isDark ? darkMutedTextColor : lightMutedTextColor;
    return GoogleFonts.latoTextTheme(TextTheme(
      headlineMedium: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 28),
      titleLarge: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 20),
      titleMedium: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 18),
      bodyLarge: TextStyle(color: textColor, fontSize: 16),
      bodyMedium: TextStyle(color: mutedTextColor, fontSize: 14),
      bodySmall: TextStyle(color: mutedTextColor, fontSize: 12),
      labelLarge: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
    ));
  }

  // --- TEMA TERANG ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: lightBackgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        background: lightBackgroundColor,
        surface: lightSurfaceColor,
        brightness: Brightness.light,
      ),
      textTheme: _getTextTheme(false),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: _getTextTheme(false).titleLarge?.copyWith(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color: lightSurfaceColor,
      ),
      inputDecorationTheme: _inputDecorationTheme(false),
      elevatedButtonTheme: _elevatedButtonTheme(false),
    );
  }

  // --- TEMA GELAP ---
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBackgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: secondaryColor, // Hijau terang lebih baik di tema gelap
        secondary: secondaryColor,
        background: darkBackgroundColor,
        surface: darkSurfaceColor,
        brightness: Brightness.dark,
      ),
      textTheme: _getTextTheme(true),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurfaceColor,
        foregroundColor: darkTextColor,
        elevation: 0,
        titleTextStyle: _getTextTheme(true).titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color: darkSurfaceColor,
      ),
      inputDecorationTheme: _inputDecorationTheme(true),
      elevatedButtonTheme: _elevatedButtonTheme(true),
      // FIX: Menggunakan TabBarThemeData
      tabBarTheme: const TabBarThemeData(
        labelColor: secondaryColor,
        unselectedLabelColor: darkMutedTextColor,
        indicator: UnderlineTabIndicator(borderSide: BorderSide(color: secondaryColor, width: 2)),
      ),
    );
  }

  // -- KOMPONEN THEME HELPER --
  static InputDecorationTheme _inputDecorationTheme(bool isDark) {
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? darkSurfaceColor.withOpacity(0.5) : lightSurfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      labelStyle: TextStyle(color: isDark ? darkMutedTextColor : lightMutedTextColor),
      prefixIconColor: isDark ? darkMutedTextColor : lightMutedTextColor,
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(bool isDark) {
    return ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      textStyle: _getTextTheme(isDark).labelLarge,
      minimumSize: const Size(double.infinity, 54),
    ));
  }
}
