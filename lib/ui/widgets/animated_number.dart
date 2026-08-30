import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Angka count-up beranimasi (inspirasi: Number Ticker).
///
/// ponytail: TweenAnimationBuilder bawaan Flutter, tidak perlu dependency.
/// Honor `MediaQuery.disableAnimations` (prefers-reduced-motion).
class AnimatedNumber extends StatelessWidget {
  const AnimatedNumber({
    super.key,
    required this.value,
    this.from,
    this.style,
    this.duration = const Duration(milliseconds: 1200),
  });

  final num value;
  final num? from;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final start = (from ?? 0).toDouble();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: start, end: value.toDouble()),
      duration: reduceMotion ? Duration.zero : duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        final isDecimal = value is double && (value % 1) != 0;
        final text = isDecimal
            ? v.toStringAsFixed(1)
            : v.round().toString();
        return Text(text, style: style);
      },
    );
  }
}

/// Panggil di perhitungan untuk membulatkan kembalian nilai (util).
num clampNum(num v, num min, num max) => math.max(min, math.min(max, v));