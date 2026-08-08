import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'tokens.dart';

class AppTheme {
  static const Color primaryColor = AppColors.primary;
  static const Color secondaryColor = AppColors.secondary;
  static const Color accentColor = AppColors.accent;

  static const Color lightBackgroundColor = AppColors.background;
  static const Color lightSurfaceColor = AppColors.surface;
  static const Color lightSurfaceAltColor = Color(0xFFF2F2F7);
  static const Color lightTextColor = AppColors.text;
  static const Color lightMutedTextColor = AppColors.textMuted;

  static const Color darkBackgroundColor = Color(0xFF000000); // iOS black
  static const Color darkSurfaceColor = Color(0xFF1C1C1E); // iOS secondary system bg
  static const Color darkSurfaceAltColor = Color(0xFF2C2C2E);
  static const Color darkTextColor = Color(0xFFFFFFFF);
  static const Color darkMutedTextColor = Color(0xFF8E8E93); // iOS secondary label

  static TextTheme _getTextTheme(bool isDark) {
    final textColor = isDark ? darkTextColor : lightTextColor;
    final mutedTextColor = isDark ? darkMutedTextColor : lightMutedTextColor;

    // Font Inter dipakai langsung via asset lokal (tanpa fetch runtime).
    return TextTheme(
        displayLarge: TextStyle(
          fontWeight: FontWeight.w800,
          color: textColor,
          fontSize: 40,
          letterSpacing: -1.1,
          height: 1.05,
        ),
        headlineMedium: TextStyle(
          fontWeight: FontWeight.w800,
          color: textColor,
          fontSize: 28,
          letterSpacing: -0.7,
          height: 1.1,
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
          fontSize: 16,
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
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontWeight: FontWeight.w600,
          color: mutedTextColor,
          fontSize: 12,
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
            primary: Color(0xFF34C759), // iOS system green
            onPrimary: Color(0xFF00230B),
            secondary: AppColors.secondary,
            tertiary: AppColors.warning,
            surface: Color(0xFF1C1C1E),
            surfaceContainerHighest: Color(0xFF2C2C2E),
            onSurface: Color(0xFFFFFFFF),
            onSurfaceVariant: Color(0xFF8E8E93),
            error: AppColors.error,
          )
        : const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.onPrimary,
            secondary: AppColors.secondary,
            onSecondary: AppColors.onPrimary,
            tertiary: AppColors.accent,
            surface: AppColors.surface,
            surfaceContainerHighest: Color(0xFFE9E9EB),
            onSurface: AppColors.text,
            onSurfaceVariant: Color(0xFF8E8E93),
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
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: isDark ? darkTextColor : lightTextColor,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: isDark ? darkTextColor : lightTextColor),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? darkSurfaceAltColor : AppColors.text,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        behavior: SnackBarBehavior.floating,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? darkSurfaceColor : AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: _inputDecorationTheme(isDark),
      elevatedButtonTheme: _elevatedButtonTheme(isDark),
      filledButtonTheme: _filledButtonTheme(isDark),
      outlinedButtonTheme: _outlinedButtonTheme(isDark),
      chipTheme: _chipTheme(isDark),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: (isDark ? darkSurfaceColor : AppColors.surface).withValues(alpha: 0.9),
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
        height: 74,
        indicatorColor: (isDark ? AppColors.accent : AppColors.primary).withValues(alpha: 0.18),
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            color: selected ? (isDark ? AppColors.accent : AppColors.primary) : (isDark ? darkMutedTextColor : lightMutedTextColor),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: selected ? 26 : 24,
            color: selected ? (isDark ? AppColors.accent : AppColors.primary) : (isDark ? darkMutedTextColor : lightMutedTextColor),
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: AppElevation.lg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: lightMutedTextColor,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      dividerTheme: DividerThemeData(
        color: (isDark ? darkMutedTextColor : lightMutedTextColor).withValues(alpha: 0.18),
        space: 1,
        thickness: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(bool isDark) {
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? darkSurfaceAltColor : lightSurfaceAltColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: BorderSide(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.07),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: const BorderSide(color: AppColors.error, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: const BorderSide(color: AppColors.error, width: 1.8),
      ),
      labelStyle: TextStyle(color: isDark ? darkMutedTextColor : lightMutedTextColor),
      hintStyle: TextStyle(color: isDark ? darkMutedTextColor : lightMutedTextColor),
      prefixIconColor: isDark ? darkMutedTextColor : lightMutedTextColor,
      suffixIconColor: isDark ? darkMutedTextColor : lightMutedTextColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(bool isDark) {
    final bg = isDark ? AppColors.accent : AppColors.primary;
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: isDark ? const Color(0xFF123018) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.xl),
        textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 15, height: 1.0),
        minimumSize: const Size(double.infinity, 52),
        elevation: 0,
      ),
    );
  }

  static FilledButtonThemeData _filledButtonTheme(bool isDark) {
    final bg = isDark ? AppColors.accent : AppColors.primary;
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: isDark ? const Color(0xFF123018) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.xl),
        textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 15, height: 1.0),
        minimumSize: const Size(double.infinity, 52),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme(bool isDark) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.xl),
        textStyle: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 15, height: 1.0),
      ),
    );
  }

  static ChipThemeData _chipTheme(bool isDark) {
    return ChipThemeData(
      backgroundColor: isDark ? darkSurfaceAltColor : lightSurfaceAltColor,
      selectedColor: AppColors.accent.withValues(alpha: 0.24),
      labelStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? darkTextColor : lightTextColor,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide(
        color: (isDark ? darkMutedTextColor : AppColors.primary).withValues(alpha: 0.15),
      ),
    );
  }
}