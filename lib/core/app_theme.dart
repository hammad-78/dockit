import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFFF7F8FA);
  static const surface = Colors.white;
  static const soft = Color(0xFFEFF2F5);
  static const border = Color(0xFFD9DEE5);
  static const ink = Color(0xFF1F2933);
  static const muted = Color(0xFF68737D);
  static const navy = Color(0xFF19324D);
  static const navyDark = Color(0xFF10243A);
  static const green = Color(0xFF287A55);
  static const amber = Color(0xFFAD7218);
  static const danger = Color(0xFFB33A3A);
}

abstract final class AppTheme {
  static ThemeData get data => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.ink,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: AppColors.navy, width: 1.5),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}
