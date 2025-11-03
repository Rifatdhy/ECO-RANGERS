import 'package:flutter/material.dart';

class MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const MenuCard({super.key, required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        // Tema Card dari AppTheme akan otomatis diterapkan di sini
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon, 
                size: 40, 
                // Ambil warna dari tema utama aplikasi
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title, 
                style: const TextStyle(fontWeight: FontWeight.bold), 
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
