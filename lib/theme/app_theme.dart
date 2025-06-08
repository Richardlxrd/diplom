import 'package:flutter/material.dart';

class AppTheme {
  static const Color _goldenApplePrimary = Color(0xFFF8D568); // Золотистый
  static const Color _goldenAppleSecondary = Color(0xFFE5B844); // Темно-золотой
  static const Color _goldenAppleDark = Color(0xFF2C2723); // Темно-коричневый
  static const Color _goldenAppleLight = Color(
    0xFFF9F5E9,
  ); // Кремовый// Акцентный золотой

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: _goldenApplePrimary,
        secondary: _goldenAppleSecondary,
        surface: _goldenAppleLight,
        onPrimary: _goldenAppleDark,
        onSecondary: _goldenAppleDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: _goldenApplePrimary,
        titleTextStyle: TextStyle(
          color: Color.fromARGB(255, 48, 230, 3),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: _goldenAppleDark),
        elevation: 2,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: _goldenApplePrimary,
        textTheme: ButtonTextTheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _goldenApplePrimary,
          foregroundColor: _goldenAppleDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
