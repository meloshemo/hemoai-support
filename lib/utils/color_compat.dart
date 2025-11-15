import 'package:flutter/material.dart';

/// Backport for Flutter versions that don't have Color.withValues.
/// We only support the `alpha` parameter since that's all we use.
extension ColorWithValues on Color {
  Color withValues({double? alpha}) {
    final currentAlpha = alpha ?? a;
    final clamped = currentAlpha.clamp(0.0, 1.0);
    return withAlpha((clamped * 255).round());
  }
}
