
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF174D3C);
  static const Color background = Color(0xFFF5F7F2);
  static const Color accent = Color(0xFFB8D8C0);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
