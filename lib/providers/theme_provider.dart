import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Semantic color getters matching website design system
  Color get bg => isDarkMode ? const Color(0xFF0B1326) : const Color(0xFFF8F9FF);
  Color get surface => isDarkMode ? const Color(0xFF131B2E) : const Color(0xFFFFFFFF);
  Color get surfaceContainer => isDarkMode ? const Color(0xFF171F33) : const Color(0xFFEFF4FF);
  Color get surfaceContainerHigh => isDarkMode ? const Color(0xFF222A3D) : const Color(0xFFE2E8F0);
  Color get primary => isDarkMode ? const Color(0xFF8083FF) : const Color(0xFF4648D4);
  Color get primaryLight => isDarkMode ? const Color(0xFFC0C1FF) : const Color(0xFF4648D4);
  Color get textPrimary => isDarkMode ? const Color(0xFFDAE2FD) : const Color(0xFF0D1C2E);
  Color get textSecondary => isDarkMode ? const Color(0xFF908FA0) : const Color(0xFF64748B);
  Color get border => isDarkMode ? Colors.white10 : const Color(0xFFE2E8F0);
  Color get divider => isDarkMode ? Colors.white10 : const Color(0xFFE2E8F0);
  Color get cardBorder => isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);
  Color get circleBtnBg => isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05);
  Color get circleBtnBorder => isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1);

  ThemeProvider() {
    loadTheme();
  }

  Future<void> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool('is_dark_mode') ?? true;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_dark_mode', _themeMode == ThemeMode.dark);
    } catch (_) {}
  }

  ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B1326),
      canvasColor: const Color(0xFF0B1326),
      cardColor: const Color(0xFF171F33),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF8083FF),
        secondary: Color(0xFF4EDEA3),
        tertiary: Color(0xFFFFB783),
        surface: Color(0xFF131B2E),
        onSurface: Color(0xFFDAE2FD),
      ),
      useMaterial3: true,
    );
  }

  ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8F9FF),
      canvasColor: const Color(0xFFF8F9FF),
      cardColor: const Color(0xFFFFFFFF),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF4648D4),
        secondary: Color(0xFF00A572),
        tertiary: Color(0xFFD97721),
        surface: Color(0xFFEFF4FF),
        onSurface: Color(0xFF0D1C2E),
      ),
      useMaterial3: true,
    );
  }
}
