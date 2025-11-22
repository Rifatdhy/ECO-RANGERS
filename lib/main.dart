import 'package:device_preview/device_preview.dart'; // Impor Device Preview
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'config.dart';
import 'locator.dart';
import 'pages/splash_screen.dart';
import 'ui/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  setupLocator();
  await ensureBaseUrl();
  
  // Bungkus root aplikasi dengan DevicePreview
  runApp(
    DevicePreview(
      // Aktifkan hanya jika dalam mode debug
      enabled: !kReleaseMode, 
      builder: (context) => const EcoRangersApp(),
    ),
  );
}

class EcoRangersApp extends StatelessWidget {
  const EcoRangersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Konfigurasi penting untuk DevicePreview
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      
      title: 'Eco Rangers',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, 
      home: const SplashScreen(),
    );
  }
}
