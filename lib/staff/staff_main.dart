import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/user.dart';
import 'screens/dashboard_screen.dart';
import 'screens/complaint_list_page.dart';
import 'screens/announcement_management_page.dart';
import 'screens/staff_management_page.dart';
import 'screens/activity_logs_page.dart';
import 'screens/resident_records_page.dart';
import 'screens/system_settings_page.dart';

class StaffMain extends StatefulWidget {
  const StaffMain({super.key});

  @override
  State<StaffMain> createState() => _StaffMainState();
}

class _StaffMainState extends State<StaffMain> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;
    final isAdmin = user?.role == UserRole.admin;

      final List<Widget> pages = [
        const DashboardScreen(),
        const ComplaintListPage(),
        const ResidentRecordsPage(),
        if (isAdmin) const StaffManagementPage() else const Center(child: Text('Access Denied')),
        const AnnouncementManagementPage(),
        const ActivityLogsPage(),
        const SystemSettingsPage(),
      ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Dark Sidebar (Mockup Style)
          Container(
            width: 300,
            color: const Color(0xFF0F172A),
            child: Column(
              children: [
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      const Icon(Icons.shield, color: Color(0xFF38BDF8), size: 36),
                      const SizedBox(width: 12),
                      const Text(
                        'Barangay\nComplaint System',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          height: 1.1,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _sidebarItem(0, Icons.grid_view_rounded, 'Dashboard'),
                      _sidebarItem(1, Icons.chat_bubble_outline_rounded, 'Complaints'),
                      _sidebarItem(2, Icons.people_outline_rounded, 'Residents'),
                      _sidebarItem(3, Icons.badge_outlined, 'Staff Management'),
                      _sidebarItem(4, Icons.campaign_outlined, 'Announcements'),
                      _sidebarItem(5, Icons.history_edu_rounded, 'Activity Logs'),
                      _sidebarItem(6, Icons.settings_outlined, 'System Settings'),
                    ],
                  ),
                ),
                // Admin Account Footer (Mockup Style)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFF1E293B))),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: Color(0xFF38BDF8),
                            child: Icon(Icons.person, color: Color(0xFF0F172A), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.name ?? 'Administrator',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  user?.role.name.toUpperCase() ?? 'ADMIN',
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextButton.icon(
                        onPressed: () => appState.logout(),
                        icon: const Icon(Icons.logout, color: Color(0xFF64748B), size: 18),
                        label: const Text('Logout', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Bar
                Container(
                  height: 80,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    children: [
                      const Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search anything...',
                            prefixIcon: Icon(Icons.search, size: 20),
                            border: InputBorder.none,
                            filled: false,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(icon: const Icon(Icons.notifications_none, color: Color(0xFF64748B)), onPressed: () {}),
                    ],
                  ),
                ),
                // Page Content
                Expanded(child: pages[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(int index, IconData icon, String label) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : const Color(0xFF64748B), size: 20),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
