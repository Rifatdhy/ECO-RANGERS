import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:eco_rangers/config.dart';
import 'package:eco_rangers/locator.dart';
import 'package:eco_rangers/pages/splash_screen.dart';
import 'package:eco_rangers/ui/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  setupLocator();
  await ensureBaseUrl();

  runApp(const EcoRangersApp());
}

class EcoRangersApp extends StatelessWidget {
  const EcoRangersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eco Rangers',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
