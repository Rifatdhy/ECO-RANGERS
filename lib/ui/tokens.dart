import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFFF2F2F7); // iOS grouped background (light)
  static const primary = Color(0xFF2E7D32);
  static const secondary = Color(0xFF43A047);
  static const accent = Color(0xFF81C784);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF1C1C1E); // iOS label primary
  static const textMuted = Color(0xFF3C3C43); // iOS secondary label
  static const success = Color(0xFF34C759); // iOS system green
  static const warning = Color(0xFFFF9500); // iOS system orange
  static const error = Color(0xFFFF3B30); // iOS system red
  static const onPrimary = Color(0xFFFFFFFF);
}

abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 40.0;
  static const huge = 48.0;
}

abstract final class AppRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
}

abstract final class AppElevation {
  static const none = 0.0;
  static const sm = 1.0;
  static const md = 3.0;
  static const lg = 8.0;
}

abstract final class AppShadows {
  static const card = [
    BoxShadow(
      color: Color(0x0A1B1B1B),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
  static const sheet = [
    BoxShadow(
      color: Color(0x141B1B1B),
      blurRadius: 32,
      offset: Offset(0, 8),
    ),
  ];
}

