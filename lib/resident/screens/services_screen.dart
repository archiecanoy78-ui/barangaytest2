import 'package:flutter/material.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barangay Programs', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Featured programs
          const Text('Featured Programs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildProgramCard(
            context,
            title: '4Ps (Pantawid Pamilyang Pilipino Program)',
            description: 'Conditional cash assistance for qualified low‑income families.',
            nextSchedule: 'Next disbursement: 15 Oct 2026',
            icon: Icons.attach_money_rounded,
            color: Colors.indigo,
            isFeatured: true,
          ),
          _buildProgramCard(
            context,
            title: 'PWD Assistance',
            description: 'Medical, transport, and livelihood support for persons with disability.',
            nextSchedule: 'Medical camp: 22 Oct 2026',
            icon: Icons.accessibility_new_rounded,
            color: Colors.teal,
            isFeatured: true,
          ),
          const SizedBox(height: 24),
          const Text('All Programs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          // Full list of programs
          _buildProgramCard(
            context,
            title: 'Senior Citizen Benefits',
            description: 'Discounts, free health check‑ups, and livelihood aid for senior citizens.',
            nextSchedule: 'Free health check‑up: 30 Sep 2026',
            icon: Icons.elderly_rounded,
            color: Colors.orange,
          ),
          _buildProgramCard(
            context,
            title: 'Educational Assistance',
            description: 'Scholarships, school supplies, and tuition subsidies for students.',
            nextSchedule: 'Application deadline: 31 Oct 2026',
            icon: Icons.school_rounded,
            color: Colors.blue,
          ),
          _buildProgramCard(
            context,
            title: 'AICS (Assistance to Individuals in Crisis Situations)',
            description: 'Emergency financial aid for families facing sudden crises.',
            nextSchedule: 'Open until: 10 Nov 2026',
            icon: Icons.warning_amber_rounded,
            color: Colors.red,
          ),
          _buildProgramCard(
            context,
            title: 'Free Legal Aid',
            description: 'Mediation and legal counseling services for residents.',
            nextSchedule: 'Legal aid clinic: Every Mon & Thu',
            icon: Icons.gavel_rounded,
            color: Colors.green,
          ),
          // Add more program cards here as needed
        ],
      ),
    );
  }

  Widget _buildProgramCard(
    BuildContext context, {
    required String title,
    required String description,
    required String nextSchedule,
    required IconData icon,
    required MaterialColor color,
    bool isFeatured = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: isFeatured ? 4 : 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: color.shade50,
                  child: Icon(icon, color: color.shade700, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded, size: 13, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(nextSchedule,
                              style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(description,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.3)),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showProgramInfo(context, title, description, nextSchedule),
                icon: const Icon(Icons.info_rounded, size: 18),
                label: const Text('Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProgramInfo(
      BuildContext context, String title, String description, String schedule) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            const SizedBox(height: 8),
            Row(
              children: const [
                Icon(Icons.schedule_rounded, size: 16, color: Colors.grey),
                SizedBox(width: 6),
              ],
            ),
            const SizedBox(height: 4),
            Text(schedule, style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
