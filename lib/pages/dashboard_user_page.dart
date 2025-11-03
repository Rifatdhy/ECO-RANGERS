import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../locator.dart';
import 'api_reports_page.dart';
import 'buat_laporan_page.dart';
import 'auth_page.dart'; // DIUBAH: Mengarah ke halaman login yang baru
import '../ui/widgets/menu_card.dart'; 

class DashboardUserPage extends StatelessWidget {
  const DashboardUserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard User"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await locator<AuthService>().logout();
              Navigator.pushAndRemoveUntil(
                context,
                // DIUBAH: Mengarah ke AuthPage setelah logout
                MaterialPageRoute(builder: (context) => const AuthPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            MenuCard(
              icon: Icons.cloud_download,
              title: "Cek Laporan (API)",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ApiReportsPage()),
                );
              },
            ),
            MenuCard(
              icon: Icons.report_problem,
              title: "Buat Laporan",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BuatLaporanPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
