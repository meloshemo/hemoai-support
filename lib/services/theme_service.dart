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
    // Modern, vibrant theme inspired by popular health apps (Apple Health, Fitbit style)
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: Colors.red,
      // Vibrant primary color (like Apple Health, modern apps)
      primaryColor: const Color(0xFFE53E3E), // Vibrant red
      scaffoldBackgroundColor: Colors.white, // Pure white like modern apps
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFE53E3E), // Vibrant red
        secondary: Color(0xFFFF6B6B), // Bright secondary
        surface: Color(0xFFFFFFFF), // Pure white for cards
        surfaceContainerHighest: Color(0xFFF5F5F5), // Subtle variation
        // background is deprecated; surface covers most usages
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black87, // Strong black text (modern apps)
        outline: Color(0xFFE0E0E0), // Clean border
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFE53E3E), // Vibrant app bar
        foregroundColor: Colors.white, // White icons/text
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 650),
        textStyle: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.all(Radius.circular(6))),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(48, 48)),
          iconSize: WidgetStateProperty.all(24),
          padding: WidgetStateProperty.all(const EdgeInsets.all(12)),
          alignment: Alignment.center,
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
        hintStyle: TextStyle(color: Colors.black54), // Modern hint
        labelStyle: TextStyle(color: Colors.black87), // Modern label
        floatingLabelStyle: TextStyle(color: Color(0xFFE53E3E)), // Vibrant primary
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFBDBDBD), width: 1), // Clean border
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE53E3E), width: 2), // Vibrant primary
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE53E3E), // Vibrant primary
          foregroundColor: Colors.white,
          // Avoid infinite width in unconstrained layouts (Row/Wrap)
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.2),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: Color(0xFFE53E3E)), // Vibrant headings
        headlineMedium: TextStyle(color: Color(0xFFE53E3E)),
        headlineSmall: TextStyle(color: Color(0xFFE53E3E)),
        bodyLarge: TextStyle(color: Colors.black87), // Strong text
        bodyMedium: TextStyle(color: Colors.black87),
        bodySmall: TextStyle(color: Colors.black54), // Modern small text
      ),
      checkboxTheme: CheckboxThemeData(
        side: const BorderSide(width: 2, color: Color(0xFF616161)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      switchTheme: const SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(Color(0xFFE53E3E)), // Vibrant
        trackColor: WidgetStatePropertyAll(Color(0xFFFFCDD2)),
      ),
      // Fast, smooth page transitions for better UX
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  // Koyu tema - Modern ve parlak
  static ThemeData get darkTheme {
    // Modern dark theme with vibrant accents (like Spotify, TikTok)
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: Colors.red,
      primaryColor: const Color(0xFFE53E3E), // Vibrant red for dark mode
      scaffoldBackgroundColor: const Color(0xFF0D1117), // Deep dark (GitHub style)
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFE53E3E), // Vibrant red
        secondary: Color(0xFFFF6B6B), // Bright secondary
        surface: Color(0xFF161B22), // Modern dark surface
        surfaceContainerHighest: Color(0xFF21262D), // Subtle variation
        // background is deprecated; use surface/scaffold
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFFF0F6FC), // Bright white text (modern apps)
        outline: Color(0xFF30363D), // Clean border
        // surfaceVariant deprecated; use surfaceContainerHighest in components as needed
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF161B22), // Modern dark AppBar
        foregroundColor: Color(0xFFF0F6FC), // Bright white
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: Color(0xFFF0F6FC), // Bright white
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(
          color: Color(0xFFF0F6FC), // Bright white
        ),
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 650),
        textStyle: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w600),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(6))),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStateProperty.all(const Size(48, 48)),
          iconSize: WidgetStateProperty.all(24),
          padding: WidgetStateProperty.all(const EdgeInsets.all(12)),
          alignment: Alignment.center,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF161B22), // Modern dark
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.4), // Modern shadow
        surfaceTintColor: const Color(0xFF21262D), // Modern tint
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: Color(0xFF30363D), // Clean border
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
          // Avoid infinite width in unconstrained layouts (Row/Wrap)
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.2),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: Color(0xFFE53E3E)), // Vibrant headings
        headlineMedium: TextStyle(color: Color(0xFFE53E3E)),
        headlineSmall: TextStyle(color: Color(0xFFE53E3E)),
        bodyLarge: TextStyle(color: Color(0xFFF0F6FC)), // Bright text
        bodyMedium: TextStyle(color: Color(0xFFC9D1D9)), // Modern medium
        bodySmall: TextStyle(color: Color(0xFF8B949E)), // Modern small
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
      checkboxTheme: CheckboxThemeData(
        side: const BorderSide(width: 2, color: Color(0xFF8B949E)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      switchTheme: const SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(Color(0xFFE53E3E)), // Vibrant
        trackColor: WidgetStatePropertyAll(Color(0xFFB91C1C)), // Modern track
      ),
      // Ultra-fast, smooth page transitions (reduced duration)
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}