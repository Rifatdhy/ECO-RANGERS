import 'package:flutter/material.dart';

/// Design tokens terinspirasi Apple Human Interface Guidelines:
/// Natural, rapih, modern, clean, dan mewah (Apple Luxury Civic Tech).
/// Menggabungkan palet botani yang tenang (Sage, Emerald, Deep Forest, Warm Alabaster)
/// dengan glassmorphism presisi, radius continuous (squircle-feel), dan hierarki tipografi tajam.
abstract final class AppColors {
  // Latar Belakang & Permukaan (Apple Clean & Warm Alabaster)
  static const background = Color(0xFFF9FAF9); // Warm pure canvas
  static const backgroundSecondary = Color(0xFFF0F3F1);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF4F6F4);
  static const glassSurface = Color(0xCCFFFFFF); // 80% opacity for blur backdrop

  // Teks & Kontras (Apple Dynamic Typography)
  static const ink = Color(0xFF111815);        // Hampir hitam pekat beraksen pine
  static const text = ink;
  static const textSecondary = Color(0xFF55605B);
  static const textMuted = Color(0xFF88958F);
  static const darkTextColor = Color(0xFFF2F5F3);
  static const darkMutedTextColor = Color(0xFF86978F);
  static const line = Color(0xFFE4E9E6);       // Ultra-clean 1px structural line
  static const lineLight = Color(0xFFEDF1EE);

  // Palet Hijau Apple Botani (Luks & Alami)
  static const forest = Color(0xFF0F2B1D);      // Deep luxury evergreen
  static const primary = forest;
  static const emerald = Color(0xFF1B4D36);     // Sophisticated pine
  static const secondary = emerald;
  static const sage = Color(0xFF437A60);        // Calm moss
  static const accent = sage;
  static const mintGlow = Color(0xFFE8F3ED);    // Tinted pill & highlights
  static const jade = Color(0xFF2E8B57);

  // Luxury Gold / Sand Accent (Sentuhan Premium)
  static const sand = Color(0xFFEFE8DD);
  static const clay = Color(0xFFC07A50);
  static const goldAccent = Color(0xFFD4AF37);

  // Status Universal (Harmonis & Elegan)
  static const pendingBg = Color(0xFFFFFBEB);
  static const pendingBorder = Color(0xFFFDE68A);
  static const pendingText = Color(0xFF92400E);

  static const diprosesBg = Color(0xFFEFF6FF);
  static const diprosesBorder = Color(0xFFBFDBFE);
  static const diprosesText = Color(0xFF1E40AF);

  static const selesaiBg = Color(0xFFECFDF5);
  static const selesaiBorder = Color(0xFFA7F3D0);
  static const selesaiText = Color(0xFF065F46);

  static const ditolakBg = Color(0xFFFEF2F2);
  static const ditolakBorder = Color(0xFFFECACA);
  static const ditolakText = Color(0xFF991B1B);

  // System
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);

  // Gradients
  static const luxuryBrandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F2B1D), Color(0xFF1B4D36)],
  );

  static const heroCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF7FAF8)],
  );

  static const glassOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x80FFFFFF), Color(0x33FFFFFF)],
  );
}

abstract final class AppRadius {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 28;
  static const double xxl = 36;
  static const double full = 999;

  static final xsBorderRadius = BorderRadius.circular(xs);
  static final smBorderRadius = BorderRadius.circular(sm);
  static final mdBorderRadius = BorderRadius.circular(md);
  static final lgBorderRadius = BorderRadius.circular(lg);
  static final xlBorderRadius = BorderRadius.circular(xl);
  static final xxlBorderRadius = BorderRadius.circular(xxl);
  static final fullBorderRadius = BorderRadius.circular(full);
}

abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
}

abstract final class AppShadows {
  // Apple Soft Ambient Diffusion Shadows
  static const luxuryCard = [
    BoxShadow(
      color: Color(0x06000000),
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: -4,
    ),
    BoxShadow(
      color: Color(0x040F2B1D),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  static const floatingControl = [
    BoxShadow(
      color: Color(0x180F2B1D),
      blurRadius: 28,
      offset: Offset(0, 12),
      spreadRadius: -2,
    ),
  ];

  static const bottomNav = [
    BoxShadow(
      color: Color(0x08000000),
      blurRadius: 32,
      offset: Offset(0, -8),
    ),
  ];
}
