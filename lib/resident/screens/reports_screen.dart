import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/report.dart';
import '../../models/user.dart';
import '../../widgets/report_form.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser!;
    final myReports = appState.getReportsForUser(user.id);
    final communityReports = appState.reports.where((r) => r.reporterId != user.id).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('E-Reportyan', style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My Reports'),
              Tab(text: 'Community Feed'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            PaginatedReportList(reports: myReports, isMyTab: true),
            PaginatedReportList(reports: communityReports, isMyTab: false),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => showReportForm(context),
          label: const Text('File Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          icon: const Icon(Icons.campaign_rounded, size: 22),
          backgroundColor: Colors.orange.shade800,
          foregroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class PaginatedReportList extends StatefulWidget {
  final List<Report> reports;
  final bool isMyTab;

  const PaginatedReportList({
    super.key,
    required this.reports,
    required this.isMyTab,
  });

  @override
  State<PaginatedReportList> createState() => _PaginatedReportListState();
}

class _PaginatedReportListState extends State<PaginatedReportList> {
  int _currentPage = 0;
  static const int _pageSize = 10;

  @override
  Widget build(BuildContext context) {
    if (widget.reports.isEmpty) {
      return _buildEmptyState(widget.isMyTab ? 'No reports yet' : 'No community reports');
    }

    final int totalPages = max(1, (widget.reports.length / _pageSize).ceil());
    if (_currentPage >= totalPages) {
      _currentPage = totalPages - 1;
    }

    final paginatedReports = widget.reports.skip(_currentPage * _pageSize).take(_pageSize).toList();

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: paginatedReports.length,
            itemBuilder: (context, index) {
              final report = paginatedReports[index];
              return _buildReportCard(context, report, widget.isMyTab);
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
                'Showing ${widget.reports.isEmpty ? 0 : _currentPage * _pageSize + 1}-${min((_currentPage + 1) * _pageSize, widget.reports.length)} of ${widget.reports.length}',
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
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, Report report, bool isMyTab) {
    final appState = context.read<AppState>();
    final user = appState.currentUser!;
    bool alreadyConfirmed = report.confirmations.contains(user.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getStatusIcon(report.status),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.category,
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        report.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                if (report.isAnonymous)
                  const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Icon(Icons.visibility_off, size: 16, color: Colors.grey),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(report.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    report.status.name.toUpperCase(),
                    style: TextStyle(fontSize: 10, color: _getStatusColor(report.status), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              report.description,
              style: const TextStyle(color: Colors.black54),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                Text(' Purok ${report.purok}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const Spacer(),
                if (!isMyTab && user.role == UserRole.resident)
                  ElevatedButton.icon(
                    onPressed: alreadyConfirmed ? null : () => appState.confirmReport(report.id, user.id),
                    icon: Icon(alreadyConfirmed ? Icons.verified_rounded : Icons.thumb_up_alt_rounded, size: 14),
                    label: Text(alreadyConfirmed ? 'Confirmed' : 'I confirm this', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: alreadyConfirmed ? Colors.green.shade50 : Colors.blue.shade50,
                      foregroundColor: alreadyConfirmed ? Colors.green.shade800 : Colors.blue.shade800,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
              ],
            ),
            if (report.confirmations.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Confirmed by ${report.confirmations.length} nearby residents',
                  style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _getStatusIcon(ReportStatus status) {
    IconData icon;
    Color color = _getStatusColor(status);
    switch (status) {
      case ReportStatus.pending:
        icon = Icons.hourglass_empty;
        break;
      case ReportStatus.underReview:
      case ReportStatus.underInvestigation:
      case ReportStatus.actionRequired:
      case ReportStatus.assigned:
      case ReportStatus.inProgress:
        icon = Icons.engineering;
        break;
      case ReportStatus.resolved:
        icon = Icons.check_circle_outline;
        break;
      case ReportStatus.rejected:
      case ReportStatus.closed:
        icon = Icons.archive_outlined;
        break;
    }
    return Icon(icon, color: color);
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.underReview:
      case ReportStatus.underInvestigation:
      case ReportStatus.actionRequired:
      case ReportStatus.assigned:
      case ReportStatus.inProgress:
        return Colors.indigo;
      case ReportStatus.resolved:
        return Colors.green;
      case ReportStatus.rejected:
      case ReportStatus.closed:
        return Colors.grey;
    }
  }
}
