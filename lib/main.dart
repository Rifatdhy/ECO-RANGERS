import 'package:flutter/material.dart';

import 'config.dart';
import 'locator.dart';
import 'pages/splash_screen.dart';
import 'ui/app_theme.dart'; // Impor tema

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ensureBaseUrl();
  setupLocator();
  runApp(const EcoRangersApp());
}

class EcoRangersApp extends StatelessWidget {
  const EcoRangersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eco Rangers',
      debugShowCheckedModeBanner: false,
      // Terapkan tema yang sudah didefinisikan
      theme: AppTheme.lightTheme, 
      home: const SplashScreen(),
    );
  }
}
