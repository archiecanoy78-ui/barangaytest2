import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/report.dart';

class EmergencyBanner extends StatelessWidget {
  const EmergencyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final activeSOS = appState.activeSOS;

    if (activeSOS.isEmpty) return const SizedBox.shrink();

    final latestSOS = activeSOS.last;

    return Container(
      width: double.infinity,
      color: Colors.red.shade900,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Icon(Icons.emergency, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'EMERGENCY SOS ALERT',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    '${latestSOS.title} at Purok ${latestSOS.purok}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _showSOSDetails(context, latestSOS),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red.shade900,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              child: const Text('RESPOND'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSOSDetails(BuildContext context, Report sos) {
    final appState = context.read<AppState>();
    
    // Intelligent Dispatch Mapping
    final Map<String, List<String>> teamSuggestions = {
      'Medical': ['Health Center Team', 'Ambulance Unit'],
      'Fire': ['BFP Station 1', 'Barangay Water Tanker'],
      'Security/Police': ['Tanod Patrol Group A', 'PNP Local Station'],
      'Natural Disaster': ['DRRM Rescue Team', 'Evacuation Staff'],
      'Other': ['Barangay Quick Response'],
    };

    String categoryKey = 'Other';
    if (sos.title.contains('Medical')) {
      categoryKey = 'Medical';
    } else if (sos.title.contains('Fire')) {
      categoryKey = 'Fire';
    } else if (sos.title.contains('Security')) {
      categoryKey = 'Security/Police';
    } else if (sos.title.contains('Disaster')) {
      categoryKey = 'Natural Disaster';
    }

    final suggestedTeams = teamSuggestions[categoryKey]!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 10),
            const Text('SOS Detail'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${sos.title}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text('Location: Purok ${sos.purok}'),
            const SizedBox(height: 10),
            const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(sos.description),
            const Divider(),
            const Text('Suggested Dispatch Teams:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            ...suggestedTeams.map((team) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.send, size: 16),
              title: Text(team, style: const TextStyle(fontSize: 13)),
              onTap: () {
                appState.updateReportStatus(sos.id, ReportStatus.assigned);
                appState.addRemarks(sos.id, 'Dispatched: $team');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dispatched $team to Purok ${sos.purok}')));
              },
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE'),
          ),
          ElevatedButton(
            onPressed: () {
              appState.updateReportStatus(sos.id, ReportStatus.resolved);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('RESOLVE'),
          ),
        ],
      ),
    );
  }
}
