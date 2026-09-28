import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/report.dart';

class AssignedReportsScreen extends StatefulWidget {
  const AssignedReportsScreen({super.key});

  @override
  State<AssignedReportsScreen> createState() => _AssignedReportsScreenState();
}

class _AssignedReportsScreenState extends State<AssignedReportsScreen> {
  int _currentPage = 0;
  static const int _pageSize = 10;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final assignedReports = appState.getAssignedReports(appState.currentUser!.id);

    if (assignedReports.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          title: const Text('Community Inbox', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: _buildEmptyState(),
      );
    }

    final int totalPages = max(1, (assignedReports.length / _pageSize).ceil());
    if (_currentPage >= totalPages) {
      _currentPage = totalPages - 1;
    }

    final paginatedReports = assignedReports.skip(_currentPage * _pageSize).take(_pageSize).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Community Inbox', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: paginatedReports.length,
              itemBuilder: (context, index) {
                final report = paginatedReports[index];
                return _buildActionableCard(context, report);
              },
            ),
          ),

          // Pagination Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${assignedReports.isEmpty ? 0 : _currentPage * _pageSize + 1}-${min((_currentPage + 1) * _pageSize, assignedReports.length)} of ${assignedReports.length}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                      onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                    ),
                    Text(
                      'Page ${_currentPage + 1} of $totalPages',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mark_email_read_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('All caught up!', style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionableCard(BuildContext context, Report report) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _showReportWorkflow(context, report),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _getStatusBadge(report.status),
                  if (report.isAnonymous)
                    _getRiskBadge(report.riskScore),
                  const Spacer(),
                  Text(
                    'Purok ${report.purok}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                report.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                report.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              if (report.confirmations.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '✓ Corroborated by ${report.confirmations.length} nearby residents',
                    style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.history, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _getTimeAgo(report.timestamp),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  if (report.isAnonymous)
                    const Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: Row(
                        children: [
                          Icon(Icons.visibility_off, size: 14, color: Colors.orange),
                          SizedBox(width: 4),
                          Text('ANONYMOUS', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  const Spacer(),
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(Icons.play_arrow, size: 16, color: Colors.blue),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getRiskBadge(RiskLevel level) {
    Color color;
    switch (level) {
      case RiskLevel.low:
        color = Colors.green;
        break;
      case RiskLevel.medium:
        color = Colors.orange;
        break;
      case RiskLevel.high:
        color = Colors.red;
        break;
    }
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(
        '${level.name.toUpperCase()} RISK',
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _getStatusBadge(ReportStatus status) {
    Color color;
    switch (status) {
      case ReportStatus.pending:
        color = Colors.orange;
        break;
      case ReportStatus.underReview:
      case ReportStatus.underInvestigation:
      case ReportStatus.actionRequired:
      case ReportStatus.assigned:
      case ReportStatus.inProgress:
        color = Colors.indigo;
        break;
      case ReportStatus.resolved:
        color = Colors.green;
        break;
      case ReportStatus.rejected:
      case ReportStatus.closed:
        color = Colors.grey;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _getTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showReportWorkflow(BuildContext context, Report report) {
    final appState = context.read<AppState>();
    final remarksController = TextEditingController(text: report.remarks);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(report.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      Text('Reported from Purok ${report.purok}', style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    _getStatusBadge(report.status),
                    if (report.isAnonymous) ...[
                      const SizedBox(height: 4),
                      _getRiskBadge(report.riskScore),
                    ],
                  ],
                ),
              ],
            ),
            if (report.isAnonymous && report.contactInfo != null && report.contactInfo!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Reporter Contact: ${report.contactInfo}', style: const TextStyle(color: Colors.blue, fontSize: 12)),
              ),
            const SizedBox(height: 20),
            _workflowSection(
              title: 'Phase 1: Dispatch Team',
              child: _buildDispatchSelector(context, report),
            ),
            _workflowSection(
              title: 'Phase 2: Action & Remarks',
              child: TextField(
                controller: remarksController,
                decoration: InputDecoration(
                  hintText: 'Add internal remarks or field notes...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                maxLines: 2,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      appState.updateReportStatus(report.id, ReportStatus.inProgress);
                      appState.addRemarks(report.id, remarksController.text);
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Update Progress'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      appState.updateReportStatus(report.id, ReportStatus.resolved);
                      appState.addRemarks(report.id, remarksController.text);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Resolve Now'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _workflowSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        ),
        child,
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildDispatchSelector(BuildContext context, Report report) {
    final appState = context.read<AppState>();

    final Map<String, List<String>> dispatchOptions = {
      'Waste Management': ['Sanitation Team', 'Maintenance'],
      'Noise Complaint': ['Tanod Patrol', 'Police Assistance'],
      'Public Safety': ['Tanod Group A', 'PNP Station'],
      'Health': ['Health Workers', 'Ambulance'],
      'Infrastructure': ['Engineering Team', 'Public Works'],
      'Emergency': ['Rescue Team', 'Fire Dept'],
      'Others': ['General Staff', 'Secretary'],
    };

    final suggestions = dispatchOptions[report.category] ?? dispatchOptions['Others']!;

    return Column(
      children: suggestions
          .map((team) => ListTile(
                dense: true,
                leading: const Icon(Icons.send, color: Colors.blue, size: 20),
                title: Text(team),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  appState.updateReportStatus(report.id, ReportStatus.assigned);
                  appState.addRemarks(report.id, 'Dispatched: $team');
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dispatched $team to Purok ${report.purok}')));
                },
              ))
          .toList(),
    );
  }
}
