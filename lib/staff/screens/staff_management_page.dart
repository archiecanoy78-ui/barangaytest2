import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/user.dart';

class StaffManagementPage extends StatelessWidget {
  const StaffManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final staffList = context.watch<AppState>().staffList;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Implementation for adding new staff
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add Staff functionality coming soon.')));
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Add Staff'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Role')),
              DataColumn(label: Text('Position')),
              DataColumn(label: Text('Username')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Actions')),
            ],
            rows: staffList.map((s) {
              return DataRow(cells: [
                DataCell(Text(s.name)),
                DataCell(Text(s.role.name.toUpperCase())),
                DataCell(Text(s.staffRole?.name ?? 'N/A')),
                DataCell(Text(s.username ?? 'N/A')),
                DataCell(Text(s.isArchived ? 'Inactive' : 'Active')),
                DataCell(Row(
                  children: [
                    IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.block), color: Colors.red, onPressed: () {}),
                  ],
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}
