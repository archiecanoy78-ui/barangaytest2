import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/user.dart';

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser!;
    
    String position = 'Barangay Staff';
    if (user.staffRole == StaffRole.captain) position = 'Barangay Captain';
    if (user.staffRole == StaffRole.secretary) position = 'Barangay Secretary';

    final messages = appState.getMessagesForRole(position);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Inbox'),
        elevation: 0,
      ),
      body: messages.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: const Icon(Icons.person, color: Colors.blue),
                    ),
                    title: Text(msg.senderName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(msg.content),
                        const SizedBox(height: 4),
                        Text(
                          '${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')} - ${msg.timestamp.day}/${msg.timestamp.month}',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mail_outline, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No messages yet',
            style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Direct inquiries from residents will appear here.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
