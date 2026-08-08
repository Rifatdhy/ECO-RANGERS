import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'config.dart';
import 'locator.dart';
import 'pages/splash_screen.dart';
import 'session.dart';
import 'ui/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  setupLocator();
  await ensureBaseUrl();
  
  // FIX: Mengaktifkan kembali DevicePreview
  runApp(
    DevicePreview(
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
      // FIX: Mengaktifkan kembali konfigurasi DevicePreview
      navigatorKey: rootNavigatorKey,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      
      title: 'Eco Rangers',
      debugShowCheckedModeBanner: false,
      
      themeMode: ThemeMode.system, // ikut mode gelap/terang sistem (ala iOS)
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      
      home: const SplashScreen(),
    );
  }
}
