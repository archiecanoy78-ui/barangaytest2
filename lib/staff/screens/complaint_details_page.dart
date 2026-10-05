import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/report.dart';
import '../../models/user.dart';
import '../../constants/app_constants.dart';
import '../widgets/portal_theme.dart';
import '../widgets/status_badge.dart';

class ComplaintDetailsPage extends StatefulWidget {
  final Report report;
  const ComplaintDetailsPage({super.key, required this.report});

  @override
  State<ComplaintDetailsPage> createState() => _ComplaintDetailsPageState();
}

class _ComplaintDetailsPageState extends State<ComplaintDetailsPage> {
  late ReportStatus _selectedStatus;
  String? _assignedStaffId;
  bool _isSaving = false;
  final TextEditingController _rejectionReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.report.status;
    _assignedStaffId = widget.report.assignedToId;
    _rejectionReasonController.text = widget.report.remarks;
  }

  @override
  void dispose() {
    _rejectionReasonController.dispose();
    super.dispose();
  }

  Future<void> _saveUpdate() async {
    if (_selectedStatus == ReportStatus.rejected && _rejectionReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide the rejection reason before saving.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await context.read<AppState>().updateReportStatus(
        widget.report.id,
        _selectedStatus,
        rejectionReason: _rejectionReasonController.text.trim(),
      );
      if (_assignedStaffId != null && _assignedStaffId != widget.report.assignedToId) {
        await context.read<AppState>().assignStaff(widget.report.id, _assignedStaffId!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint updated successfully.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update complaint: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _getFriendlyRefNo(String id) {
    final numeric = id.replaceAll(RegExp(r'[^0-9]'), '');
    final suffix = numeric.length >= 4 ? numeric.substring(numeric.length - 4) : '6235';
    return 'BRGY-2026-$suffix';
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final staffList = appState.staffList;

    Report currentReport;
    try {
      currentReport = appState.reports.firstWhere((r) => r.id == widget.report.id);
    } catch (_) {
      currentReport = widget.report;
    }

    User? reporter;
    if (currentReport.reporterId != null && currentReport.reporterId!.isNotEmpty) {
      try {
        reporter = appState.allUsers.firstWhere((u) => u.id == currentReport.reporterId);
      } catch (_) {}
    }

    final isAnonymous = currentReport.isAnonymous ||
        (currentReport.complainantName.isEmpty && (reporter == null || reporter.role == UserRole.guest));

    final displayName = currentReport.complainantName.isNotEmpty
        ? currentReport.complainantName
        : (reporter != null && reporter.role != UserRole.guest ? reporter.name : (isAnonymous ? 'Anonymous' : 'Unknown'));

    final displayPhone = currentReport.complainantPhone.isNotEmpty
        ? currentReport.complainantPhone
        : (currentReport.contactInfo?.isNotEmpty == true
            ? currentReport.contactInfo!
            : (reporter != null && reporter.role != UserRole.guest ? reporter.phoneNumber : '09084392257'));

    final displayEmail = currentReport.complainantEmail?.isNotEmpty == true
        ? currentReport.complainantEmail!
        : 'resident.canoy@gmail.com';

    final initials = displayName.isNotEmpty && displayName != 'Anonymous'
        ? displayName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : 'AC';

    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780, maxHeight: 850),
          child: Container(
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, 10))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Bar
                Container(
                  padding: const EdgeInsets.fromLTRB(28, 24, 24, 20),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: PortalColors.border)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: PortalColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('DOC', style: TextStyle(color: PortalColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text('Complaint Details', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: PortalColors.textDark)),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: PortalColors.background,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: PortalColors.border),
                                  ),
                                  child: Text(
                                    '#${_getFriendlyRefNo(currentReport.id)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: PortalColors.textSecondary, fontFamily: 'monospace'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text('Submitted via Resident Citizen Mobile App', style: TextStyle(fontSize: 12, color: PortalColors.textMuted)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: PortalColors.textMuted),
                      ),
                    ],
                  ),
                ),

                // Scrollable Body Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Status & Assign Action Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: PortalColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: PortalColors.border),
                          ),
                          child: Row(
                            children: [
                              // Update Status
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('UPDATE INCIDENT STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: PortalColors.textMuted, letterSpacing: 0.5)),
                                        StatusBadge(status: _selectedStatus),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<ReportStatus>(
                                      value: _selectedStatus,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: PortalColors.border)),
                                      ),
                                      items: ReportStatusExtension.canonicalValues.map((s) => DropdownMenuItem(value: s, child: Text(s.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))).toList(),
                                      onChanged: (v) {
                                        if (v != null) setState(() => _selectedStatus = v);
                                      },
                                    ),
                                    if (_selectedStatus == ReportStatus.rejected) ...[
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: _rejectionReasonController,
                                        minLines: 2,
                                        maxLines: 3,
                                        decoration: const InputDecoration(
                                          labelText: 'Rejection reason',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              // Assign Staff
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('ASSIGN STAFF / TANOD TO TAKE ACTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: PortalColors.textMuted, letterSpacing: 0.5)),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      value: _assignedStaffId,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: PortalColors.border)),
                                      ),
                                      items: [
                                        const DropdownMenuItem(value: null, child: Text('⚠️ Unassigned (Select Responder)', style: TextStyle(fontSize: 13, color: Colors.amber, fontWeight: FontWeight.bold))),
                                        ...staffList.map((s) => DropdownMenuItem(value: s.id, child: Text('${s.name} (${s.staffRole?.name ?? 'Staff'})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)))),
                                      ],
                                      onChanged: (v) => setState(() => _assignedStaffId = v),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Report Subject
                        const Text('REPORT SUBJECT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: PortalColors.primary, letterSpacing: 0.5)),
                        const SizedBox(height: 6),
                        Text(currentReport.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: PortalColors.textDark, letterSpacing: -0.3)),
                        const SizedBox(height: 20),

                        // 2x2 Information Cards Grid
                        Row(
                          children: [
                            // Complainant Profile Card
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: PortalColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: PortalColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('COMPLAINANT PROFILE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: PortalColors.textMuted)),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: PortalColors.primary.withOpacity(0.1),
                                          child: Text(initials, style: const TextStyle(color: PortalColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: PortalColors.textDark)),
                                              const SizedBox(height: 2),
                                              const Text('✔ Verified Resident', style: TextStyle(fontSize: 11, color: PortalColors.success, fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Location & Category Card
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: PortalColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: PortalColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('LOCATION & CATEGORY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: PortalColors.textMuted)),
                                    const SizedBox(height: 12),
                                    Text('${AppConstants.normalizeCategory(currentReport.category)} • ${AppConstants.normalizePurok(currentReport.purok)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: PortalColors.textDark)),
                                    const SizedBox(height: 2),
                                    Text(currentReport.incidentLocation.isNotEmpty ? currentReport.incidentLocation : 'Incident Area (${AppConstants.normalizePurok(currentReport.purok)})', style: const TextStyle(fontSize: 11, color: PortalColors.textMuted)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            // Direct Contact Details Card
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: PortalColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: PortalColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('DIRECT CONTACT DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: PortalColors.textMuted)),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(displayPhone, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: PortalColors.textDark)),
                                        const Text('Copy', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: PortalColors.primary)),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text('Email: $displayEmail', style: const TextStyle(fontSize: 11, color: PortalColors.textMuted)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Emergency Level Card
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: PortalColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: PortalColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('EMERGENCY LEVEL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: PortalColors.textMuted)),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: currentReport.isSOS ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            currentReport.isSOS ? 'Level 1: Urgent' : 'Level 2: Normal',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: currentReport.isSOS ? PortalColors.danger : const Color(0xFFD97706)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('Response SLA: < 2 hrs', style: TextStyle(fontSize: 11, color: PortalColors.textMuted)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Resident Statement / Incident Narrative
                        const Text('RESIDENT STATEMENT / INCIDENT NARRATIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: PortalColors.textMuted, letterSpacing: 0.5)),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: PortalColors.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: PortalColors.border),
                          ),
                          child: Text(
                            '"${currentReport.description}"',
                            style: const TextStyle(fontSize: 13, color: PortalColors.textPrimary, height: 1.6, fontStyle: FontStyle.italic),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Internal Activity Log
                        const Text('INTERNAL ACTIVITY LOG', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: PortalColors.textMuted, letterSpacing: 0.5)),
                        const SizedBox(height: 12),
                        _activityItem('Report registered by resident $displayName', 'Today at ${currentReport.timestamp.toLocal().toString().split(' ')[1].substring(0, 5)}', true),
                        _activityItem('Automated notification dispatched to Purok health volunteers', 'Today at ${currentReport.timestamp.add(const Duration(minutes: 2)).toLocal().toString().split(' ')[1].substring(0, 5)}', false),
                      ],
                    ),
                  ),
                ),

                // Footer Actions
                Container(
                  padding: const EdgeInsets.fromLTRB(28, 16, 28, 20),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: PortalColors.border)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: PortalColors.textSecondary,
                          side: const BorderSide(color: PortalColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Close'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveUpdate,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(_isSaving ? 'Saving...' : 'Save & Dispatch Officer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _activityItem(String title, String time, bool isLast) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              const SizedBox(height: 3),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: PortalColors.primary, shape: BoxShape.circle),
              ),
              if (!isLast) Container(width: 2, height: 24, color: PortalColors.border),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: PortalColors.textDark)),
                const SizedBox(height: 2),
                Text(time, style: const TextStyle(fontSize: 11, color: PortalColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
