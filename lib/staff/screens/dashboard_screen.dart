import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final counts = appState.getReportCountsByStatus();
    final total = appState.reports.length;
    final verified = counts['verified'] ?? 0;
    final pending = counts['pending'] ?? 0;
    final assigned = counts['assigned'] ?? 0;
    final inProgress = counts['underInvestigation'] ?? 0;
    final resolved = counts['resolved'] ?? 0;
    final closed = counts['closed'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '1:05',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                  ),
                  Row(
                    children: const [
                      Icon(Icons.signal_cellular_4_bar_rounded, size: 16),
                      SizedBox(width: 6),
                      Icon(Icons.wifi_rounded, size: 16),
                      SizedBox(width: 6),
                      Icon(Icons.battery_5_bar_rounded, size: 16),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 18),
                    const Text(
                      'Admin Dashboard',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E88E5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'E-Reportyan Admin',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'Total Incidents Logged',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFFDDEEFF),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '$total',
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _statInline('Verified', verified),
                              const SizedBox(width: 28),
                              _statInline('Pending', pending),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Operational Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      shrinkWrap: true,
                      childAspectRatio: 1.8,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _overviewTile(
                          'Assigned',
                          assigned,
                          const Color(0xFFF1F5F9),
                          const Color(0xFF0F172A),
                        ),
                        _overviewTile(
                          'In Progress',
                          inProgress,
                          const Color(0xFFF1F5F9),
                          const Color(0xFF0F172A),
                        ),
                        _overviewTile(
                          'Resolved',
                          resolved,
                          const Color(0xFFE8F5E9),
                          const Color(0xFF1F9D55),
                        ),
                        _overviewTile(
                          'Closed',
                          closed,
                          const Color(0xFFF1F5F9),
                          const Color(0xFF0F172A),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: const [
                          BottomNavItem(Icons.grid_view_rounded, 'Dash', true),
                          BottomNavItem(Icons.inbox_outlined, 'Inbox', false),
                          BottomNavItem(Icons.map_outlined, 'Map', false),
                          BottomNavItem(
                            Icons.people_outline_rounded,
                            'Users',
                            false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statInline(String label, int value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _overviewTile(
    String title,
    int value,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const BottomNavItem(this.icon, this.label, this.selected);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 22,
          color: selected ? const Color(0xFF1E88E5) : const Color(0xFF64748B),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: selected ? const Color(0xFF1E88E5) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
