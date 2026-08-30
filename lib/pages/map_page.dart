import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../locator.dart';
import '../models/kategori.dart';
import '../models/laporan.dart';
import '../services/api_client.dart';
import '../ui/status_info.dart';
import '../ui/tokens.dart';
import '../ui/widgets/state_views.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  final ApiClient _api = locator<ApiClient>();
  List<Laporan> _reports = [];
  bool _loading = true;
  String? _error;
  Laporan? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void refresh({bool silent = false}) => _load(silent: silent);

  LatLng? _center;
  int _reqSeq = 0;

  Future<void> _load({bool silent = false}) async {
    final seq = ++_reqSeq;
    if (!mounted) return;
    if (!silent || _reports.isEmpty) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final reports = await _api.fetchReportsAsModel(limit: 500);
      if (seq != _reqSeq || !mounted) return;
      final coords = reports
          .where((l) => l.latitude != null && l.longitude != null)
          .toList();
      setState(() {
        _reports = reports;
        _center = _computeCenter(coords);
      });
    } catch (e) {
      if (seq != _reqSeq || !mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (seq == _reqSeq && mounted) setState(() => _loading = false);
    }
  }

  LatLng? _computeCenter(List<Laporan> coords) {
    if (coords.isEmpty) return null;
    if (coords.length == 1) {
      return LatLng(coords.first.latitude!, coords.first.longitude!);
    }
    final latAvg = coords.map((l) => l.latitude!).reduce((a, b) => a + b) / coords.length;
    final lngAvg = coords.map((l) => l.longitude!).reduce((a, b) => a + b) / coords.length;
    return LatLng(latAvg, lngAvg);
  }

  List<Laporan> get _withCoords =>
      _reports.where((l) => l.latitude != null && l.longitude != null).toList();

  Future<void> _openMaps(Laporan l) async {
    final lat = l.latitude;
    final lng = l.longitude;
    final uri = lat != null && lng != null
        ? Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng')
        : Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(l.lokasiText ?? l.judul)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka Google Maps')),
      );
    }
  }

  void _onMarkerTap(Laporan l) {
    setState(() => _selected = l);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Lokasi Laporan', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                          Text('Ketuk marker untuk detail & buka Google Maps',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Muat ulang',
                      onPressed: _load,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? ErrorRetry(onRetry: _load, message: _error ?? 'Terjadi kesalahan')
                        : _withCoords.isEmpty
                            ? const EmptyState(
                                icon: Icons.location_off_outlined,
                                title: 'Belum ada lokasi',
                                subtitle: 'Laporan dengan koordinat akan muncul di peta.',
                              )
                            : _buildMap(),
              ),
              if (_selected != null) _buildBottomSheet(context, _selected!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMap() {
    final coords = _withCoords;
    final center = _center ?? _computeCenter(coords) ?? const LatLng(-6.2, 106.8);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 11,
        onTap: (_, __) => setState(() => _selected = null),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.ecorangers.app',
        ),
        MarkerLayer(
          markers: [
            for (final l in coords)
              Marker(
                point: LatLng(l.latitude!, l.longitude!),
                width: 48,
                height: 48,
                child: Semantics(
                  label: l.judul,
                  button: true,
                  child: GestureDetector(
                    onTap: () => _onMarkerTap(l),
                    child: _StatusMarker(status: l.status, selected: _selected?.id == l.id),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // MapController disimpan sebagai field agar TIDAK dibuat ulang tiap build.
  final MapController _mapController = MapController();

  Widget _buildBottomSheet(BuildContext context, Laporan l) {
    final theme = Theme.of(context);
    final selInfo = statusInfo(l.status);
    return Material(
      color: AppColors.surface,
      elevation: 12,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.judul,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: () => setState(() => _selected = null),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${kategoriIcon(l.kategori)} ${kategoriLabel(l.kategori)} · ${l.lokasiText ?? l.lokasi}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(selInfo.icon, size: 16, color: selInfo.color),
                  const SizedBox(width: 4),
                  Text(selInfo.text, style: theme.textTheme.labelMedium?.copyWith(color: selInfo.color, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    onPressed: () => _openMaps(l),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Buka di Maps'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusMarker extends StatelessWidget {
  const _StatusMarker({required this.status, this.selected = false});

  final String status;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final info = statusInfo(status);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: info.color,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? Colors.white : AppColors.surface,
          width: (selected ? 3 : 2).toDouble(),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: selected ? 0.35 : 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          info.icon,
          color: Colors.white,
          size: (selected ? 20 : 16).toDouble(),
        ),
      ),
    );
  }
}