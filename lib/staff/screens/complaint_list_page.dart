import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/report.dart';
import 'complaint_details_page.dart';

class ComplaintListPage extends StatefulWidget {
  const ComplaintListPage({super.key});

  @override
  State<ComplaintListPage> createState() => _ComplaintListPageState();
}

class _ComplaintListPageState extends State<ComplaintListPage> {
  String _searchQuery = '';
  ReportStatus? _filterStatus;
  String? _filterCategory;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final categories = appState.categories;

    List<Report> filteredReports = appState.reports.where((r) {
      final matchesSearch = r.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.complainantName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.description.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesStatus = _filterStatus == null || r.status == _filterStatus;
      final matchesCategory = _filterCategory == null || r.category == _filterCategory;

      return matchesSearch && matchesStatus && matchesCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaint Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by ID, Name, or Keywords...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<ReportStatus>(
                    decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                    value: _filterStatus,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Status')),
                      ...ReportStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name))),
                    ],
                    onChanged: (v) => setState(() => _filterStatus = v),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    value: _filterCategory,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Categories')),
                      ...categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                    ],
                    onChanged: (v) => setState(() => _filterCategory = v),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: filteredReports.isEmpty
                ? const Center(child: Text('No complaints found.'))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        showCheckboxColumn: false,
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Complainant')),
                          DataColumn(label: Text('Category')),
                          DataColumn(label: Text('Submitted')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Priority')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: filteredReports.map((r) {
                          return DataRow(
                            onSelectChanged: (_) => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ComplaintDetailsPage(report: r)),
                            ),
                            cells: [
                              DataCell(Text(r.id)),
                              DataCell(Text(r.complainantName)),
                              DataCell(Text(r.category)),
                              DataCell(Text(r.timestamp.toString().split(' ')[0])),
                              DataCell(_buildStatusChip(r.status)),
                              DataCell(Text(r.priority)),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.visibility),
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => ComplaintDetailsPage(report: r)),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ReportStatus status) {
    Color color;
    switch (status) {
      case ReportStatus.pending: color = Colors.orange; break;
      case ReportStatus.underReview: color = Colors.blue; break;
      case ReportStatus.underInvestigation: color = Colors.indigo; break;
      case ReportStatus.actionRequired: color = Colors.red; break;
      case ReportStatus.resolved: color = Colors.green; break;
      case ReportStatus.rejected: color = Colors.grey; break;
      case ReportStatus.closed: color = Colors.black54; break;
    }

    return Chip(
      label: Text(status.name.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white)),
      backgroundColor: color,
      padding: EdgeInsets.zero,
    );
  }
}
