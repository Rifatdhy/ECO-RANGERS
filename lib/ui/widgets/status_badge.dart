import 'package:flutter/material.dart';
import '../tokens.dart';

/// StatusBadge bergaya Apple Pill Badge yang sangat bersih, elegan, dan kontras lembut.
class StatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase().trim();

    final (bg, border, text, label) = switch (s) {
      'pending' => (AppColors.pendingBg, AppColors.pendingBorder, AppColors.pendingText, 'Pending'),
      'diproses' || 'proses' => (AppColors.diprosesBg, AppColors.diprosesBorder, AppColors.diprosesText, 'Diproses'),
      'selesai' || 'resolved' => (AppColors.selesaiBg, AppColors.selesaiBorder, AppColors.selesaiText, 'Selesai'),
      'ditolak' || 'rejected' => (AppColors.ditolakBg, AppColors.ditolakBorder, AppColors.ditolakText, 'Ditolak'),
      _ => (AppColors.surfaceMuted, AppColors.line, AppColors.textMuted, status),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 11,
        vertical: compact ? 3.5 : 5.5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: compact ? 5.5 : 6.5,
            height: compact ? 5.5 : 6.5,
            decoration: BoxDecoration(
              color: text,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5.5),
          Text(
            label,
            style: TextStyle(
              color: text,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
