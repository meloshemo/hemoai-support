import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'localization_provider.g.dart';

@riverpod
class Locale extends _$Locale {
  @override
  Locale build() {
    _loadLocale();
    return const Locale('en', 'US');
  }

  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('language_code') ?? 'en';
      final countryCode = prefs.getString('country_code') ?? 'US';
      state = Locale(languageCode, countryCode);
    } catch (e) {
      // Use default locale as fallback
      state = const Locale('en', 'US');
    }
  }

  Future<void> setLocale(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language_code', locale.languageCode);
      await prefs.setString('country_code', locale.countryCode ?? '');
      state = locale;
    } catch (e) {
      // Handle error silently
    }
  }
}

// Convenience provider for locale
final localeProvider = localeProvider;
