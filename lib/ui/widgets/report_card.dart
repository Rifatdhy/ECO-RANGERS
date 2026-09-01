import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/laporan.dart';
import '../tokens.dart';
import 'status_badge.dart';

/// ReportCard mewah bergaya Apple Editorial Card:
/// Foto rasio 16:9 ber-hero edge-to-edge lembut, badge floating translucent,
/// tipografi tajam dengan hierarki rapi, dan micro-interaction sentuhan halus.
class ReportCard extends StatelessWidget {
  final Laporan report;
  final VoidCallback? onTap;
  final VoidCallback? onVote;

  const ReportCard({
    super.key,
    required this.report,
    this.onTap,
    this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final imgUrl = report.fotoUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14201A) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.07) : AppColors.line,
          width: 1,
        ),
        boxShadow: AppShadows.luxuryCard,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          splashColor: AppColors.sage.withValues(alpha: 0.08),
          highlightColor: AppColors.sage.withValues(alpha: 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Media Header (Apple Aspect Ratio with Subtle Gradient Veil)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg - 1)),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: imgUrl != null && imgUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imgUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: isDark ? const Color(0xFF1E2E26) : AppColors.backgroundSecondary,
                                child: const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      color: AppColors.sage,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => _buildPlaceholder(isDark),
                            )
                          : _buildPlaceholder(isDark),
                    ),
                    // Gradient Shadow for Floating Badge legibility
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 54,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.25),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Top Right Status Badge
                    Positioned(
                      top: 12,
                      right: 12,
                      child: StatusBadge(status: report.status, compact: true),
                    ),
                    // Top Left Category Tag
                    if (report.kategori.isNotEmpty)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            report.kategori.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Content Body (Apple Clean Spacing)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.judul,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 1.25,
                        color: isDark ? Colors.white : AppColors.ink,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      report.deskripsi,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        color: isDark ? AppColors.darkMutedTextColor : AppColors.textSecondary,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),

                    // Divider Hairline
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.lineLight,
                    ),
                    const SizedBox(height: 12),

                    // Footer Meta Bar
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: isDark ? AppColors.darkMutedTextColor : AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            report.lokasiText ?? (report.latitude != null ? '${report.latitude!.toStringAsFixed(4)}, ${report.longitude!.toStringAsFixed(4)}' : 'Lokasi terlampir'),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkMutedTextColor : AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Vote Pill / Interaction
                        GestureDetector(
                          onTap: onVote,
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: report.votedByMe
                                  ? (isDark ? const Color(0xFF1B3D2B) : AppColors.mintGlow)
                                  : (isDark ? const Color(0xFF1C2C23) : AppColors.backgroundSecondary),
                              borderRadius: BorderRadius.circular(AppRadius.full),
                              border: Border.all(
                                color: report.votedByMe
                                    ? AppColors.emerald.withValues(alpha: 0.3)
                                    : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  report.votedByMe ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                                  size: 13,
                                  color: report.votedByMe ? AppColors.emerald : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${report.voteCount}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: report.votedByMe ? AppColors.emerald : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1B2B22) : AppColors.backgroundSecondary,
      child: Center(
        child: Icon(
          Icons.park_rounded,
          size: 42,
          color: isDark ? const Color(0xFF2E4638) : AppColors.sand,
        ),
      ),
    );
  }
}
