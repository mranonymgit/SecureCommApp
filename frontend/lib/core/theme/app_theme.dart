// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class ColorBlindnessTheme {
  final String key;
  final String name;
  final String description;
  final ThemeData themeData;

  const ColorBlindnessTheme({
    required this.key,
    required this.name,
    required this.description,
    required this.themeData,
  });
}

class AppTheme {
  // Función auxiliar para construir el ThemeData reutilizando tus estilos
  static ThemeData _buildTheme({
    required Color primary,
    required Color primaryDark,
    required Color accent,
    required Color background,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      cardColor: cardColor,
      dividerColor: borderColor,
      colorScheme: ColorScheme.dark(
        primary: primary,
        onPrimary: Colors.white,
        secondary: accent,
        onSecondary: const Color.fromARGB(255, 0, 0, 0),
        surface: cardColor,
        onSurface: textColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: cardColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white70,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        labelStyle: TextStyle(color: textColor, fontSize: 16),
        hintStyle: TextStyle(color: secondaryTextColor, fontSize: 16),
        prefixIconColor: primary,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: borderColor, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: primary, width: 2.5),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        titleTextStyle: TextStyle(color: textColor, fontSize: 25),
        contentTextStyle: TextStyle(color: textColor, fontSize: 18),
      ),
    );
  }

  // Definición de las paletas de accesibilidad
  static final ColorBlindnessTheme estandar = ColorBlindnessTheme(
    key: 'default',
    name: 'Estándar (Modo Oscuro)',
    description:
        'Paleta original de la aplicación (Fondo negro, verde y texto blanco).',
    themeData: _buildTheme(
      primary: Colors.green, // Botones e íconos verdes
      primaryDark: const Color(
        0xFF1B5E20,
      ), // Verde oscuro para acentos secundarios
      accent: Colors.greenAccent, // Verde brillante para destacados
      background: const Color.fromARGB(
        255,
        28,
        28,
        28,
      ), // Fondo totalmente negro
      cardColor: const Color(
        0xFF121212,
      ), // Tarjetas y elementos en negro elevado
      borderColor: const Color(0xFF2E7D32), // Borde verde oscuro
      textColor: Colors.white, // Letras blancas
      secondaryTextColor:
          Colors.white70, // Letras secundarias blancas con opacidad
    ),
  );

  static final ColorBlindnessTheme deuteranopia = ColorBlindnessTheme(
    key: 'deuteranopia',
    name: 'Deuteranopía / Protanopía',
    description: 'Optimizado para la dificultad en distinguir rojo y verde.',
    themeData: _buildTheme(
      primary: const Color(0xFF3A86FF),
      primaryDark: const Color(0xFF004E92),
      accent: const Color(0xFFFFBE0B),
      background: const Color(0xFF10141D),
      cardColor: const Color(0xFF1C2331),
      borderColor: const Color(0xFF2C3E50),
      textColor: const Color(0xFFF1F5F9),
      secondaryTextColor: const Color(0xFF94A3B8),
    ),
  );

  static final ColorBlindnessTheme tritanopia = ColorBlindnessTheme(
    key: 'tritanopia',
    name: 'Tritanopía',
    description: 'Optimizado para la dificultad en distinguir azul y amarillo.',
    themeData: _buildTheme(
      primary: const Color(0xFFFF0055),
      primaryDark: const Color(0xFF990033),
      accent: const Color(0xFF00F5D4),
      background: const Color(0xFF1A0F1A),
      cardColor: const Color(0xFF2A1B2A),
      borderColor: const Color(0xFF4A2B4A),
      textColor: const Color(0xFFFFF0F5),
      secondaryTextColor: const Color(0xFFD8B4E2),
    ),
  );

  static final ColorBlindnessTheme monocromatico = ColorBlindnessTheme(
    key: 'monochromacy',
    name: 'Alto Contraste / Monocromático',
    description: 'Máximo contraste visual en escala de grises.',
    themeData: _buildTheme(
      primary: const Color(0xFFFFFFFF),
      primaryDark: const Color(0xFF333333),
      accent: const Color(0xFFCCCCCC),
      background: const Color(0xFF000000),
      cardColor: const Color(0xFF1A1A1A),
      borderColor: const Color(0xFFFFFFFF),
      textColor: const Color(0xFFFFFFFF),
      secondaryTextColor: const Color(0xFFCCCCCC),
    ),
  );

  static final List<ColorBlindnessTheme> temas = [
    estandar,
    deuteranopia,
    tritanopia,
    monocromatico,
  ];
}

class ThemeNotifier extends ValueNotifier<ColorBlindnessTheme> {
  ThemeNotifier() : super(AppTheme.estandar);

  void cambiarTema(ColorBlindnessTheme nuevoTema) {
    value = nuevoTema;
  }
}

final appThemeNotifier = ThemeNotifier();
