import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Define available themes
enum AppThemeMode { calmGreen, focusBlue, sunsetOrange }

class AppTheme {
  // Theme 1: Calm Green (Default - Nature)
  static final ThemeData calmGreen = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFA8E6CF),
      primary: const Color(0xFF66BB6A),
      secondary: const Color(0xFF81C784),
      surface: const Color(0xFFF5F9F6),
      background: const Color(0xFFF5F9F6),
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F9F6),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFA8E6CF),
      foregroundColor: Color(0xFF1B5E20),
      elevation: 0,
    ),
  );

  // Theme 2: Focus Blue (Productivity)
  static final ThemeData focusBlue = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF90CAF9),
      primary: const Color(0xFF1976D2),
      secondary: const Color(0xFF64B5F6),
      surface: const Color(0xFFE3F2FD),
      background: const Color(0xFFE3F2FD),
    ),
    scaffoldBackgroundColor: const Color(0xFFE3F2FD),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF90CAF9),
      foregroundColor: Color(0xFF0D47A1),
      elevation: 0,
    ),
  );

  // Theme 3: Sunset Orange (Warmth/Energy - from Assignment)
  static final ThemeData sunsetOrange = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFFFCC80),
      primary: const Color(0xFFF57C00),
      secondary: const Color(0xFFFFB74D),
      surface: const Color(0xFFFFF3E0),
      background: const Color(0xFFFFF3E0),
    ),
    scaffoldBackgroundColor: const Color(0xFFFFF3E0),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFCC80),
      foregroundColor: Color(0xFFE65100),
      elevation: 0,
    ),
  );
}

// Controller to manage theme state
class ThemeController extends StateNotifier<AppThemeMode> {
  ThemeController() : super(AppThemeMode.calmGreen) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('theme_mode');
    if (savedTheme != null) {
      state = AppThemeMode.values.firstWhere(
        (e) => e.toString() == savedTheme,
        orElse: () => AppThemeMode.calmGreen,
      );
    }
  }

  Future<void> setTheme(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.toString());
  }
}

final themeControllerProvider =
    StateNotifierProvider<ThemeController, AppThemeMode>((ref) {
      return ThemeController();
    });
