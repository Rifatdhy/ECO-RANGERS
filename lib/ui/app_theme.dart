import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'tokens.dart';

class AppTheme {
  static const Color primaryColor = AppColors.primary;
  static const Color secondaryColor = AppColors.secondary;
  static const Color accentColor = AppColors.accent;

  static const Color lightBackgroundColor = AppColors.background;
  static const Color lightSurfaceColor = AppColors.surface;
  static const Color lightTextColor = AppColors.ink;
  static const Color lightMutedTextColor = AppColors.textMuted;

  static const Color darkBackgroundColor = Color(0xFF0B1410);
  static const Color darkSurfaceColor = Color(0xFF14201A);
  static const Color darkSurfaceAltColor = Color(0xFF1B2A23);
  static const Color darkTextColor = Color(0xFFF2F5F3);
  static const Color darkMutedTextColor = Color(0xFF86978F);

  static TextTheme _getTextTheme(bool isDark) {
    final textColor = isDark ? darkTextColor : lightTextColor;
    final mutedTextColor = isDark ? darkMutedTextColor : lightMutedTextColor;

    return TextTheme(
      displayLarge: TextStyle(
        fontWeight: FontWeight.w800,
        color: textColor,
        fontSize: 38,
        letterSpacing: -1.2,
        height: 1.06,
      ),
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w700,
        color: textColor,
        fontSize: 28,
        letterSpacing: -0.8,
        height: 1.15,
      ),
      headlineSmall: TextStyle(
        fontWeight: FontWeight.w700,
        color: textColor,
        fontSize: 22,
        letterSpacing: -0.5,
      ),
      titleLarge: TextStyle(
        fontWeight: FontWeight.w700,
        color: textColor,
        fontSize: 18,
        letterSpacing: -0.3,
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w600,
        color: textColor,
        fontSize: 15,
        letterSpacing: -0.1,
      ),
      bodyLarge: TextStyle(
        color: textColor,
        fontSize: 15,
        height: 1.45,
        letterSpacing: -0.1,
      ),
      bodyMedium: TextStyle(
        color: mutedTextColor,
        fontSize: 13.5,
        height: 1.45,
      ),
      bodySmall: TextStyle(
        color: mutedTextColor,
        fontSize: 11.5,
        height: 1.35,
      ),
      labelLarge: TextStyle(
        fontWeight: FontWeight.w700,
        color: textColor,
        fontSize: 13.5,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontWeight: FontWeight.w600,
        color: mutedTextColor,
        fontSize: 11.5,
        letterSpacing: 0.2,
      ),
    ).apply(fontFamily: 'Inter');
  }

  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final textTheme = _getTextTheme(isDark);

    final colorScheme = isDark
        ? const ColorScheme.dark(
            primary: Color(0xFF52B788),
            onPrimary: Color(0xFF081C12),
            secondary: Color(0xFF74C69D),
            surface: Color(0xFF14201A),
            surfaceContainerHighest: Color(0xFF1E2E26),
            onSurface: Color(0xFFF2F5F3),
            onSurfaceVariant: Color(0xFF86978F),
            error: AppColors.error,
          )
        : const ColorScheme.light(
            primary: AppColors.forest,
            onPrimary: Colors.white,
            secondary: AppColors.emerald,
            onSecondary: Colors.white,
            surface: AppColors.surface,
            surfaceContainerHighest: AppColors.backgroundSecondary,
            onSurface: AppColors.ink,
            onSurfaceVariant: AppColors.textSecondary,
            error: AppColors.error,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? darkBackgroundColor : AppColors.background,
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? darkBackgroundColor.withValues(alpha: 0.85) : AppColors.background.withValues(alpha: 0.85),
        foregroundColor: isDark ? darkTextColor : lightTextColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: isDark ? darkTextColor : lightTextColor),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? darkSurfaceColor : AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.line,
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? darkSurfaceAltColor : AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.forest, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        hintStyle: TextStyle(
          color: isDark ? darkMutedTextColor : AppColors.textMuted,
          fontSize: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFF52B788) : AppColors.forest,
          foregroundColor: isDark ? const Color(0xFF081C12) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          elevation: 0,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.forest,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
      ),
    );
  }
}
