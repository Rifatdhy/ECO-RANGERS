import 'package:flutter/material.dart';

import '../models/kategori.dart';
import '../models/laporan.dart';
import '../services/notifikasi_service.dart';
import '../ui/status_info.dart';
import '../ui/tokens.dart';
import '../ui/widgets/state_views.dart';
import '../ui/widgets/status_badge.dart';
import 'laporan_detail_page.dart';

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  List<Laporan> _unseen = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await NotifikasiService.instance.fetchUnseen();
      if (mounted) setState(() => _unseen = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markSeenAndOpen(Laporan l) async {
    // Tetapkan baseline baru → notifikasi ini tak lagi unread.
    await NotifikasiService.instance.markAllSeen();
    if (!mounted) return;
    setState(() => _unseen = []);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LaporanDetailPage(laporan: l)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [ErrorRetry(onRetry: _load, message: _error!, compact: true)],
                  )
                : _unseen.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          Padding(
                            padding: EdgeInsets.only(top: 120),
                            child: Column(
                              children: [
                                Icon(Icons.notifications_none_rounded, size: 56, color: AppColors.textMuted),
                                SizedBox(height: 12),
                                Text('Tidak ada notifikasi baru', style: TextStyle(fontWeight: FontWeight.w600)),
                                SizedBox(height: 4),
                                Text('Perubahan status laporanmu akan muncul di sini.', style: TextStyle(color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemBuilder: (context, i) {
                          final l = _unseen[i];
                          final info = statusInfo(l.status);
                          return Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: info.color.withValues(alpha: 0.14),
                                child: Icon(info.icon, color: info.color),
                              ),
                              title: Text(l.judul, maxLines: 2, overflow: TextOverflow.ellipsis),
                              subtitle: Text(
                                '${kategoriIcon(l.kategori)} ${kategoriLabel(l.kategori)} · ${l.createdAtLabel}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              trailing: StatusBadge(status: l.status, compact: true),
                              onTap: () => _markSeenAndOpen(l),
                            ),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemCount: _unseen.length,
                      ),
      ),
    );
  }
}