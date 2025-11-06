import 'package:flutter/material.dart';

/// Backport for Flutter versions that don't have Color.withValues.
/// We only support the `alpha` parameter since that's all we use.
extension ColorWithValues on Color {
  Color withValues({double? alpha}) {
    final a = alpha ?? opacity;
    return withOpacity(a);
  }
}
