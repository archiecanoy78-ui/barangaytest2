import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/user.dart';
import 'screens/home_screen.dart';
import 'screens/services_screen.dart';
import 'screens/directory_screen.dart';
import 'screens/profile_screen.dart';
import '../widgets/centralized_report_modal.dart';

class ResidentMain extends StatefulWidget {
  const ResidentMain({super.key});

  @override
  State<ResidentMain> createState() => _ResidentMainState();
}

class _ResidentMainState extends State<ResidentMain> {
  int _selectedIndex = 0;

  List<Widget> _getScreens(UserRole role) {
    if (role == UserRole.guest) {
      return const [HomeScreen()];
    }
    return const [
      HomeScreen(),
      ServicesScreen(),
      DirectoryScreen(),
      ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final role = Provider.of<AppState>(context).currentUser?.role ?? UserRole.guest;
    final List<Widget> _screens = _getScreens(role);
    if (_selectedIndex >= _screens.length) {
      _selectedIndex = 0;
    }


    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: _buildPixelReferenceBottomBar(context, role),
    );
  }

  /// Exact Bottom Navigation Bar matching the reference UI screenshot
  Widget _buildPixelReferenceBottomBar(BuildContext context, UserRole role) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 72,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Home (always present)
                  _buildNavItem(
                    index: 0,
                    icon: Icons.home_rounded,
                    label: 'Home',
                  ),

                  // Show other tabs only for non‑guest users
                  if (role != UserRole.guest) ...[
                    _buildNavItem(
                      index: 1,
                      icon: Icons.assignment_turned_in_outlined,
                      label: 'Services',
                    ),
                    // Centralized Report button now positioned between Services and Directory
                    _buildCenterReportButton(context),
                    _buildNavItem(
                      index: 2,
                      icon: Icons.groups_outlined,
                      label: 'Directory',
                    ),
                    _buildNavItem(
                      index: 3,
                      icon: Icons.person_outline_rounded,
                      label: 'Profile',
                    ),
                  ],

                  // For guest users only the report button (center) remains
                  if (role == UserRole.guest) _buildCenterReportButton(context),
                ],
              ),
            ),

            // iOS / Modern home indicator bar at bottom
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0, top: 2.0),
              child: Container(
                width: 134,
                height: 4.5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedIndex == index;
    final activeColor = const Color(0xFF1D4ED8); // Reference blue
    final inactiveColor = const Color(0xFF64748B);

    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 62,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Floating Center Megaphone Button matching the exact orange circular styling in reference
  Widget _buildCenterReportButton(BuildContext context) {
    return GestureDetector(
      onTap: () => showCentralizedReportModal(context),
      child: SizedBox(
        width: 62,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF7A00), Color(0xFFFF4838)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5722).withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.campaign_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Report',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFFEA580C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
