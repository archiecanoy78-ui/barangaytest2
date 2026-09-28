import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/user.dart';
import 'widgets/app_scaffold.dart';
import 'screens/dashboard_screen.dart';
import 'screens/complaint_list_page.dart';
import 'screens/announcement_management_page.dart';
import 'screens/staff_management_page.dart';
import 'screens/activity_logs_page.dart';
import 'screens/resident_records_page.dart';
import 'screens/system_settings_page.dart';
import 'screens/map_screen.dart';
import 'screens/emergency_map_page.dart';

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
      const MapScreen(),
      const EmergencyMapPage(),
      const ActivityLogsPage(),
      const SystemSettingsPage(),
    ];

    return AppScaffold(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      body: pages[_selectedIndex < pages.length ? _selectedIndex : 0],
    );
  }
}
