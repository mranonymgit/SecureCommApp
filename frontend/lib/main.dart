import 'package:flutter/material.dart';
import 'package:frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/network/api_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (ApiConfig.supabaseUrl.isNotEmpty &&
      ApiConfig.supabasePublishableKey.isNotEmpty) {
    await Supabase.initialize(
      url: ApiConfig.supabaseUrl,
      publishableKey: ApiConfig.supabasePublishableKey,
    );
  }
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
