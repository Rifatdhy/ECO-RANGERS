import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../models/laporan.dart';
import '../locator.dart'; // Impor locator

class ApiReportsPage extends StatefulWidget {
  const ApiReportsPage({super.key});

  @override
  State<ApiReportsPage> createState() => _ApiReportsPageState();
}

class _ApiReportsPageState extends State<ApiReportsPage> {
  late Future<List<Laporan>> _reportsFuture;
  // Gunakan locator untuk mendapatkan instance ApiClient
  final ApiClient _apiClient = locator<ApiClient>();

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() {
    setState(() {
      _reportsFuture = _apiClient.fetchReportsAsModel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan (API)'),
        backgroundColor: Colors.green,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadReports(),
        child: FutureBuilder<List<Laporan>>(
          future: _reportsFuture,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error: ${snap.error}'),
                ),
              );
            }
            final data = snap.data ?? [];
            if (data.isEmpty) {
              return const Center(child: Text('Belum ada laporan'));
            }

            return ListView.builder(
              itemCount: data.length,
              itemBuilder: (_, i) {
                final laporan = data[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    isThreeLine: true,
                    leading: laporan.fotoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              laporan.fotoUrl!,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                    title: Text(laporan.judul),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          laporan.deskripsi,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text('Status: ${laporan.status}'),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
