import 'package:flutter/material.dart';
import 'auth_page.dart'; // Langsung ke halaman login gabungan

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green, Colors.lightGreen],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.eco, size: 100, color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                "Eco Rangers",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Selamat Datang di Eco Rangers!",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      // Mengarah ke AuthPage, bukan LoginSelectionPage
                      builder: (_) => const AuthPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green,
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.arrow_forward),
                label: const Text("Mulai"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
