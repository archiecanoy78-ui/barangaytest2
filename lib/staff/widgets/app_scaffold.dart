import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/user.dart';
import '../../models/report.dart';
import 'portal_theme.dart';
import '../screens/complaint_details_page.dart';

class AppScaffold extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;

  const AppScaffold({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  void _showNotificationsModal(BuildContext context) {
    final appState = context.read<AppState>();
    appState.markNotificationsAsRead();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Staff & Admin Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: () => Navigator.pop(ctx),
              tooltip: 'Close',
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          height: 400,
          child: appState.staffNotifications.isEmpty
              ? const Center(child: Text('No new notifications.', style: TextStyle(color: PortalColors.textMuted)))
              : ListView.separated(
                  itemCount: appState.staffNotifications.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: PortalColors.border),
                  itemBuilder: (context, index) {
                    final n = appState.staffNotifications[index];
                    final isEmergency = n['isEmergency'] == true;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isEmergency ? PortalColors.dangerBg : PortalColors.blue50,
                        child: Icon(
                          isEmergency ? Icons.warning_amber_rounded : Icons.notifications_rounded,
                          color: isEmergency ? PortalColors.danger : PortalColors.primary,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        n['title'] ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isEmergency ? PortalColors.danger : PortalColors.textDark,
                        ),
                      ),
                      subtitle: Text(
                        n['subtitle'] ?? '',
                        style: const TextStyle(fontSize: 12, color: PortalColors.textMuted),
                      ),
                      onTap: () async {
                        final report = n['report'] as Report?;
                        if (report != null) {
                          await appState.markReportAsRead(report.id);
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (report != null && context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ComplaintDetailsPage(report: report)),
                          );
                        }
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser;
    final isAdmin = user?.role == UserRole.admin;
    final complaintCount = appState.reports.length;

    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 1024;

    Widget sidebarContent({bool isDrawer = false}) => Container(
      width: 260,
      color: const Color(0xFFF8F9FC),
      child: Column(
        children: [
          // Branding Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: PortalColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [PortalColors.primary, PortalColors.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Color(0x1A4F46E5), blurRadius: 8, offset: Offset(0, 4)),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'BRGY',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Barangay Admin',
                        style: TextStyle(
                          color: PortalColors.textDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Web Management Portal',
                        style: TextStyle(
                          color: PortalColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isDrawer)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Navigation Links List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Text('OVERVIEW', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: PortalColors.textMuted)),
                ),
                _navItem(0, Icons.grid_view_rounded, 'Dashboard', isDrawer: isDrawer),
                _navItem(1, Icons.chat_bubble_outline_rounded, 'Complaints', badge: complaintCount, isDrawer: isDrawer),
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 16, 12, 8),
                  child: Text('OPERATIONS', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: PortalColors.textMuted)),
                ),
                _navItem(2, Icons.people_outline_rounded, 'Residents', isDrawer: isDrawer),
                if (isAdmin) _navItem(3, Icons.badge_outlined, 'Staff Management', isDrawer: isDrawer),
                _navItem(4, Icons.forum_outlined, 'Messages', isDrawer: isDrawer),
                _navItem(5, Icons.campaign_outlined, 'Announcements', isDrawer: isDrawer),
                _navItem(6, Icons.map_outlined, 'Operations Map', isDrawer: isDrawer),
                _navItem(7, Icons.crisis_alert_rounded, 'Emergency Map', isDrawer: isDrawer),
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 16, 12, 8),
                  child: Text('SYSTEM', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: PortalColors.textMuted)),
                ),
                _navItem(8, Icons.history_edu_rounded, 'Activity Logs', isDrawer: isDrawer),
                _navItem(9, Icons.settings_outlined, 'System Settings', isDrawer: isDrawer),
              ],
            ),
          ),

          // User Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: PortalColors.border)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: PortalColors.blue50,
                  child: Text(
                    (user?.name.isNotEmpty ?? false) ? user!.name.substring(0, 2).toUpperCase() : 'AD',
                    style: const TextStyle(color: PortalColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Administrator',
                        style: const TextStyle(color: PortalColors.textDark, fontWeight: FontWeight.bold, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Active Session',
                        style: TextStyle(color: PortalColors.success, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Tooltip(
                  message: 'Sign Out',
                  child: IconButton(
                    icon: const Icon(Icons.logout_rounded, color: PortalColors.textMuted, size: 18),
                    onPressed: () => appState.logout(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: PortalColors.background,
      drawer: isDesktop ? null : Drawer(child: sidebarContent(isDrawer: true)),
      body: Row(
        children: [
          if (isDesktop) sidebarContent(),
          Expanded(
            child: Column(
              children: [
                // Top Action Bar
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: const BoxDecoration(
                    color: PortalColors.surface,
                    border: Border(bottom: BorderSide(color: PortalColors.border)),
                  ),
                  child: Row(
                    children: [
                      if (!isDesktop) ...[
                        Builder(
                          builder: (context) => Tooltip(
                            message: 'Open Navigation Menu',
                            child: IconButton(
                              icon: const Icon(Icons.menu_rounded, color: PortalColors.textDark, size: 22),
                              onPressed: () => Scaffold.of(context).openDrawer(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Barangay Portal',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: PortalColors.textDark),
                        ),
                      ],
                      const Spacer(),
                      Consumer<AppState>(
                        builder: (context, appState, _) {
                          final unreadCount = appState.unreadStaffNotificationsCount;
                          return Tooltip(
                            message: 'Notifications',
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                IconButton(
                                  onPressed: () => _showNotificationsModal(context),
                                  icon: const Icon(Icons.notifications_none_rounded, color: PortalColors.textDark, size: 22),
                                ),
                                if (unreadCount > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: PortalColors.danger,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Main Dashboard Body
                Expanded(child: widget.body),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, {int? badge, bool isDrawer = false}) {
    final bool isSelected = widget.selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? PortalColors.primary.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          if (isSelected)
            Positioned(
              left: 0,
              top: 6,
              bottom: 6,
              child: Container(
                width: 3.5,
                decoration: BoxDecoration(
                  color: PortalColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ListTile(
            minVerticalPadding: 12,
            onTap: () {
              if (isDrawer) Navigator.pop(context);
              widget.onDestinationSelected(index);
            },
            leading: Icon(
              icon,
              size: 20,
              color: isSelected ? PortalColors.primary : PortalColors.textMuted,
            ),
            title: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? PortalColors.primary : PortalColors.textDark,
              ),
            ),
            trailing: badge != null && badge > 0
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: PortalColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(color: PortalColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  )
                : null,
            dense: true,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ],
      ),
    );
  }
}
