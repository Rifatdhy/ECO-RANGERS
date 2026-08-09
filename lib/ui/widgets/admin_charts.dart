import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../tokens.dart';

const _chartColors = [
  Color(0xFF2E7D32),
  Color(0xFFF9A825),
  Color(0xFF43A047),
  Color(0xFF81C784),
  Color(0xFF8D6E63),
  Color(0xFFB0BEC5),
];

const _kategoriNames = {
  'sampah': 'Sampah',
  'pencemaran': 'Pencemaran',
  'infrastruktur': 'Infrastruktur',
  'fauna': 'Fauna',
  'flora': 'Flora',
  'laimnya': 'Lainnya',
};

/// Grafik bar: tren laporan 7 hari terakhir (dari stats['trend'] 30 hari).
class TrenChart extends StatelessWidget {
  const TrenChart({super.key, required this.trend});

  final List<Map<String, dynamic>> trend;

  @override
  Widget build(BuildContext context) {
    final last7 = trend.length >= 7 ? trend.sublist(trend.length - 7) : trend;
    if (last7.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('Belum ada data tren', style: TextStyle(color: AppColors.textMuted))),
      );
    }

    final maxVal = last7.fold<int>(
      0,
      (m, e) => ((e['total'] as num?) ?? 0) > m ? (e['total'] as num).toInt() : m,
    );

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (maxVal + 1).toDouble(),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final label = last7[groupIndex]['date'].toString().substring(5); // MM-dd
                return BarTooltipItem(
                  '$label\n${rod.toY.toInt()} laporan',
                  const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
          barGroups: [
            for (var i = 0; i < last7.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: ((last7[i]['total'] as num?) ?? 0).toDouble(),
                    color: AppColors.primary,
                    width: 18,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Donut distribusi kategori (dari stats['kategori']).
class KategoriDonut extends StatelessWidget {
  const KategoriDonut({super.key, required this.kategori});

  final Map<String, dynamic> kategori;

  @override
  Widget build(BuildContext context) {
    final entries = kategori.entries.where((e) => ((e.value as num?) ?? 0) > 0).toList();
    if (entries.isEmpty) {
      return const SizedBox(
        height: 140,
        child: Center(child: Text('Belum ada data kategori', style: TextStyle(color: AppColors.textMuted))),
      );
    }
    final total = entries.fold<int>(0, (s, e) => s + (e.value as num).toInt());

    return Row(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 34,
              sections: [
                for (var i = 0; i < entries.length; i++)
                  PieChartSectionData(
                    value: (entries[i].value as num).toDouble(),
                    color: _chartColors[i % _chartColors.length],
                    radius: 40,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < entries.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: _chartColors[i % _chartColors.length], shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _kategoriNames[entries[i].key] ?? entries[i].key,
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${(entries[i].value as num).toInt()} (${(((entries[i].value as num).toInt() / total) * 100).round()}%)',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}