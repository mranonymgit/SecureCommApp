import 'package:flutter/material.dart';
import 'package:frontend/features/auth/presentation/screens/loginScreen.dart';
import 'package:frontend/core/theme/app_theme.dart';

void main() {
  runApp(const VecinalApp());
}

class VecinalApp extends StatelessWidget {
  const VecinalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SCA',
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}