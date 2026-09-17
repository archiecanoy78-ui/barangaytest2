import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/assigned_reports_screen.dart';
import 'screens/map_screen.dart';
import 'screens/management_screen.dart';
import 'screens/inbox_screen.dart';
import '../widgets/emergency_banner.dart';

class StaffMain extends StatefulWidget {
  const StaffMain({super.key});

  @override
  State<StaffMain> createState() => _StaffMainState();
}

class _StaffMainState extends State<StaffMain> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const AssignedReportsScreen(),
    const InboxScreen(),
    const MapScreen(),
    const ManagementScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const EmergencyBanner(),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dash'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.inbox), label: 'Inbox'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
        ],
      ),
    );
  }
}
