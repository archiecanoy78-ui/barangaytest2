import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';

class AnnouncementsList extends StatelessWidget {
  const AnnouncementsList({super.key});

  @override
  Widget build(BuildContext context) {
    final announcements = context.watch<AppState>().announcements;

    return Scaffold(
      appBar: AppBar(title: const Text('Barangay Announcements')),
      body: announcements.isEmpty
          ? const Center(child: Text('No announcements at this time.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: announcements.length,
              itemBuilder: (context, index) {
                final ann = announcements[index];
                return Card(
                  margin: const EdgeInsets.bottom(16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                ann.type.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              "${ann.date.toLocal()}".split(' ')[0],
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          ann.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          ann.content,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
