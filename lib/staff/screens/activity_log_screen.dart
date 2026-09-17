import 'package:flutter/material.dart';

class ActivityLogScreen extends StatelessWidget {
  const ActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity Log')),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.check_circle, color: Colors.green),
            title: Text('Resolved Waste Management Issue'),
            subtitle: Text('2 hours ago'),
          ),
          ListTile(
            leading: Icon(Icons.play_arrow, color: Colors.orange),
            title: Text('Started working on Noise Complaint'),
            subtitle: Text('5 hours ago'),
          ),
        ],
      ),
    );
  }
}
