import 'package:flutter/material.dart';

class AppTheme {
  // ── Brand Palette (from Stitch designs)
  static const Color brand = Color(0xFF5C35C2);       // deep purple
  static const Color brandLight = Color(0xFFEDE9FB);  // purple tint bg
  static const Color pageBackground = Color(0xFFF0F0F8); // light blue-grey page bg
  static const Color cardBg = Colors.white;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: pageBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brand,
        brightness: Brightness.light,
        surface: cardBg,
        background: pageBackground,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: pageBackground,
        foregroundColor: Color(0xFF1A1A2E),
        titleTextStyle: TextStyle(
          color: Color(0xFF1A1A2E),
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      cardTheme: CardTheme(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
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
        fillColor: const Color(0xFFF5F5FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: brand, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardBg,
        indicatorColor: brandLight,
        labelTextStyle: MaterialStateProperty.all(
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
