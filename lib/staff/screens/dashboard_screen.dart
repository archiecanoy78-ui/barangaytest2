import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/report.dart';
import '../../constants/app_constants.dart';
import '../widgets/portal_theme.dart';
import '../widgets/page_header.dart';
import '../widgets/status_badge.dart';
import '../widgets/needs_attention_strip.dart';
import '../widgets/stat_card.dart';
import '../widgets/section_card.dart';
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
    return 'BRGY-${DateTime.now().year}-$suffix';
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
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: PortalColors.textDark),
                  ),
                  if (isRequired)
                    const Text(
                      ' *',
                      style: TextStyle(color: PortalColors.danger, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                ],
              ),
            );
          }

          final screenWidth = MediaQuery.of(context).size.width;
          final dialogWidth = screenWidth < 560 ? screenWidth * 0.9 : 500.0;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            title: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Log New Incident',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: PortalColors.textDark),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (autoGenerateId) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: PortalColors.neutral100,
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
              width: dialogWidth,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (validationError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: PortalColors.dangerBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: PortalColors.dangerBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 16, color: PortalColors.danger),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                validationError!,
                                style: const TextStyle(color: PortalColors.dangerText, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Incident Title
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

                    // Category
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

                    // Location
                    buildLabel('Location / Landmark'),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Purok 5, Main Road near Chapel',
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Description
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

                    // Evidence Upload Field
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
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                        decoration: BoxDecoration(
                          color: attachedFileName != null ? PortalColors.primary.withOpacity(0.04) : PortalColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: attachedFileName != null ? PortalColors.primary : PortalColors.border,
                            width: 1.2,
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
              OutlinedButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
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
    final inProgressCount = reports.where((r) => r.status == ReportStatus.under_investigation).length;
    final closedResolvedCount = reports.where((r) => r.status == ReportStatus.resolved).length;

    // Purok Breakdown
    final Map<String, int> pCounts = {};
    for (var r in reports) {
      final p = AppConstants.normalizePurok(r.purok);
      pCounts[p] = (pCounts[p] ?? 0) + 1;
    }
    final sortedPuroks = pCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Recent 5 complaints
    final recentReports = reports.take(5).toList();
    final volumeSeries = _buildVolumeSeries(reports);

    return Scaffold(
      backgroundColor: PortalColors.background,
      floatingActionButton: MediaQuery.of(context).size.width < 600
          ? FloatingActionButton.extended(
              onPressed: _showNewIncidentDialog,
              backgroundColor: PortalColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Log Incident', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Widget
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

          // Scrollable Dashboard Content Area
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Stat Cards Grid (Responsive 4-col / 2x2 grid)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;

                      final c1 = StatCard(
                        title: 'Total Incidents',
                        value: '$totalIncidents',
                        delta: '+2.4% vs last week',
                        icon: Icons.assignment_outlined,
                        colors: const [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                        positive: true,
                        tooltip: 'Total registered incident reports',
                      );

                      final c2 = StatCard(
                        title: 'Assigned',
                        value: '$assignedCount',
                        delta: '+8 today',
                        icon: Icons.person_outline_rounded,
                        colors: const [Color(0xFF0D9488), Color(0xFF14B8A6)],
                        positive: true,
                        tooltip: 'Reports assigned to barangay officers',
                      );

                      final c3 = StatCard(
                        title: 'In Progress / Investigating',
                        value: '$inProgressCount',
                        delta: '+3 today',
                        icon: Icons.hourglass_top_rounded,
                        colors: const [Color(0xFFD97706), Color(0xFFF59E0B)],
                        positive: false,
                        tooltip: 'Reports currently being investigated or handled',
                      );

                      final c4 = StatCard(
                        title: 'Closed / Resolved',
                        value: '$closedResolvedCount',
                        delta: '+12 this week',
                        icon: Icons.check_circle_outline_rounded,
                        colors: const [Color(0xFF16A34A), Color(0xFF22C55E)],
                        positive: true,
                        tooltip: 'Successfully resolved or closed complaints',
                      );

                      if (width > 1024) {
                        // Desktop: 4 columns in 1 Row
                        return IntrinsicHeight(
                          child: Row(
                            children: [
                              Expanded(child: c1),
                              const SizedBox(width: 16),
                              Expanded(child: c2),
                              const SizedBox(width: 16),
                              Expanded(child: c3),
                              const SizedBox(width: 16),
                              Expanded(child: c4),
                            ],
                          ),
                        );
                      } else if (width >= 500) {
                        // Tablet / Medium Screen: 2x2 Grid
                        return Column(
                          children: [
                            IntrinsicHeight(
                              child: Row(
                                children: [
                                  Expanded(child: c1),
                                  const SizedBox(width: 14),
                                  Expanded(child: c2),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            IntrinsicHeight(
                              child: Row(
                                children: [
                                  Expanded(child: c3),
                                  const SizedBox(width: 14),
                                  Expanded(child: c4),
                                ],
                              ),
                            ),
                          ],
                        );
                      } else {
                        // Mobile Small Screen: 2x2 Grid or 1 Column
                        return Column(
                          children: [
                            IntrinsicHeight(
                              child: Row(
                                children: [
                                  Expanded(child: c1),
                                  const SizedBox(width: 10),
                                  Expanded(child: c2),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            IntrinsicHeight(
                              child: Row(
                                children: [
                                  Expanded(child: c3),
                                  const SizedBox(width: 10),
                                  Expanded(child: c4),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  // 2. Needs Attention Strip
                  NeedsAttentionStrip(
                    items: [
                      NeedsAttentionItem(label: 'Unassigned', count: unassigned, color: PortalColors.warning, onTap: () {}),
                      NeedsAttentionItem(label: 'Pending > 3 Days', count: pendingOver3Days, color: PortalColors.danger, onTap: () {}),
                      NeedsAttentionItem(label: 'Urgent / High Priority', count: urgentCount, color: PortalColors.danger, onTap: () {}),
                      NeedsAttentionItem(label: 'Resolved This Week', count: resolvedThisWeek, color: PortalColors.success, onTap: () {}),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 3. Recent Complaints & Purok Distribution Cards
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 1024;

                      Widget complaintsCard = SectionCard(
                        title: 'Recent Complaints',
                        subtitle: 'Latest incidents logged by residents or staff',
                        padding: EdgeInsets.zero,
                        headerAction: TextButton(
                          onPressed: () {},
                          child: const Text('View all', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: PortalColors.primary)),
                        ),
                        child: recentReports.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(32),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.inbox_rounded, size: 40, color: PortalColors.neutral300),
                                      SizedBox(height: 8),
                                      Text(
                                        'No recent complaints reported yet.',
                                        style: TextStyle(color: PortalColors.textMuted, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: recentReports.length,
                                separatorBuilder: (_, __) => const Divider(height: 1, color: PortalColors.border),
                                itemBuilder: (context, index) {
                                  final r = recentReports[index];
                                  final isEmergency = r.category.toLowerCase().contains('emergency') || r.isSOS;

                                  return ListTile(
                                    minVerticalPadding: 12,
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ComplaintDetailsPage(report: r))),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                    title: Row(
                                      children: [
                                        Text(
                                          _getFriendlyRefNo(r.id),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'monospace', color: PortalColors.primary),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            r.title,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: PortalColors.textPrimary),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        children: [
                                          if (isEmergency)
                                            Container(
                                              width: 6,
                                              height: 6,
                                              margin: const EdgeInsets.only(right: 6),
                                              decoration: const BoxDecoration(color: PortalColors.danger, shape: BoxShape.circle),
                                            ),
                                          Expanded(
                                            child: Text(
                                              '${AppConstants.normalizeCategory(r.category)} • ${AppConstants.normalizePurok(r.purok)}',
                                              style: const TextStyle(color: PortalColors.textMuted, fontSize: 12),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    trailing: StatusBadge(status: r.status),
                                  );
                                },
                              ),
                      );

                      Widget purokCard = SectionCard(
                        title: 'Complaints by Purok',
                        subtitle: 'Active distribution across neighborhood puroks',
                        child: sortedPuroks.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(32),
                                child: Center(
                                  child: Text('No purok data available', style: TextStyle(color: PortalColors.textMuted, fontSize: 13)),
                                ),
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
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
                                            Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: PortalColors.textPrimary)),
                                            Text('${entry.value} ($percent%)', style: const TextStyle(color: PortalColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700)),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(999),
                                          child: Container(
                                            width: double.infinity,
                                            height: 8,
                                            decoration: BoxDecoration(color: PortalColors.neutral100, borderRadius: BorderRadius.circular(999)),
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: FractionallySizedBox(
                                                widthFactor: pct.clamp(0.08, 1.0),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(
                                                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                                                      begin: Alignment.centerLeft,
                                                      end: Alignment.centerRight,
                                                    ),
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
                      );

                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: complaintsCard),
                            const SizedBox(width: 20),
                            Expanded(flex: 2, child: purokCard),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            complaintsCard,
                            const SizedBox(height: 20),
                            purokCard,
                          ],
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  // 4. Trends Over Time Chart
                  SectionCard(
                    title: 'Trends Over Time',
                    subtitle: '30-day incident logging activity and volume',
                    headerAction: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: PortalColors.blue50, borderRadius: BorderRadius.circular(999)),
                      child: const Text('Last 30 days', style: TextStyle(color: PortalColors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                    child: SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _TrendAreaPainter(volumeSeries),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
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
}

class _TrendPoint {
  final DateTime date;
  final int count;

  const _TrendPoint(this.date, this.count);
}

class _TrendAreaPainter extends CustomPainter {
  final List<_TrendPoint> points;

  const _TrendAreaPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final max = points.map((p) => p.count.toDouble()).reduce((a, b) => a > b ? a : b);
    final min = 0.0;
    final gridPaint = Paint()..color = PortalColors.border..strokeWidth = 1;
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
      colors: [Color(0x2A4F46E5), Color(0x057C3AED)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(areaPath, areaPaint);

    final linePaint = Paint()
      ..color = PortalColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final outerPaint = Paint()..color = PortalColors.primary..style = PaintingStyle.fill;
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
