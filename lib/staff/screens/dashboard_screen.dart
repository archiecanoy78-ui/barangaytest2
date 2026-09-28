import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/report.dart';
import '../widgets/portal_theme.dart';
import '../widgets/page_header.dart';
import '../widgets/status_badge.dart';
import '../widgets/needs_attention_strip.dart';
import 'complaint_details_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _getFriendlyRefNo(String id) {
    final numeric = id.replaceAll(RegExp(r'[^0-9]'), '');
    final suffix = numeric.length >= 4 ? numeric.substring(numeric.length - 4) : '0012';
    return 'BRGY-2026-$suffix';
  }

  void _showNewIncidentDialog() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final locationController = TextEditingController();
    String category = context.read<AppState>().categories.first;
    String purok = 'Purok 1';
    String? attachedFileName;
    String? validationError;

    // Load System Settings from Firestore
    bool requireEvidence = true;
    bool autoGenerateId = true;
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('barangay_info').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        requireEvidence = (data['requireEvidence'] as bool?) ?? true;
        autoGenerateId = (data['autoGenerateId'] as bool?) ?? true;
      }
    } catch (_) {}

    final generatedSuffix = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    final autoRefId = 'BRGY-${DateTime.now().year}-$generatedSuffix';

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setModalState) {
          Widget buildLabel(String text, {bool isRequired = false}) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Text(
                    text,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: PortalColors.textDark),
                  ),
                  if (isRequired)
                    const Text(
                      ' *',
                      style: TextStyle(color: PortalColors.danger, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                ],
              ),
            );
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            title: Row(
              children: [
                const Text('Log New Incident', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (autoGenerateId) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: PortalColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: PortalColors.border),
                    ),
                    child: Text(
                      autoRefId,
                      style: const TextStyle(
                        color: PortalColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (validationError != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFF87171)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 16, color: PortalColors.danger),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                validationError!,
                                style: const TextStyle(color: Color(0xFF991B1B), fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Incident Title (Required)
                    buildLabel('Incident Title', isRequired: true),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Flooding near Purok 5 Main Street',
                      ),
                      onChanged: (_) {
                        if (validationError != null) {
                          setModalState(() => validationError = null);
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Category (Required)
                    buildLabel('Category', isRequired: true),
                    DropdownButtonFormField<String>(
                      value: category,
                      isExpanded: true,
                      decoration: const InputDecoration(),
                      items: context.read<AppState>().categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setModalState(() {
                            category = v;
                            if (validationError != null) validationError = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Location / Landmark
                    buildLabel('Location / Landmark'),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Purok 5, Main Road near Chapel',
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Description & Live Character Counter
                    buildLabel('Description'),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      maxLength: 500,
                      buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                      decoration: const InputDecoration(
                        hintText: 'Describe the incident in detail...',
                        counterText: '',
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${descController.text.length} / 500',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: descController.text.length > 500 ? PortalColors.danger : PortalColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Evidence Upload Field (Respects Require Evidence Attachment)
                    buildLabel('Attach photo or document evidence', isRequired: requireEvidence),
                    InkWell(
                      onTap: () {
                        setModalState(() {
                          if (attachedFileName == null) {
                            attachedFileName = 'incident_photo_${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}.jpg';
                          } else {
                            attachedFileName = null;
                          }
                          if (validationError != null) validationError = null;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(
                          color: attachedFileName != null ? PortalColors.primary.withOpacity(0.04) : PortalColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: attachedFileName != null ? PortalColors.primary : PortalColors.border,
                            width: 1.5,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              attachedFileName != null ? Icons.check_circle_rounded : Icons.attach_file_rounded,
                              size: 18,
                              color: attachedFileName != null ? PortalColors.success : PortalColors.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                attachedFileName != null ? 'Attached: $attachedFileName (Tap to remove)' : 'Click to attach photo or document evidence',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: attachedFileName != null ? FontWeight.w600 : FontWeight.w500,
                                  color: attachedFileName != null ? PortalColors.textDark : PortalColors.textMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              // Ghost Secondary Button
              OutlinedButton(
                onPressed: () => Navigator.pop(dialogCtx),
                style: OutlinedButton.styleFrom(
                  foregroundColor: PortalColors.textSecondary,
                  side: const BorderSide(color: PortalColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              // Primary Filled Button
              ElevatedButton(
                onPressed: () async {
                  final titleText = titleController.text.trim();
                  if (titleText.isEmpty) {
                    setModalState(() => validationError = 'Incident Title is required.');
                    return;
                  }
                  if (requireEvidence && attachedFileName == null) {
                    setModalState(() => validationError = 'Evidence attachment is required as per System Settings rules.');
                    return;
                  }

                  final appState = context.read<AppState>();
                  final reportId = autoGenerateId
                      ? autoRefId
                      : "BRGY-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";

                  final isEmergency = category.toLowerCase().contains('emergency');
                  final priority = isEmergency ? 'Emergency' : 'Medium';

                  final newReport = Report(
                    id: reportId,
                    title: titleText,
                    category: category,
                    description: descController.text.trim(),
                    incidentLocation: locationController.text.trim(),
                    purok: purok,
                    complainantName: appState.currentUser?.name ?? 'Admin',
                    complainantPhone: appState.currentUser?.phoneNumber ?? 'N/A',
                    status: ReportStatus.pending,
                    priority: priority,
                    isSOS: isEmergency,
                    attachmentUrls: attachedFileName != null ? [attachedFileName!] : [],
                    timestamp: DateTime.now(),
                  );

                  await appState.submitComplaint(newReport);
                  if (mounted) Navigator.pop(dialogCtx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: PortalColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Save Incident'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final reports = appState.reports;

    // Attention Metrics
    final unassigned = reports.where((r) => r.assignedToId == null && r.status == ReportStatus.pending).length;
    final pendingOver3Days = reports.where((r) => r.status == ReportStatus.pending && DateTime.now().difference(r.timestamp).inDays >= 3).length;
    final urgentCount = reports.where((r) => r.priority.toLowerCase() == 'high' || r.isSOS).length;
    final resolvedThisWeek = reports.where((r) => r.status == ReportStatus.resolved && DateTime.now().difference(r.timestamp).inDays <= 7).length;

    final totalIncidents = reports.length;
    final assignedCount = reports.where((r) => r.assignedToId != null && r.assignedToId!.isNotEmpty).length;
    final inProgressCount = reports.where((r) => r.status == ReportStatus.inProgress || r.status == ReportStatus.underInvestigation || r.status == ReportStatus.underReview).length;
    final closedResolvedCount = reports.where((r) => r.status == ReportStatus.resolved || r.status == ReportStatus.closed).length;

    // Purok Breakdown (Normalized and Sorted highest to lowest)
    final Map<String, int> pCounts = {};
    for (var r in reports) {
      String p = r.purok.trim();
      if (p.isEmpty) {
        p = 'Purok 1';
      } else {
        p = p[0].toUpperCase() + p.substring(1).toLowerCase();
      }
      pCounts[p] = (pCounts[p] ?? 0) + 1;
    }
    final sortedPuroks = pCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Recent 5 complaints
    final recentReports = reports.take(5).toList();

    final volumeSeries = _buildVolumeSeries(reports);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: "Today's Summary",
          description: 'Overview of active resident complaints, purok distribution, and urgent matters.',
          breadcrumbs: const ['Dashboard', 'Overview'],
          actionButton: ElevatedButton.icon(
            onPressed: _showNewIncidentDialog,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Log Incident'),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(28),
            children: [
              Row(
                children: [
                  _buildMetricCard('Total Incidents', '$totalIncidents', '2.4%', Icons.assignment_outlined, const [Color(0xFF6366F1), Color(0xFF8B5CF6)], true),
                  const SizedBox(width: 16),
                  _buildMetricCard('Assigned', '$assignedCount', '+8 today', Icons.person_outline_rounded, const [Color(0xFF14B8A6), Color(0xFF2DD4BF)], true),
                  const SizedBox(width: 16),
                  _buildMetricCard('In Progress / Investigating', '$inProgressCount', '+3 today', Icons.hourglass_top_rounded, const [Color(0xFFF59E0B), Color(0xFFFBBF24)], false),
                  const SizedBox(width: 16),
                  _buildMetricCard('Closed / Resolved', '$closedResolvedCount', '+12 this week', Icons.check_circle_outline_rounded, const [Color(0xFF22C55E), Color(0xFF4ADE80)], true),
                ],
              ),
              const SizedBox(height: 24),
              NeedsAttentionStrip(
                items: [
                  NeedsAttentionItem(label: 'Unassigned', count: unassigned, color: PortalColors.warning, onTap: () {}),
                  NeedsAttentionItem(label: 'Pending > 3 Days', count: pendingOver3Days, color: PortalColors.danger, onTap: () {}),
                  NeedsAttentionItem(label: 'Urgent / High Priority', count: urgentCount, color: PortalColors.danger, onTap: () {}),
                  NeedsAttentionItem(label: 'Resolved This Week', count: resolvedThisWeek, color: PortalColors.success, onTap: () {}),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: PortalColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: PortalColors.border),
                        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 14, offset: Offset(0, 2))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Recent Complaints', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: PortalColors.textDark)),
                                TextButton(onPressed: () {}, child: const Text('View all', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: PortalColors.primary))),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: PortalColors.border),
                          recentReports.isEmpty
                              ? const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('No complaints recorded.', style: TextStyle(color: PortalColors.textMuted))))
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: recentReports.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1, color: PortalColors.border),
                                  itemBuilder: (context, index) {
                                    final r = recentReports[index];
                                    final isEmergency = r.category.toLowerCase().contains('emergency') || r.isSOS;

                                    return ListTile(
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ComplaintDetailsPage(report: r))),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                      title: Row(
                                        children: [
                                          Text(_getFriendlyRefNo(r.id), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'monospace', color: PortalColors.primary)),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: PortalColors.textPrimary), overflow: TextOverflow.ellipsis)),
                                        ],
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Row(
                                          children: [
                                            if (isEmergency)
                                              Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 6), decoration: const BoxDecoration(color: PortalColors.danger, shape: BoxShape.circle)),
                                            Text('${r.category} • ${r.purok.isNotEmpty ? r.purok : 'Purok 1'}', style: const TextStyle(color: PortalColors.textMuted, fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                      trailing: StatusBadge(status: r.status),
                                    );
                                  },
                                ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: PortalColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: PortalColors.border),
                        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 14, offset: Offset(0, 2))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Complaints by Purok', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: PortalColors.textDark)),
                          const SizedBox(height: 4),
                          const Text('Active distribution across puroks', style: TextStyle(fontSize: 12, color: PortalColors.textMuted)),
                          const SizedBox(height: 20),
                          sortedPuroks.isEmpty
                              ? const Center(child: Text('No data available', style: TextStyle(color: PortalColors.textMuted)))
                              : Column(
                                  children: sortedPuroks.map((entry) {
                                    final maxCount = sortedPuroks.first.value;
                                    final pct = maxCount > 0 ? entry.value / maxCount : 0.0;
                                    final percent = (pct * 100).round();
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 14),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: PortalColors.textPrimary)),
                                              Text('$percent%', style: const TextStyle(color: PortalColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700)),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(999),
                                            child: AnimatedContainer(
                                              duration: const Duration(milliseconds: 500),
                                              curve: Curves.easeOutCubic,
                                              width: double.infinity,
                                              height: 10,
                                              decoration: BoxDecoration(color: const Color(0xFFE8EBF3), borderRadius: BorderRadius.circular(999)),
                                              child: Align(
                                                alignment: Alignment.centerLeft,
                                                child: FractionallySizedBox(
                                                  widthFactor: pct.clamp(0.08, 1.0),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)], begin: Alignment.centerLeft, end: Alignment.centerRight),
                                                      borderRadius: BorderRadius.circular(999),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: PortalColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: PortalColors.border),
                  boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 14, offset: Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Trends Over Time', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: PortalColors.textDark)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(999)),
                          child: const Text('Last 30 days', style: TextStyle(color: PortalColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 180,
                      child: CustomPaint(
                        painter: _TrendAreaPainter(volumeSeries),
                        child: Container(),
                      ),
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

  List<_TrendPoint> _buildVolumeSeries(List<Report> reports) {
    final now = DateTime.now();
    final values = <_TrendPoint>[];

    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final count = reports.where((r) => r.timestamp.year == date.year && r.timestamp.month == date.month && r.timestamp.day == date.day).length;
      values.add(_TrendPoint(date, count));
    }

    return values;
  }

  Widget _buildMetricCard(String title, String value, String delta, IconData icon, List<Color> colors, bool positive) {
    final glow = positive ? const Color(0xFFDCFCE7) : const Color(0xFFFFF7ED);
    final deltaColor = positive ? const Color(0xFF15803D) : const Color(0xFFB45309);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: PortalColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: PortalColors.border),
          boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(color: glow, borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    delta,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: deltaColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: PortalColors.textDark, letterSpacing: -0.8)),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: PortalColors.textMuted)),
            const SizedBox(height: 12),
            SizedBox(
              height: 26,
              child: CustomPaint(
                painter: _MiniSparklinePainter(
                  values: List.generate(8, (index) => (index + 1) * (index.isEven ? 0.8 : 1.2) + (positive ? 0.2 : 0.0)),
                  color: colors.first,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendPoint {
  final DateTime date;
  final int count;

  const _TrendPoint(this.date, this.count);
}

class _MiniSparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;

  const _MiniSparklinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final max = values.reduce((a, b) => a > b ? a : b).clamp(0.1, double.infinity);
    final min = values.reduce((a, b) => a < b ? a : b);
    final span = (max - min).abs() < 0.0001 ? 1.0 : max - min;

    for (int i = 0; i < values.length; i++) {
      final x = i / (values.length - 1) * size.width;
      final y = size.height - ((values[i] - min) / span) * (size.height - 4) - 2;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _MiniSparklinePainter oldDelegate) => oldDelegate.values != values || oldDelegate.color != color;
}

class _TrendAreaPainter extends CustomPainter {
  final List<_TrendPoint> points;

  const _TrendAreaPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final max = points.map((p) => p.count.toDouble()).reduce((a, b) => a > b ? a : b);
    final min = 0.0;
    final gridPaint = Paint()..color = const Color(0xFFE5E7EB)..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final linePath = Path();
    final areaPath = Path();
    final step = points.length > 1 ? size.width / (points.length - 1) : size.width;
    final denominator = (max - min).abs() < 0.0001 ? 1.0 : max - min;

    for (int i = 0; i < points.length; i++) {
      final x = i * step;
      final ratio = (points[i].count - min) / denominator;
      final y = size.height - ratio * (size.height - 22) - 10;
      if (i == 0) {
        linePath.moveTo(x, y);
        areaPath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
        areaPath.lineTo(x, y);
      }
    }

    areaPath.lineTo(size.width, size.height);
    areaPath.lineTo(0, size.height);
    areaPath.close();

    final areaPaint = Paint()..shader = const LinearGradient(
      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(areaPath, areaPaint..color = const Color(0x1A6366F1));

    final linePaint = Paint()
      ..color = const Color(0xFF6366F1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final outerPaint = Paint()..color = const Color(0xFF6366F1)..style = PaintingStyle.fill;
    final lastPoint = points.last;
    final lastRatio = (lastPoint.count - min) / ((max - min).abs() < 0.0001 ? 1.0 : max - min);
    final lastX = size.width;
    final lastY = size.height - lastRatio * (size.height - 22) - 10;
    canvas.drawCircle(Offset(lastX, lastY), 5, outerPaint);
    canvas.drawCircle(Offset(lastX, lastY), 2.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _TrendAreaPainter oldDelegate) => oldDelegate.points != points;
}
