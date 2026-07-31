import 'package:flutter/material.dart';
import 'package:frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:frontend/core/theme/app_theme.dart';

void main() {
  runApp(const VecinalApp());
}

class VecinalApp extends StatelessWidget {
  const VecinalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ColorBlindnessTheme>(
      valueListenable: appThemeNotifier,
      builder: (context, temaActual, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SCA',
          theme: temaActual.themeData,
          home: const LoginScreen(),
        );
      },
    );
  }
}