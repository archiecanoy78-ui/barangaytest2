import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/report.dart';
import 'complaint_details_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _searchQuery = '';
  String? _selectedCategory;
  ReportStatus? _selectedStatus;

  void _showNewIncidentDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final locationController = TextEditingController();
    String category = 'Emergency';
    String purok = 'Purok 1';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('New Incident Report', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Incident Title', hintText: 'e.g. Flooding near Purok 5'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: context.read<AppState>().categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setModalState(() => category = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location / Landmark', hintText: 'e.g. Purok 5, Main Road'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description', hintText: 'Describe the situation...'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;
                final appState = context.read<AppState>();
                final id = "BR-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
                final newReport = Report(
                  id: id,
                  title: titleController.text.trim(),
                  category: category,
                  description: descController.text.trim(),
                  incidentLocation: locationController.text.trim(),
                  purok: purok,
                  complainantName: appState.currentUser?.name ?? 'Admin',
                  complainantPhone: appState.currentUser?.phoneNumber ?? 'N/A',
                  status: ReportStatus.pending,
                  priority: 'High',
                  timestamp: DateTime.now(),
                );
                await appState.submitComplaint(newReport);
                if (mounted) Navigator.pop(dialogCtx);
              },
              child: const Text('Submit Incident'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final reports = appState.reports;

    // Dynamics calculations from Firebase
    final totalReports = reports.length;
    final verifiedCount = reports.where((r) => r.confirmations.isNotEmpty || r.status == ReportStatus.resolved || r.status == ReportStatus.underReview).length;
    final pendingCount = reports.where((r) => r.status == ReportStatus.pending).length;

    final assignedCount = reports.where((r) => r.assignedToId != null || r.status == ReportStatus.assigned).length;
    final inProgressCount = reports.where((r) => r.status == ReportStatus.inProgress).length;
    final investigatingCount = reports.where((r) => r.status == ReportStatus.underInvestigation || r.status == ReportStatus.underReview).length;
    final closedResolvedCount = reports.where((r) => r.status == ReportStatus.resolved || r.status == ReportStatus.closed).length;

    // Filter reports for Complaint Management section
    final filteredReports = reports.where((r) {
      final query = _searchQuery.toLowerCase();
      final matchesQuery = _searchQuery.isEmpty ||
          r.id.toLowerCase().contains(query) ||
          r.complainantName.toLowerCase().contains(query) ||
          r.title.toLowerCase().contains(query) ||
          r.description.toLowerCase().contains(query);

      final matchesCategory = _selectedCategory == null || r.category == _selectedCategory;
      final matchesStatus = _selectedStatus == null || r.status == _selectedStatus;

      return matchesQuery && matchesCategory && matchesStatus;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Title Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Admin Dashboard',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Welcome back, Administrator. Here is the operational overview of Barangay operations.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.upload_outlined, size: 18, color: Color(0xFF334155)),
                      label: const Text('Export Report', style: TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _showNewIncidentDialog,
                      icon: const Icon(Icons.add, size: 20, color: Colors.white),
                      label: const Text('+ New Incident', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Banner Card: Total Incidents Logged
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F2563EB),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF60A5FA),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'E-REPORTYAN ADMIN SYSTEM',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFBFDBFE),
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Total Incidents Logged',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '$totalReports',
                              style: const TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.trending_up_rounded, color: Color(0xFF34D399), size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    '+12% this week',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Inset Verification Counts Box
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'VERIFIED',
                              style: TextStyle(
                                color: Color(0xFFBFDBFE),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$verifiedCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 32),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withOpacity(0.25),
                        ),
                        const SizedBox(width: 32),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PENDING',
                              style: TextStyle(
                                color: Color(0xFFBFDBFE),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$pendingCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
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
            const SizedBox(height: 32),

            // Operational Overview Title
            const Text(
              'Operational Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),

            // 4 Metric Overview Cards
            LayoutBuilder(
              builder: (context, constraints) {
                double cardWidth = (constraints.maxWidth - 48) / 4;
                if (cardWidth < 220) cardWidth = constraints.maxWidth;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildOverviewCard(
                      title: 'Assigned',
                      value: assignedCount,
                      badgeText: 'Active',
                      badgeSubtext: 'staff handling cases',
                      badgeColor: const Color(0xFF10B981),
                      icon: Icons.assignment_outlined,
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF2563EB),
                      width: cardWidth,
                    ),
                    _buildOverviewCard(
                      title: 'In Progress',
                      value: inProgressCount,
                      badgeText: 'Under',
                      badgeSubtext: 'field investigation',
                      badgeColor: const Color(0xFFD97706),
                      icon: Icons.schedule_rounded,
                      iconBg: const Color(0xFFFFF7ED),
                      iconColor: const Color(0xFFD97706),
                      width: cardWidth,
                    ),
                    _buildOverviewCard(
                      title: 'Investigating',
                      value: investigatingCount,
                      badgeText: 'Reviewing',
                      badgeSubtext: 'evidence',
                      badgeColor: const Color(0xFF7C3AED),
                      icon: Icons.search_rounded,
                      iconBg: const Color(0xFFF5F3FF),
                      iconColor: const Color(0xFF7C3AED),
                      width: cardWidth,
                    ),
                    _buildOverviewCard(
                      title: 'Closed / Resolved',
                      value: closedResolvedCount,
                      badgeText: 'Completed',
                      badgeSubtext: 'cases this cycle',
                      badgeColor: const Color(0xFF10B981),
                      icon: Icons.check_rounded,
                      iconBg: const Color(0xFFECFDF5),
                      iconColor: const Color(0xFF10B981),
                      width: cardWidth,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),

            // Complaint Management Table Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x05000000),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Header & Filters
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Complaint Management',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Review and filter active community reports and resolution statuses.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search ID, name, description...',
                                  prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                ),
                                onChanged: (val) => setState(() => _searchQuery = val),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                value: _selectedCategory,
                                decoration: InputDecoration(
                                  hintText: 'All Categories',
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                ),
                                items: [
                                  const DropdownMenuItem<String>(value: null, child: Text('All Categories')),
                                  ...appState.categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))),
                                ],
                                onChanged: (val) => setState(() => _selectedCategory = val),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<ReportStatus>(
                                value: _selectedStatus,
                                decoration: InputDecoration(
                                  hintText: 'All Status',
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                ),
                                items: [
                                  const DropdownMenuItem<ReportStatus>(value: null, child: Text('All Status')),
                                  ...ReportStatus.values.map((st) => DropdownMenuItem(value: st, child: Text(_formatStatus(st)))),
                                ],
                                onChanged: (val) => setState(() => _selectedStatus = val),
                              ),
                            ),
                            const SizedBox(width: 16),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _selectedCategory = null;
                                  _selectedStatus = null;
                                });
                              },
                              child: const Text(
                                'Reset Filters',
                                style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                  // Complaints Data Table
                  filteredReports.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(48),
                          alignment: Alignment.center,
                          child: const Column(
                            children: [
                              Icon(Icons.inbox_outlined, size: 48, color: Color(0xFF94A3B8)),
                              SizedBox(height: 12),
                              Text(
                                'No complaints match the filter criteria.',
                                style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 360),
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                              headingRowHeight: 48,
                              dataRowMaxHeight: 64,
                              horizontalMargin: 24,
                              columns: const [
                                DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 11))),
                                DataColumn(label: Text('COMPLAINANT', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 11))),
                                DataColumn(label: Text('CATEGORY', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 11))),
                                DataColumn(label: Text('LOCATION', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 11))),
                                DataColumn(label: Text('DATE', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 11))),
                                DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 11))),
                                DataColumn(label: Text('ACTION', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 11))),
                              ],
                              rows: filteredReports.map((report) {
                                final isAnon = report.isAnonymous || report.complainantName.isEmpty;
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      InkWell(
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => ComplaintDetailsPage(report: report)),
                                        ),
                                        child: Text(
                                          report.id,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2563EB),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        isAnon ? 'Anonymous' : report.complainantName,
                                        style: TextStyle(
                                          fontWeight: isAnon ? FontWeight.normal : FontWeight.w600,
                                          fontStyle: isAnon ? FontStyle.italic : FontStyle.normal,
                                          color: isAnon ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        report.category,
                                        style: const TextStyle(color: Color(0xFF334155), fontSize: 13),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        report.purok.isNotEmpty
                                            ? report.purok
                                            : (report.incidentLocation.isNotEmpty ? report.incidentLocation : 'Not specified'),
                                        style: TextStyle(
                                          color: (report.purok.isEmpty && report.incidentLocation.isEmpty)
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF334155),
                                          fontStyle: (report.purok.isEmpty && report.incidentLocation.isEmpty)
                                              ? FontStyle.italic
                                              : FontStyle.normal,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        _formatDate(report.timestamp),
                                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                      ),
                                    ),
                                    DataCell(_buildStatusBadge(report.status)),
                                    DataCell(
                                      TextButton(
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => ComplaintDetailsPage(report: report)),
                                        ),
                                        child: const Text(
                                          'View',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 13),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required int value,
    required String badgeText,
    required String badgeSubtext,
    required Color badgeColor,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              height: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                badgeText,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: badgeColor,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  badgeSubtext,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ReportStatus status) {
    Color color;
    Color bg;
    String label = _formatStatus(status);

    switch (status) {
      case ReportStatus.pending:
        color = const Color(0xFFD97706);
        bg = const Color(0xFFFEF3C7);
        break;
      case ReportStatus.underReview:
      case ReportStatus.underInvestigation:
        color = const Color(0xFF7C3AED);
        bg = const Color(0xFFF3E8FF);
        break;
      case ReportStatus.assigned:
      case ReportStatus.inProgress:
        color = const Color(0xFF2563EB);
        bg = const Color(0xFFEFF6FF);
        break;
      case ReportStatus.resolved:
        color = const Color(0xFF10B981);
        bg = const Color(0xFFD1FAE5);
        break;
      case ReportStatus.closed:
        color = const Color(0xFF64748B);
        bg = const Color(0xFFF1F5F9);
        break;
      case ReportStatus.rejected:
        color = const Color(0xFFEF4444);
        bg = const Color(0xFFFEE2E2);
        break;
      default:
        color = const Color(0xFF64748B);
        bg = const Color(0xFFF1F5F9);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatStatus(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return 'Pending';
      case ReportStatus.underReview:
        return 'Under Review';
      case ReportStatus.underInvestigation:
        return 'Investigating';
      case ReportStatus.assigned:
        return 'Assigned';
      case ReportStatus.inProgress:
        return 'In Progress';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.closed:
        return 'closed';
      case ReportStatus.rejected:
        return 'Rejected';
      default:
        return status.name;
    }
  }

  String _formatDate(DateTime dt) {
    final year = dt.year;
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
