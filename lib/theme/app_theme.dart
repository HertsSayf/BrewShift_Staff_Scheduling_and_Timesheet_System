import 'package:flutter/material.dart';

/// Central theme definition so the page files stay focused on behaviour.

class BrewShiftTheme {
  BrewShiftTheme._();

  static const Color navy = Color(0xFF071B49);
  static const Color background = Color(0xFFF5F7FB);
  static const Color textPrimary = Color(0xFF13213E);

  static ThemeData lightTheme() {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: navy,
      brightness: Brightness.light,
    );

    final colorScheme = baseScheme.copyWith(
      primary: navy,
      onPrimary: Colors.white,
      secondary: const Color(0xFF183B84),
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: textPrimary,
      outline: const Color(0xFFD5DDED),
    );

    final baseTheme = ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      useMaterial3: true,
    );

    return baseTheme.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: const Color(0x14071B49),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE2E9F6)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD5DDED)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFD5DDED)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: navy, width: 1.5),
        ),
        labelStyle: const TextStyle(color: Color(0xFF51607F)),
        prefixIconColor: const Color(0xFF51607F),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: navy,
          side: const BorderSide(color: navy),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: navy,
        contentTextStyle: TextStyle(color: Colors.white),
      ),
      textTheme: baseTheme.textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
    );
  }
}
