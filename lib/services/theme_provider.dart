import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark }

enum AppAccentColor { purple, blue, red, green, yellow, skyBlue, black }

class ThemeProvider extends ChangeNotifier {
  static const _modeKey = 'theme_mode';
  static const _accentKey = 'theme_accent';

  AppThemeMode _mode = AppThemeMode.system;
  AppAccentColor _accent = AppAccentColor.purple;

  AppThemeMode get mode => _mode;
  AppAccentColor get accent => _accent;

  bool isDark(BuildContext context) {
    if (_mode == AppThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _mode == AppThemeMode.dark;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    // Load theme mode
    final modeVal = prefs.getString(_modeKey) ?? 'system';
    _mode = AppThemeMode.values.firstWhere(
      (e) => e.name == modeVal,
      orElse: () => AppThemeMode.system,
    );

    // Load accent color
    final accentVal = prefs.getString(_accentKey) ?? 'purple';
    _accent = AppAccentColor.values.firstWhere(
      (e) => e.name == accentVal,
      orElse: () => AppAccentColor.purple,
    );

    notifyListeners();
  }

  Future<void> setMode(AppThemeMode mode) async {
    _mode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode.name);
    notifyListeners();
  }

  Future<void> setAccent(AppAccentColor accent) async {
    _accent = accent;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accentKey, accent.name);
    notifyListeners();
  }
}

// ── Dark palette ──────────────────────────────────────────────────────────────
class DarkColors {
  static const bg = Color(0xFF0F172A); // Deep slate blue background
  static const bg2 = Color(0xFF1E293B);
  static const bg3 = Color(0xFF334155);
  static const card = Color(0xFF1E293B);
  static const card2 = Color(0xFF334155);
  static const textPrimary = Color(0xFFF8FAFC);
  static const textSec = Color(0xFFCBD5E1);
  static const textMuted = Color(0xFF94A3B8);
  static const border = Color(0xFF334155);
  static const danger = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const navBg = Color(0xFF0F172A);
}

// ── Light palette ─────────────────────────────────────────────────────────────
class LightColors {
  static const bg = Color(0xFFF8F9FA); // Soft clean grey/white
  static const bg2 = Color(0xFFE9ECEF);
  static const bg3 = Color(0xFFDEE2E6);
  static const card = Color(0xFFFFFFFF);
  static const card2 = Color(0xFFF8F9FA);
  static const textPrimary = Color(0xFF1E293B);
  static const textSec = Color(0xFF475569);
  static const textMuted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const danger = Color(0xFFDC2626);
  static const warning = Color(0xFFD97706);
  static const navBg = Color(0xFFFFFFFF);
}

// ── Dynamic accessor ──────────────────────────────────────────────────────────
class AppColors {
  final bool dark;
  final AppAccentColor accentType;
  const AppColors(this.dark, [this.accentType = AppAccentColor.purple]);

  Color get bg => dark ? DarkColors.bg : LightColors.bg;
  Color get bg2 => dark ? DarkColors.bg2 : LightColors.bg2;
  Color get bg3 => dark ? DarkColors.bg3 : LightColors.bg3;
  Color get card => dark ? DarkColors.card : LightColors.card;
  Color get card2 => dark ? DarkColors.card2 : LightColors.card2;

  Color get accent {
    switch (accentType) {
      case AppAccentColor.purple:
        return const Color(0xFF8B5CF6);
      case AppAccentColor.blue:
        return const Color(0xFF3B82F6);
      case AppAccentColor.red:
        return const Color(0xFFEF4444);
      case AppAccentColor.green:
        return const Color(0xFF10B981);
      case AppAccentColor.yellow:
        return const Color(0xFFF59E0B);
      case AppAccentColor.skyBlue:
        return const Color(0xFF0EA5E9);
      case AppAccentColor.black:
        // In dark mode, use a visible slate/zinc neutral instead of pure invisible white
        return dark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A);
    }
  }

  Color get accent2 {
    switch (accentType) {
      case AppAccentColor.purple:
        return const Color(0xFFA78BFA);
      case AppAccentColor.blue:
        return const Color(0xFF60A5FA);
      case AppAccentColor.red:
        return const Color(0xFFF87171);
      case AppAccentColor.green:
        return const Color(0xFF34D399);
      case AppAccentColor.yellow:
        return const Color(0xFFFBBF24);
      case AppAccentColor.skyBlue:
        return const Color(0xFF38BDF8);
      case AppAccentColor.black:
        return dark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
    }
  }

  Color get accent3 {
    switch (accentType) {
      case AppAccentColor.purple:
        return const Color(0xFFDDD6FE);
      case AppAccentColor.blue:
        return const Color(0xFFDBEAFE);
      case AppAccentColor.red:
        return const Color(0xFFFEE2E2);
      case AppAccentColor.green:
        return const Color(0xFFD1FAE5);
      case AppAccentColor.yellow:
        return const Color(0xFFFEF3C7);
      case AppAccentColor.skyBlue:
        return const Color(0xFFE0F2FE);
      case AppAccentColor.black:
        return dark ? const Color(0xFF475569) : const Color(0xFF64748B);
    }
  }

  Color get textPrimary =>
      dark ? DarkColors.textPrimary : LightColors.textPrimary;
  Color get textSec => dark ? DarkColors.textSec : LightColors.textSec;
  Color get textMuted => dark ? DarkColors.textMuted : LightColors.textMuted;
  Color get border => dark ? DarkColors.border : LightColors.border;
  Color get danger => dark ? DarkColors.danger : LightColors.danger;
  Color get warning => dark ? DarkColors.warning : LightColors.warning;
  Color get navBg => dark ? DarkColors.navBg : LightColors.navBg;
}

// ── Theme builder ─────────────────────────────────────────────────────────────
ThemeData buildTheme(AppColors c) => ThemeData(
      brightness: c.dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: c.bg,
      colorScheme: ColorScheme(
        brightness: c.dark ? Brightness.dark : Brightness.light,
        primary: c.accent,
        onPrimary: c.accentType == AppAccentColor.black && c.dark
            ? Colors.black
            : Colors.white,
        secondary: c.accent2,
        onSecondary: c.accentType == AppAccentColor.black && c.dark
            ? Colors.black
            : Colors.white,
        surface: c.card,
        onSurface: c.textPrimary,
        error: c.danger,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        foregroundColor: c.textPrimary,
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.navBg,
        selectedItemColor: c.accent,
        unselectedItemColor: c.textMuted,
        elevation: 8,
      ),
      dividerColor: c.border,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.accent, width: 1.5),
        ),
        hintStyle: TextStyle(color: c.textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.accentType == AppAccentColor.black && c.dark
              ? Colors.black
              : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.accent),
      ),
    );
