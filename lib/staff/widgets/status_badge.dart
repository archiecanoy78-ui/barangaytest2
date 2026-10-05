import 'package:flutter/material.dart';
import '../../models/report.dart';
import 'app_colors.dart';

class StatusBadge extends StatelessWidget {
  final ReportStatus? status;
  final String? customText;
  final Color? customBg;
  final Color? customTextFg;

  const StatusBadge({
    super.key,
    this.status,
    this.customText,
    this.customBg,
    this.customTextFg,
  });

  @override
  Widget build(BuildContext context) {
    String text = customText ?? (status?.label ?? 'Pending');
    
    Color bg = customBg ?? _getBgForStatus(status);
    Color fg = customTextFg ?? _getFgForStatus(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.15,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBgForStatus(ReportStatus? st) {
    if (st == null) return const Color(0xFFF1F5F9);
    switch (st) {
      case ReportStatus.pending:
        return const Color(0xFFFEF3C7);
      case ReportStatus.under_investigation:
        return const Color(0xFFEDE9FE);
      case ReportStatus.resolved:
        return const Color(0xFFDCFCE7);
      case ReportStatus.rejected:
        return const Color(0xFFF1F5F9);
    }
  }

  Color _getFgForStatus(ReportStatus? st) {
    if (st == null) return AppColors.textSecondary;
    switch (st) {
      case ReportStatus.pending:
        return const Color(0xFFB45309);
      case ReportStatus.under_investigation:
        return const Color(0xFF6D28D9);
      case ReportStatus.resolved:
        return const Color(0xFF15803D);
      case ReportStatus.rejected:
        return const Color(0xFF475569);
    }
  }
}
