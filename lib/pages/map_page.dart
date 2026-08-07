import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../locator.dart';
import '../models/laporan.dart';
import '../services/api_client.dart';
import '../ui/tokens.dart';
import '../ui/widgets/section_header.dart';
import '../ui/widgets/state_views.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final ApiClient _api = locator<ApiClient>();
  List<Laporan> _reports = [];
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
      _reports = await _api.fetchReportsAsModel();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openMaps(Laporan l) async {
    final lat = l.latitude;
    final lng = l.longitude;
    final uri = lat != null && lng != null
        ? Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng')
        : Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(l.lokasiText ?? l.judul)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka Google Maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final withCoords = _reports.where((l) => l.latitude != null && l.longitude != null).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
                  child: SectionHeader(
                    title: 'Lokasi Laporan',
                    subtitle: 'Tap laporan untuk membuka Google Maps',
                  ),
                ),
              ),
              if (_loading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorRetry(onRetry: _load, message: _error!),
                )
              else if (withCoords.isEmpty)
SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.location_off_outlined,
                    title: 'Belum ada lokasi',
                    subtitle: 'Laporan dengan koordinat akan muncul di sini.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 24),
                  sliver: SliverList.separated(
                    itemBuilder: (context, i) {
                      final l = withCoords[i];
                      return Card(
                        child: InkWell(
                          onTap: () => _openMaps(l),
                          borderRadius: BorderRadius.circular(24),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_rounded,
                                      color: AppColors.primary,
                                      size: 26,
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Expanded(
                                      child: Text(
                                        l.judul,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.only(left: 34),
                                  child: Text(
                                    l.lokasiText ?? l.lokasi,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.only(left: 34),
                                  child: Row(
                                    children: [
                                      Text(
                                        l.latitude?.toStringAsFixed(4) ?? '-',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                      Text(' , ', style: theme.textTheme.bodySmall),
                                      Text(
                                        l.longitude?.toStringAsFixed(4) ?? '-',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                      const Spacer(),
                                      const Icon(Icons.open_in_new_rounded, size: 16),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemCount: withCoords.length,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}