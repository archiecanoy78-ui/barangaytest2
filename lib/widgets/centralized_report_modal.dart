import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/user.dart';
import '../resident/screens/reports_screen.dart';
import 'report_form.dart';
import 'sos_modal.dart';

void showCentralizedReportModal(BuildContext context) {
  final user = context.read<AppState>().currentUser;
  final isGuest = user?.role == UserRole.guest;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade700, Colors.deepOrange.shade600],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Centralized Report Portal',
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Choose the option that matches your situation',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Option 1: Emergency SOS / Urgent Dispatch
          _buildReportOptionCard(
            context,
            title: 'Emergency Assistance (SOS)',
            badge: 'URGENT DISPATCH',
            badgeColor: Colors.red.shade800,
            badgeBgColor: Colors.red.shade50,
            description: 'Immediate response for medical emergencies, fire hazards, natural disasters, or active crimes.',
            icon: Icons.crisis_alert_rounded,
            gradientColors: [Colors.red.shade600, Colors.red.shade900],
            borderColor: Colors.red.shade200,
            cardBgColor: Colors.red.shade50.withValues(alpha: 0.35),
            onTap: () {
              Navigator.pop(context);
              showSOSModal(context);
            },
          ),
          const SizedBox(height: 14),

          // Option 2: Standard Community Report (Normal) – only for non‑guest
          if (!isGuest) ...[
            _buildReportOptionCard(
              context,
              title: 'Standard Community Report',
              badge: 'CIVIC TICKET',
              badgeColor: Colors.orange.shade900,
              badgeBgColor: Colors.orange.shade50,
              description: 'Report waste disposal, streetlight breakdown, noise disturbance, road hazards, or public concerns.',
              icon: Icons.campaign_rounded,
              gradientColors: [Colors.orange.shade600, Colors.deepOrange.shade700],
              borderColor: Colors.orange.shade200,
              cardBgColor: Colors.orange.shade50.withValues(alpha: 0.35),
              onTap: () {
                Navigator.pop(context);
                showReportForm(context);
              },
            ),
            const SizedBox(height: 14),
          ],

          // Option 3: View Reports & Community Feed (for verified residents)
          if (!isGuest) ...[
            InkWell(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReportsScreen()),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.blue.shade50,
                      child: Icon(Icons.assignment_outlined, color: Colors.blue.shade800, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('View Filed Reports & Neighborhood Feed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('Track status updates and confirm nearby reports', style: TextStyle(color: Colors.black54, fontSize: 11)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

Widget _buildReportOptionCard(
  BuildContext context, {
  required String title,
  required String badge,
  required Color badgeColor,
  required Color badgeBgColor,
  required String description,
  required IconData icon,
  required List<Color> gradientColors,
  required Color borderColor,
  required Color cardBgColor,
  required VoidCallback onTap,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[0].withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeBgColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: badgeColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Padding(
              padding: EdgeInsets.only(top: 14),
              child: Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    ),
  );
}
