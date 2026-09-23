import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';

class ResidentRecordsPage extends StatelessWidget {
  const ResidentRecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = context.watch<AppState>().reports;
    
    // Group reports by complainant to get resident records
    final Map<String, List<dynamic>> residents = {};
    for (var r in reports) {
      if (!residents.containsKey(r.complainantPhone)) {
        residents[r.complainantPhone] = [r.complainantName, r.complainantPhone, r.complainantEmail ?? 'N/A', 0, r.timestamp];
      }
      residents[r.complainantPhone]![3] += 1;
      if (r.timestamp.isAfter(residents[r.complainantPhone]![4])) {
        residents[r.complainantPhone]![4] = r.timestamp;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('Residents / Complainants'), backgroundColor: Colors.white, elevation: 0),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Search resident name...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: Container(
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
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Phone')),
                      DataColumn(label: Text('Total Complaints')),
                      DataColumn(label: Text('Last Report')),
                      DataColumn(label: Text('Action')),
                    ],
                    rows: residents.values.map((res) {
                      return DataRow(cells: [
                        DataCell(Text(res[0])),
                        DataCell(Text(res[1])),
                        DataCell(Text(res[3].toString())),
                        DataCell(Text(res[4].toString().split(' ')[0])),
                        DataCell(TextButton(onPressed: () {}, child: const Text('View'))),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
