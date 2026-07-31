// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF0D8D0F);
  static const Color primaryDark = Color(0xFF02742F);
  static const Color accent = Color(0xFF15FF00);
  static const Color background = Colors.white;
  static const Color surfaceTint = Color(0x1E00D447);

  // --- CORRECCIÓN DE FORMULARIOS Y CAJAS DE TEXTO ---
  // 1. Cambiamos el verde fosforescente por un gris suave súper limpio para los campos:
  static const Color fieldFill = Color(0xFFF4F4F4);

  static const Color fieldBorder = Color(0x9376966B);
  static const Color fieldBorderAlt = Color(0x948B8896);
  static const Color fieldFocused = Color(0xD11D9712);

  // 2. Cambiamos el texto transparente por un negro/gris oscuro legible en toda la app:
  static const Color textBody = Color(0xFF222222);

  static const Color alert = Colors.redAccent;
}
