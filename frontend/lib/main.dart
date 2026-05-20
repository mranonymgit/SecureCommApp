import 'package:flutter/material.dart';
import 'package:frontend/features/news/presentation/screens/home_screen.dart'; 

void main() {
  runApp(const VecinalApp());
}

class VecinalApp extends StatelessWidget {
  const VecinalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App Vecinal',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}