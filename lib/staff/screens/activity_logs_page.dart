import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';

class ActivityLogsPage extends StatelessWidget {
  const ActivityLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final logs = context.watch<AppState>().activityLogs;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Activity Logs'), backgroundColor: Colors.white, elevation: 0),
      body: Container(
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              columns: const [
                DataColumn(label: Text('Date/Time')),
                DataColumn(label: Text('User')),
                DataColumn(label: Text('Action')),
                DataColumn(label: Text('Complaint ID')),
                DataColumn(label: Text('Description')),
              ],
              rows: logs.map((log) {
                return DataRow(cells: [
                  DataCell(Text(log.timestamp.toString().split('.')[0])),
                  DataCell(Text(log.user, style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(_actionBadge(log.action)),
                  DataCell(Text(log.complaintId, style: const TextStyle(color: Color(0xFF2563EB)))),
                  DataCell(Text(log.description)),
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionBadge(String action) {
    Color color = Colors.blue;
    if (action.contains('Filed')) color = Colors.green;
    if (action.contains('Login')) color = Colors.indigo;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(action, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
