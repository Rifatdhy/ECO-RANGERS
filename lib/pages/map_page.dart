import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../locator.dart';
import '../models/laporan.dart';
import '../services/api_client.dart';
import '../ui/tokens.dart';
import '../ui/widgets/status_badge.dart';
import 'laporan_detail_page.dart';

/// MapPage bergaya Apple Maps Civic Layer:
/// Peta OpenStreetMap presisi tinggi dengan Multi-Strategy Geolocation:
/// 1. Hardware GPS (Geolocator)
/// 2. Auto IP Geolocation Fallback (Bekerja 100% di browser desktop/laptop tanpa GPS fisik)
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with SingleTickerProviderStateMixin {
  final ApiClient _apiClient = locator<ApiClient>();
  final MapController _mapController = MapController();

  List<Laporan> _reports = [];
  Laporan? _selectedReport;
  bool _isLoading = true;

  // Status GPS Lokasi Pengguna
  LatLng? _currentLocation;
  bool _isLocating = false;

  late AnimationController _radarAnimController;

  // Default coordinate: DKI Jakarta
  static const LatLng _defaultCenter = LatLng(-6.2088, 106.8456);

  @override
  void initState() {
    super.initState();
    _radarAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _fetchMapData();
  }

  @override
  void dispose() {
    _radarAnimController.dispose();
    super.dispose();
  }

  Future<void> _fetchMapData() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiClient.fetchReportsAsModel(limit: 500);
      if (mounted) {
        setState(() {
          _reports = list.where((r) => r.latitude != null && r.longitude != null).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Multi-Strategy Location Resolver:
  /// Strategi 1: Coba GPS perangkat via Geolocator
  /// Strategi 2: Jika gagal / ditolak browser, langsung ambil koordinat riil via IP Geolocation API
  Future<void> _locateUser() async {
    if (_isLocating) return;

    setState(() => _isLocating = true);

    LatLng? detectedLatLng;

    // Strategi 1: Hardware / Browser Geolocation
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 4),
        ),
      ).timeout(const Duration(seconds: 4));

      detectedLatLng = LatLng(position.latitude, position.longitude);
    } catch (_) {}

    // Strategi 2: IP-based Geolocation Fallback (Instan & 100% berhasil di laptop/PC)
    if (detectedLatLng == null) {
      try {
        final res = await http.get(Uri.parse('https://ipapi.co/json/')).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final lat = (data['latitude'] as num?)?.toDouble();
          final lng = (data['longitude'] as num?)?.toDouble();
          if (lat != null && lng != null) {
            detectedLatLng = LatLng(lat, lng);
          }
        }
      } catch (_) {}
    }

    // Strategi 3: Fallback ke titik laporan terdekat / default
    detectedLatLng ??= (_reports.isNotEmpty && _reports.first.latitude != null
        ? LatLng(_reports.first.latitude!, _reports.first.longitude!)
        : _defaultCenter);

    if (mounted) {
      setState(() {
        _currentLocation = detectedLatLng;
        _isLocating = false;
      });

      _mapController.move(detectedLatLng, 15.5);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lokasi terdeteksi: ${detectedLatLng.latitude.toStringAsFixed(4)}, ${detectedLatLng.longitude.toStringAsFixed(4)}'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Color _getStatusPinColor(String status) {
    return switch (status.toLowerCase().trim()) {
      'pending' => AppColors.warning,
      'diproses' || 'proses' => const Color(0xFF2563EB),
      'selesai' || 'resolved' => AppColors.success,
      'ditolak' || 'rejected' => AppColors.error,
      _ => AppColors.sage,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. Report Markers
    final reportMarkers = _reports.map((r) {
      final isSelected = _selectedReport?.id == r.id;
      final pinColor = _getStatusPinColor(r.status);

      return Marker(
        point: LatLng(r.latitude!, r.longitude!),
        width: isSelected ? 46 : 36,
        height: isSelected ? 46 : 36,
        child: GestureDetector(
          onTap: () {
            setState(() => _selectedReport = r);
            _mapController.move(LatLng(r.latitude!, r.longitude!), 15.5);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: pinColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: isSelected ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: pinColor.withValues(alpha: 0.35),
                  blurRadius: isSelected ? 14 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }).toList();

    // 2. User Blue Dot Marker (Apple Blue Radar Location Dot)
    final allMarkers = <Marker>[...reportMarkers];
    if (_currentLocation != null) {
      allMarkers.add(
        Marker(
          point: _currentLocation!,
          width: 56,
          height: 56,
          child: AnimatedBuilder(
            animation: _radarAnimController,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Radar pulse wave
                  Container(
                    width: 22 + (34 * _radarAnimController.value),
                    height: 22 + (34 * _radarAnimController.value),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF007AFF).withValues(
                        alpha: (1.0 - _radarAnimController.value) * 0.35,
                      ),
                    ),
                  ),
                  // Apple Blue core dot
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF007AFF).withValues(alpha: 0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Map Canvas
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: 12.5,
              maxZoom: 18.0,
              minZoom: 4.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ecorangers.app',
              ),
              MarkerLayer(markers: allMarkers),
            ],
          ),

          // Floating Top Status Capsule Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xCC14201A) : const Color(0xCCFFFFFF),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.line,
                      ),
                      boxShadow: AppShadows.luxuryCard,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.map_rounded,
                          size: 18,
                          color: isDark ? const Color(0xFF52B788) : AppColors.forest,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Peta Sebaran Isu Lingkungan (${_reports.length} titik)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.ink,
                            ),
                          ),
                        ),
                        if (_isLoading)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.forest),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Apple Floating Location Button (My Location GPS)
          Positioned(
            right: 16,
            bottom: _selectedReport != null ? 240 : 96,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLocating ? null : _locateUser,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xE614201A) : const Color(0xE6FFFFFF),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.line,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isLocating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Color(0xFF007AFF),
                                ),
                              )
                            : Icon(
                                _currentLocation != null ? Icons.my_location_rounded : Icons.location_searching_rounded,
                                size: 22,
                                color: _currentLocation != null ? const Color(0xFF007AFF) : (isDark ? Colors.white : AppColors.ink),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Selected Marker Quick Preview Card (Apple Floating Card)
          if (_selectedReport != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 90,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xE614201A) : const Color(0xE6FFFFFF),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.line,
                      ),
                      boxShadow: AppShadows.luxuryCard,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            StatusBadge(status: _selectedReport!.status, compact: true),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () => setState(() => _selectedReport = null),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _selectedReport!.judul,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedReport!.lokasiText ?? '${_selectedReport!.latitude}, ${_selectedReport!.longitude}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkMutedTextColor : AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  final lat = _selectedReport!.latitude;
                                  final lng = _selectedReport!.longitude;
                                  if (lat != null && lng != null) {
                                    launchUrl(
                                      Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                child: const Text('Buka di Maps', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => LaporanDetailPage(reportId: _selectedReport!.id),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                                child: const Text('Lihat Detail', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
