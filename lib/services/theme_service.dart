import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  bool _isDarkMode = false;
  static const Duration animationDuration = Duration(milliseconds: 150);

  bool get isDarkMode => _isDarkMode;

  ThemeService() {
    _loadThemeMode();
  }

  // Tema modunu yükle
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themeKey) ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error while loading theme mode: $e');
    }
  }

  // Tema modunu değiştir
  Future<void> toggleTheme() async {
    try {
      _isDarkMode = !_isDarkMode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode);
      notifyListeners();
    } catch (e) {
  debugPrint('Tema modu kaydedilirken hata: $e');
    }
  }

  // Açık tema
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: Colors.red,
      primaryColor: const Color(0xFFE53E3E),
      scaffoldBackgroundColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFE53E3E),
        secondary: Color(0xFFE53E3E),
        surface: Colors.white,
        // background is deprecated; surface covers most usages
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black87,
        outline: Color(0xFFE0E0E0),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFFE53E3E),
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Color(0xFFE53E3E),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.grey.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.black54),
        labelStyle: TextStyle(color: Colors.black87),
        floatingLabelStyle: TextStyle(color: Color(0xFFE53E3E)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE0E0E0), width: 1),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE53E3E), width: 2),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE53E3E),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: Color(0xFFE53E3E)),
        headlineMedium: TextStyle(color: Color(0xFFE53E3E)),
        headlineSmall: TextStyle(color: Color(0xFFE53E3E)),
        bodyLarge: TextStyle(color: Colors.black87),
        bodyMedium: TextStyle(color: Colors.black87),
        bodySmall: TextStyle(color: Colors.black54),
      ),
    );
  }

  // Koyu tema - Profesyonel tasarım
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: Colors.red,
      primaryColor: const Color(0xFFE53E3E),
      scaffoldBackgroundColor: const Color(0xFF0D1117), // GitHub Dark benzeri
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFE53E3E),
        secondary: Color(0xFFFF6B6B), // Daha soft secondary
        surface: Color(0xFF161B22), // Daha profesyonel surface
        // background is deprecated; use surface/scaffold
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFFF0F6FC), // Yüksek kontrast text
        outline: Color(0xFF30363D), // Border renkleri
        // surfaceVariant deprecated; use surfaceContainerHighest in components as needed
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF161B22), // Profesyonel AppBar
        foregroundColor: Color(0xFFF0F6FC), // Beyaz iconlar
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: Color(0xFFF0F6FC), // Beyaz başlık
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(
          color: Color(0xFFF0F6FC), // Beyaz iconlar
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF161B22), // Profesyonel card rengi
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        surfaceTintColor: const Color(0xFF21262D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: Color(0xFF30363D), // Subtle border
            width: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Color(0xFF8B949E)),
        labelStyle: TextStyle(color: Color(0xFFC9D1D9)),
        floatingLabelStyle: TextStyle(color: Color(0xFFE53E3E)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF30363D), width: 1),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE53E3E), width: 2),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE53E3E),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: Color(0xFFE53E3E)),
        headlineMedium: TextStyle(color: Color(0xFFE53E3E)),
        headlineSmall: TextStyle(color: Color(0xFFE53E3E)),
        bodyLarge: TextStyle(color: Color(0xFFF0F6FC)),
        bodyMedium: TextStyle(color: Color(0xFFC9D1D9)),
        bodySmall: TextStyle(color: Color(0xFF8B949E)),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Color(0xFF161B22),
        surfaceTintColor: Color(0xFF21262D),
      ),
      dividerColor: const Color(0xFF30363D),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF161B22),
        surfaceTintColor: Color(0xFF21262D),
      ),
    );
  }
}