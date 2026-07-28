import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFFE5E7EB);
  static const Color secondaryColor = Color(0xFF9CA3AF);
  static const Color accentColor = Color(0xFFF59E0B);

  static const Color lightBackgroundColor = Color(0xFFF4F5F7);
  static const Color lightSurfaceColor = Color(0xFFFFFFFF);
  static const Color lightSurfaceAltColor = Color(0xFFF1F2F4);
  static const Color lightTextColor = Color(0xFF111827);
  static const Color lightMutedTextColor = Color(0xFF6B7280);

  static const Color darkBackgroundColor = Color(0xFF0B0D10);
  static const Color darkSurfaceColor = Color(0xFF13161B);
  static const Color darkSurfaceAltColor = Color(0xFF1A1E24);
  static const Color darkTextColor = Color(0xFFF3F4F6);
  static const Color darkMutedTextColor = Color(0xFF9CA3AF);

  static const Color industrialBlack = Color(0xFF050608);
  static const Color industrialCharcoal = Color(0xFF161A21);
  static const Color industrialSteel = Color(0xFF2A2F39);
  static const Color industrialSilver = Color(0xFFD1D5DB);

  static TextTheme _getTextTheme(bool isDark) {
    final textColor = isDark ? darkTextColor : lightTextColor;
    final mutedTextColor = isDark ? darkMutedTextColor : lightMutedTextColor;

    return GoogleFonts.interTextTheme(
      TextTheme(
        displayLarge: TextStyle(
          fontWeight: FontWeight.w800,
          color: textColor,
          fontSize: 44,
          letterSpacing: -1.2,
          height: 1.0,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w800,
          color: textColor,
          fontSize: 30,
          letterSpacing: -0.8,
          height: 1.06,
        ),
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w700,
          color: textColor,
          fontSize: 24,
          letterSpacing: -0.4,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w700,
          color: textColor,
          fontSize: 20,
          letterSpacing: -0.2,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w600,
          color: textColor,
          fontSize: 17,
        ),
        bodyLarge: TextStyle(
          color: textColor,
          fontSize: 16,
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          color: mutedTextColor,
          fontSize: 14,
          height: 1.45,
        ),
        bodySmall: TextStyle(
          color: mutedTextColor,
          fontSize: 12,
          height: 1.35,
        ),
        labelLarge: TextStyle(
          fontWeight: FontWeight.w700,
          color: textColor,
          fontSize: 14,
          letterSpacing: 0.15,
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    final textTheme = _getTextTheme(false);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: industrialBlack,
      scaffoldBackgroundColor: lightBackgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: industrialBlack,
        primary: industrialBlack,
        secondary: industrialSteel,
        tertiary: accentColor,
        surface: lightSurfaceColor,
        surfaceContainerHighest: lightSurfaceAltColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightTextColor,
        brightness: Brightness.light,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: lightTextColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: industrialBlack,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: lightSurfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      inputDecorationTheme: _inputDecorationTheme(false),
      elevatedButtonTheme: _elevatedButtonTheme(false),
      filledButtonTheme: _filledButtonTheme(false),
      outlinedButtonTheme: _outlinedButtonTheme(false),
      chipTheme: _chipTheme(false),
      tabBarTheme: TabBarThemeData(
        labelColor: industrialBlack,
        unselectedLabelColor: lightMutedTextColor,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: industrialBlack,
          borderRadius: BorderRadius.circular(999),
        ),
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  static ThemeData get darkTheme {
    final textTheme = _getTextTheme(true);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: industrialSilver,
      scaffoldBackgroundColor: darkBackgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: industrialSilver,
        primary: industrialSilver,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: darkSurfaceColor,
        surfaceContainerHighest: darkSurfaceAltColor,
        onPrimary: industrialBlack,
        onSecondary: Colors.white,
        onSurface: darkTextColor,
        brightness: Brightness.dark,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: darkTextColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkSurfaceAltColor,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: darkTextColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: darkSurfaceColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      inputDecorationTheme: _inputDecorationTheme(true),
      elevatedButtonTheme: _elevatedButtonTheme(true),
      filledButtonTheme: _filledButtonTheme(true),
      outlinedButtonTheme: _outlinedButtonTheme(true),
      chipTheme: _chipTheme(true),
      tabBarTheme: TabBarThemeData(
        labelColor: industrialSilver,
        unselectedLabelColor: darkMutedTextColor,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: industrialSilver.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
        ),
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(bool isDark) {
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? darkSurfaceAltColor : lightSurfaceAltColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: industrialBlack, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
      ),
      labelStyle: TextStyle(color: isDark ? darkMutedTextColor : lightMutedTextColor),
      hintStyle: TextStyle(color: isDark ? darkMutedTextColor : lightMutedTextColor),
      prefixIconColor: isDark ? darkMutedTextColor : lightMutedTextColor,
      suffixIconColor: isDark ? darkMutedTextColor : lightMutedTextColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(bool isDark) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? industrialSilver : industrialBlack,
        foregroundColor: isDark ? industrialBlack : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          letterSpacing: 0.15,
        ),
        minimumSize: const Size(double.infinity, 54),
        elevation: 0,
      ),
    );
  }

  static FilledButtonThemeData _filledButtonTheme(bool isDark) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: isDark ? industrialSilver : industrialBlack,
        foregroundColor: isDark ? industrialBlack : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          letterSpacing: 0.15,
        ),
        minimumSize: const Size(double.infinity, 54),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme(bool isDark) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? darkTextColor : lightTextColor,
        side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.14) : Colors.black.withValues(alpha: 0.12)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }

  static ChipThemeData _chipTheme(bool isDark) {
    return ChipThemeData(
      backgroundColor: isDark ? darkSurfaceAltColor : lightSurfaceAltColor,
      selectedColor: isDark ? industrialSilver.withValues(alpha: 0.18) : industrialBlack.withValues(alpha: 0.08),
      labelStyle: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? darkTextColor : lightTextColor,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08)),
    );
  }
}