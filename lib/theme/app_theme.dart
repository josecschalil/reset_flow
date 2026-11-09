import 'package:flutter/material.dart';

class AppTheme {
  // ── Cash requirements palette
  static const Color brand = Color(0xFF1E3A5F);
  static const Color brandLight = Color(0xFFEEF2F7);
  static const Color pageBackground = Color(0xFFF5F6F8);
  static const Color cardBg = Colors.white;
  static const Color ink = Color(0xFF14202E);
  static const Color muted = Color(0xFF5F6B7A);
  static const Color line = Color(0xFFDFE3E9);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: pageBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brand,
        brightness: Brightness.light,
        surface: cardBg,
        background: pageBackground,
      ).copyWith(
        onSurface: ink,
        onSurfaceVariant: muted,
        outline: line,
        outlineVariant: line,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: pageBackground,
        foregroundColor: ink,
        titleTextStyle: TextStyle(
          color: ink,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brand,
          side: const BorderSide(color: brand),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return brand;
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8F9FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: brand, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardBg,
        indicatorColor: brandLight,
        iconTheme: MaterialStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(MaterialState.selected) ? brand : muted,
          );
        }),
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(MaterialState.selected) ? brand : muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          );
        }),
      ),
    );
  }
}
