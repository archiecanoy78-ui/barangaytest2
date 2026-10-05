import 'package:flutter/material.dart';
import '../../models/report.dart';
import '../../staff/widgets/status_badge.dart';
import 'upvote_button.dart';

class ReportCard extends StatelessWidget {
  final Report report;
  final String? currentUserId;
  final VoidCallback onTap;
  final VoidCallback onUpvote;

  const ReportCard({
    super.key,
    required this.report,
    required this.currentUserId,
    required this.onTap,
    required this.onUpvote,
  });

  String _getFriendlyRefNo(String id) {
    final numeric = id.replaceAll(RegExp(r'[^0-9]'), '');
    final suffix = numeric.length >= 4 ? numeric.substring(numeric.length - 4) : '0012';
    return 'BRGY-${DateTime.now().year}-$suffix';
  }

  String _getRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isUpvoted = currentUserId != null && report.upvotedUserIds.contains(currentUserId);
    final isEmergency = report.category.toLowerCase().contains('emergency') || report.isSOS;

    // Public-Safe Privacy Masking
    final publicReporterText = report.isAnonymous || report.complainantName.isEmpty
        ? 'Anonymous Resident • ${report.purok.isNotEmpty ? report.purok : 'Barangay Area'}'
        : '${report.complainantName} • ${report.purok.isNotEmpty ? report.purok : 'Barangay Area'}';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Ref No + Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        _getFriendlyRefNo(report.id),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•  ${_getRelativeTime(report.timestamp)}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  StatusBadge(status: report.status),
                ],
              ),
              const SizedBox(height: 10),

              // Title & Emergency Indicator
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isEmergency)
                    Container(
                      margin: const EdgeInsets.only(top: 4, right: 6),
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDC2626),
                        shape: BoxShape.circle,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      report.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Description Snippet
              if (report.description.isNotEmpty) ...[
                Text(
                  report.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
              ],

              // Photo Thumbnail Preview (if attached)
              if (report.attachmentUrls.isNotEmpty) ...[
                Container(
                  height: 120,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Icon(Icons.image_outlined, color: Color(0xFF64748B), size: 28),
                        ),
                        Expanded(
                          child: Text(
                            '1 Evidence Attachment (${report.attachmentUrls.first})',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              const SizedBox(height: 12),

              // Bottom Footer: Public Safe Identity + Upvote Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            publicReporterText,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  UpvoteButton(
                    count: report.upvoteCount,
                    isUpvoted: isUpvoted,
                    onTap: onUpvote,
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
