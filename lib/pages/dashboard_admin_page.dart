import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/laporan.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import 'detail_laporan_admin_page.dart';
import 'auth_page.dart'; // DIUBAH: Mengarah ke halaman login yang baru
import '../locator.dart';

class DashboardAdminPage extends StatefulWidget {
  const DashboardAdminPage({super.key});

  @override
  State<DashboardAdminPage> createState() => _DashboardAdminPageState();
}

class _DashboardAdminPageState extends State<DashboardAdminPage> {
  final _api = locator<ApiClient>();
  List<Laporan> laporanList = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.fetchReportsAsModel();
      setState(() {
        laporanList = data;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _updateLaporan(Laporan laporan, String status) {
    setState(() {
      laporan.status = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isDesktop ? 'Dashboard Admin (Desktop)' : 'Dashboard Admin (Mobile)',
        ),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
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
      body: _buildBody(isDesktop),
    );
  }

  Widget _buildBody(bool isDesktop) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _load,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }
    return isDesktop ? _buildDesktopView() : _buildMobileView();
  }

  Widget _buildMobileView() {
    return ListView.builder(
      itemCount: laporanList.length,
      itemBuilder: (_, index) {
        final laporan = laporanList[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            title: Text(laporan.judul),
            subtitle: Text('Status: ${laporan.status}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailLaporanAdminPage(
                          laporan: laporan,
                          onUpdate: _updateLaporan,
                        ),
                      ),
                    ).then((_) => _load());
                  },
                  child: const Text('Detail'),
                ),
                const SizedBox(width: 6),
                _buildDeleteButton(laporan),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopView() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        headingRowColor: WidgetStateProperty.all(
          Colors.green[100],
        ),
        columns: const [
          DataColumn(label: Text('ID')),
          DataColumn(label: Text('Judul')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Tanggal')),
          DataColumn(label: Text('Action')),
        ],
        rows: laporanList.map((laporan) {
          return DataRow(
            cells: [
              DataCell(Text(laporan.id.toString())),
              DataCell(Text(laporan.judul)),
              DataCell(Text(laporan.status)),
              DataCell(Text(DateFormat('d MMM yyyy').format(laporan.tanggal))),
              DataCell(
                Row(
                  children: [
                    ElevatedButton(
                      child: const Text('Detail'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                DetailLaporanAdminPage(
                                  laporan: laporan,
                                  onUpdate: _updateLaporan,
                                ),
                          ),
                        ).then((_) => _load());
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildDeleteButton(laporan),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  IconButton _buildDeleteButton(Laporan laporan) {
    return IconButton(
      icon: const Icon(
        Icons.delete,
        color: Colors.red,
      ),
      onPressed: () async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Hapus laporan?'),
            content: Text(laporan.judul),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, true),
                child: const Text('Hapus'),
              ),
            ],
          ),
        );
        if (ok == true) {
          try {
            await _api.deleteReport(laporan.id);
            _load();
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(
              SnackBar(
                content: Text('Gagal hapus: $e'),
              ),
            );
          }
        }
      },
    );
  }
}
