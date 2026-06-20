// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    // Esto centraliza el estilo de tus alertas
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.primary,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 25),
      contentTextStyle: TextStyle(color: AppColors.textBody, fontSize: 18),
    ),
  );
}