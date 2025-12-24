import 'package:flutter/material.dart';

class AppTheme {
  static const _primary = Color(0xFF0B5FFF);
  static const _primaryStrong = Color(0xFF0A2E73);
  static const _background = Color(0xFFF7F9FC);
  static const _surface = Colors.white;
  static const _border = Color(0xFFE5EAF2);
  static const _text = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF475569);

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: _background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primary,
        brightness: Brightness.light,
        primary: _primary,
        secondary: _primaryStrong,
        background: _background,
        surface: _surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _background,
        foregroundColor: _text,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: _surface,
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: _border),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: _text,
        displayColor: _text,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary),
        ),
        hintStyle: const TextStyle(color: _textMuted),
        labelStyle: const TextStyle(color: _textMuted),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: _background,
        selectedColor: _primary.withOpacity(0.12),
        side: const BorderSide(color: _border),
        labelStyle: const TextStyle(color: _text),
      ),
      dividerColor: _border,
    );
  }
}
