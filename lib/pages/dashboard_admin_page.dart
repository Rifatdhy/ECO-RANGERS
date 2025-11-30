import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:collection/collection.dart'; // Import untuk groupBy

import '../models/laporan.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import 'laporan_detail_page.dart';
import 'auth_page.dart';
import '../locator.dart';
import '../ui/app_theme.dart';

class DashboardAdminPage extends StatefulWidget {
  const DashboardAdminPage({super.key});

  @override
  State<DashboardAdminPage> createState() => _DashboardAdminPageState();
}

class _DashboardAdminPageState extends State<DashboardAdminPage> {
  Future<List<Laporan>>? _reportsFuture;
  DateTime? _selectedDate;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() {
    setState(() {
      _reportsFuture = locator<ApiClient>().fetchReportsAsModel();
      _clearFilters();
    });
  }
  
  void _clearFilters() {
    setState(() {
      _selectedDate = null;
      _selectedStatus = null;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }
  
  void _selectStatus(String? status) {
    setState(() => _selectedStatus = status);
  }

  void _navigateToDetail(Laporan laporan) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LaporanDetailPage(laporan: laporan)),
    );
    if (result == true) {
      _loadReports();
    }
  }

  String _buildAppBarTitle() {
    if (_selectedStatus != null && _selectedDate != null) {
      return '${_selectedStatus![0].toUpperCase()}${_selectedStatus!.substring(1)} | ${DateFormat('dd MMM yyyy').format(_selectedDate!)}';
    }
    if (_selectedStatus != null) {
      return 'Laporan ${_selectedStatus![0].toUpperCase()}${_selectedStatus!.substring(1)}';
    }
    if (_selectedDate != null) {
      return DateFormat('dd MMM yyyy').format(_selectedDate!);
    }
    return "Semua Laporan";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_buildAppBarTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
          ),
          if (_selectedDate != null || _selectedStatus != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Hapus Semua Filter',
              onPressed: _clearFilters,
            ),
          _buildStatusFilterMenu(),
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            tooltip: 'Filter Tanggal',
            onPressed: () => _selectDate(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Logout',
            onPressed: () async {
              await locator<AuthService>().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const AuthPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Laporan>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerList();
          }
          if (snapshot.hasError) {
            return Center(child: Text("Gagal memuat data: ${snapshot.error}"));
          }
          
          final allReports = snapshot.data ?? [];
          
          final filteredReports = allReports.where((report) {
            final isDateMatch = _selectedDate == null || DateUtils.isSameDay(report.createdAt, _selectedDate!);
            final isStatusMatch = _selectedStatus == null || report.status == _selectedStatus;
            return isDateMatch && isStatusMatch;
          }).toList();

          if (allReports.isEmpty) {
            return _buildEmptyState('Belum ada laporan masuk.', 'Sistem belum menerima laporan apa pun.');
          }
          if (filteredReports.isEmpty) {
            return _buildEmptyState('Tidak Ada Laporan', 'Tidak ada laporan yang cocok dengan filter Anda.');
          }
          return _buildGroupedReportList(filteredReports);
        },
      ),
    );
  }

  Widget _buildGroupedReportList(List<Laporan> reports) {
    final groupedReports = groupBy(reports, (Laporan report) => DateUtils.dateOnly(report.createdAt));

    return AnimationLimiter(
      child: RefreshIndicator(
        onRefresh: () async => _loadReports(),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          itemCount: groupedReports.keys.length,
          itemBuilder: (context, index) {
            final date = groupedReports.keys.elementAt(index);
            final reportsForDate = groupedReports[date]!;
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 4.0),
                  child: Text(_formatGroupDate(date), style: Theme.of(context).textTheme.titleLarge),
                ),
                ...reportsForDate.map((report) {
                   final reportIndex = reports.indexOf(report);
                   return AnimationConfiguration.staggeredList(
                      position: reportIndex,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: _buildReportCard(report, Theme.of(context).textTheme),
                        ),
                      ),
                   );
                }).toList(),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatGroupDate(DateTime date) {
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final yesterday = DateUtils.addDaysToDate(today, -1);

    if (date == today) return 'Hari Ini';
    if (date == yesterday) return 'Kemarin';
    return DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
  }
  
  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(width: 70, height: 70, color: Colors.white),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: double.infinity, height: 16.0, color: Colors.white),
                        const SizedBox(height: 8),
                        Container(width: 100.0, height: 12.0, color: Colors.white),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(width: 80, height: 30, color: Colors.white),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  PopupMenuButton<String> _buildStatusFilterMenu() {
    return PopupMenuButton<String>(
      onSelected: _selectStatus,
      icon: const Icon(Icons.filter_list),
      tooltip: 'Filter Status',
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(value: 'pending', child: Text('Pending')),
        const PopupMenuItem<String>(value: 'diproses', child: Text('Diproses')),
        const PopupMenuItem<String>(value: 'selesai', child: Text('Selesai')),
        const PopupMenuItem<String>(value: 'ditolak', child: Text('Ditolak')),
      ],
    );
  }

  Widget _buildEmptyState(String title, String message) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.all_inbox_outlined, size: 80, color: theme.textTheme.bodyMedium?.color),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(Laporan laporan, TextTheme textTheme) {
    final statusInfo = _getStatusInfo(laporan.status);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () => _navigateToDetail(laporan),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: laporan.fotoUrl != null
                    ? Image.network(
                        laporan.fotoUrl!,
                        width: 70, height: 70, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                      )
                    : _buildPlaceholderImage(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(laporan.judul, style: textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMMM yyyy').format(laporan.createdAt),
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Chip(
                avatar: Icon(statusInfo.icon, color: Colors.white, size: 16),
                label: Text(statusInfo.text),
                backgroundColor: statusInfo.color,
                labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 70, height: 70,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Center(
        child: Icon(Icons.image_not_supported_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 30),
      ),
    );
  }

  ({Color color, IconData icon, String text}) _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return (color: Colors.green, icon: Icons.check_circle, text: 'Selesai');
      case 'diproses':
        return (color: Colors.purple, icon: Icons.hourglass_bottom, text: 'Diproses');
      case 'ditolak':
        return (color: Colors.red, icon: Icons.cancel, text: 'Ditolak');
      default: // pending
        return (color: Colors.orange, icon: Icons.inbox, text: 'Pending');
    }
  }
}
