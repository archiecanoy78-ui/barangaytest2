import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/announcement.dart';

class AnnouncementManagementPage extends StatefulWidget {
  const AnnouncementManagementPage({super.key});

  @override
  State<AnnouncementManagementPage> createState() => _AnnouncementManagementPageState();
}

class _AnnouncementManagementPageState extends State<AnnouncementManagementPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedType = 'Announcement';

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Announcement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: ['Announcement', 'Event', 'Alert'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _selectedType = v!),
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _contentController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Content', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final ann = Announcement(
                title: _titleController.text,
                content: _contentController.text,
                date: DateTime.now(),
                type: _selectedType,
              );
              context.read<AppState>().addAnnouncement(ann);
              Navigator.pop(context);
              _titleController.clear();
              _contentController.clear();
            },
            child: const Text('Publish'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final announcements = context.watch<AppState>().announcements;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcement Management'),
        actions: [
          ElevatedButton.icon(
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add),
            label: const Text('New Announcement'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: announcements.length,
        itemBuilder: (context, index) {
          final ann = announcements[index];
          return Card(
            margin: const EdgeInsets.bottom(16),
            child: ListTile(
              title: Text(ann.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("${ann.type} - ${ann.date.toString().split(' ')[0]}"),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => context.read<AppState>().deleteAnnouncement(ann.title),
              ),
            ),
          );
        },
      ),
    );
  }
}
