import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/report.dart';
import '../../models/user.dart';
import '../../staff/widgets/status_badge.dart';
import '../widgets/upvote_button.dart';

class CommunityReportDetailsScreen extends StatefulWidget {
  final Report report;

  const CommunityReportDetailsScreen({super.key, required this.report});

  @override
  State<CommunityReportDetailsScreen> createState() => _CommunityReportDetailsScreenState();
}

class _CommunityReportDetailsScreenState extends State<CommunityReportDetailsScreen> {
  void _handleUpvote() async {
    final appState = context.read<AppState>();
    if (appState.currentUser == null || appState.currentUser?.role.name == 'guest') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in as a resident to upvote community reports.')),
      );
      return;
    }

    try {
      await appState.toggleUpvote(widget.report.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  void _showReportFlagModal() {
    final reasonController = TextEditingController();
    String? selectedReason = 'Inappropriate or offensive content';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.flag_rounded, color: Color(0xFFDC2626), size: 24),
              SizedBox(width: 8),
              Text('Report Inappropriate Post', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Help keep our community safe and respectful. Select a reason for flagging this report:',
                style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedReason,
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: [
                  'Inappropriate or offensive content',
                  'False or misleading information',
                  'Privacy violation / Contains personal data',
                  'Spam or duplicate report',
                  'Other reason',
                ].map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) => setModalState(() => selectedReason = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Additional details (optional)...',
                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.all(10),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final reason = '$selectedReason ${reasonController.text.trim()}'.trim();
                await context.read<AppState>().flagReport(widget.report.id, reason);
                if (mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thank you. The report has been flagged for barangay moderation.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
              child: const Text('Submit Flag'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentReport = appState.reports.firstWhere((r) => r.id == widget.report.id, orElse: () => widget.report);
    final currentUserId = appState.currentUser?.id;
    final isUpvoted = currentUserId != null && currentReport.upvotedUserIds.contains(currentUserId);

    final publicReporterText = currentReport.isAnonymous || currentReport.complainantName.isEmpty
        ? 'Anonymous Resident (${currentReport.purok.isNotEmpty ? currentReport.purok : 'Barangay Area'})'
        : '${currentReport.complainantName} (${currentReport.purok.isNotEmpty ? currentReport.purok : 'Barangay Area'})';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Community Report Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.outlined_flag_rounded, color: Color(0xFFDC2626)),
            onPressed: _showReportFlagModal,
            tooltip: 'Report this post',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          currentReport.id,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace', color: Color(0xFF1D4ED8)),
                        ),
                        StatusBadge(status: currentReport.status),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      currentReport.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.3),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                          child: Text(
                            currentReport.category,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${currentReport.timestamp.day}/${currentReport.timestamp.month}/${currentReport.timestamp.year} ${currentReport.timestamp.hour.toString().padLeft(2, '0')}:${currentReport.timestamp.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 18, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Reported by: $publicReporterText',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text('Full Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                    const SizedBox(height: 6),
                    Text(
                      currentReport.description.isEmpty ? 'No additional description provided.' : currentReport.description,
                      style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    if (currentReport.attachmentUrls.isNotEmpty) ...[
                      const Text('Attached Photo Evidence', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.image_outlined, color: Color(0xFF1D4ED8), size: 32),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Photo File: ${currentReport.attachmentUrls.first}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Community Upvotes:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                        UpvoteButton(
                          count: currentReport.upvoteCount,
                          isUpvoted: isUpvoted,
                          onTap: _handleUpvote,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Official Resolution Progress', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 14),
                    _buildTimelineStep('Submitted to Barangay', 'Report received and queued for review', true),
                    _buildTimelineStep('Under Review / Assigned', 'Barangay officials verifying incident details', currentReport.status != ReportStatus.pending),
                    _buildTimelineStep('In Progress / Investigating', 'On-ground investigation or response active', currentReport.status == ReportStatus.under_investigation),
                    _buildTimelineStep('Resolved & Closed', 'Action completed by barangay staff', currentReport.status == ReportStatus.resolved, isLast: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineStep(String title, String subtitle, bool isCompleted, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isCompleted ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? Icons.check_rounded : Icons.radio_button_unchecked_rounded,
                size: 14,
                color: isCompleted ? Colors.white : const Color(0xFF94A3B8),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: isCompleted ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isCompleted ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}
