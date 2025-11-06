import 'package:flutter/material.dart';
import '../services/localization_service.dart';
import 'package:provider/provider.dart';

/// Extension for easy localization access
/// Provides convenient methods for accessing localized strings
extension LocalizationExtension on BuildContext {
  /// Get LocalizationService instance
  LocalizationService get loc => Provider.of<LocalizationService>(this, listen: false);

  /// Get localized string
  String t(String key) => loc.getString(key);

  /// Get localized string with parameters
  String tParams(String key, Map<String, String> params) => loc.getStringWithParams(key, params);
}

/// Extension for String localization
extension StringLocalizationExtension on String {
  /// Translate this string using LocalizationService
  /// Note: This requires a BuildContext, so use with caution
  String translate(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    return loc.getString(this);
  }
}

/// Helper class for common localization patterns
class LocalizationHelper {
  /// Format date with localization
  static String formatDate(BuildContext context, DateTime date) {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    // Use intl package for proper date formatting
    // For now, return simple format
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Format number with localization
  static String formatNumber(BuildContext context, num value, {int decimals = 2}) {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    // Use locale-specific number formatting
    return value.toStringAsFixed(decimals);
  }

  /// Format currency with localization
  static String formatCurrency(BuildContext context, double amount, {String currency = 'TRY'}) {
    final loc = Provider.of<LocalizationService>(context, listen: false);
    // Use locale-specific currency formatting
    return '${amount.toStringAsFixed(2)} $currency';
  }
}
