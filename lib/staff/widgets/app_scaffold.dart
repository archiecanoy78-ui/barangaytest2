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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Staff & Admin Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: () => Navigator.pop(ctx),
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
                        backgroundColor: isEmergency ? PortalColors.danger.withOpacity(0.15) : PortalColors.primary.withOpacity(0.1),
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
                        style: const TextStyle(fontSize: 11, color: PortalColors.textMuted),
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
    final bool isWide = screenWidth >= 900;

    final sidebarContent = Container(
      width: 260,
      color: const Color(0xFFF8F8FB),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                      BoxShadow(color: Color(0x1A6366F1), blurRadius: 8, offset: Offset(0, 4)),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'BP',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Barangay Portal',
                        style: TextStyle(
                          color: PortalColors.textDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Official Admin Console',
                        style: TextStyle(
                          color: PortalColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 4, 12, 10),
                  child: Text('OVERVIEW', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: PortalColors.textMuted)),
                ),
                _navItem(0, Icons.grid_view_rounded, 'Dashboard'),
                _navItem(1, Icons.chat_bubble_outline_rounded, 'Complaints', badge: complaintCount),
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 18, 12, 10),
                  child: Text('OPERATIONS', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: PortalColors.textMuted)),
                ),
                _navItem(2, Icons.people_outline_rounded, 'Residents'),
                if (isAdmin) _navItem(3, Icons.badge_outlined, 'Staff Management'),
                _navItem(4, Icons.campaign_outlined, 'Announcements'),
                _navItem(5, Icons.map_outlined, 'Operations Map'),
                _navItem(6, Icons.crisis_alert_rounded, 'Emergency Map'),
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 18, 12, 10),
                  child: Text('SYSTEM', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700, color: PortalColors.textMuted)),
                ),
                _navItem(7, Icons.history_edu_rounded, 'Activity Logs'),
                _navItem(8, Icons.settings_outlined, 'System Settings'),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: PortalColors.border)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: PortalColors.primary.withOpacity(0.08),
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
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: PortalColors.textMuted, size: 18),
                  onPressed: () => appState.logout(),
                  tooltip: 'Logout',
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: PortalColors.background,
      drawer: isWide ? null : Drawer(child: sidebarContent),
      body: Row(
        children: [
          if (isWide) sidebarContent,
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 72,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: PortalColors.surface,
                    border: Border(bottom: BorderSide(color: PortalColors.border)),
                  ),
                  child: Row(
                    children: [
                      if (!isWide) ...[
                        Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.menu_rounded),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      const Spacer(),
                      Consumer<AppState>(
                        builder: (context, appState, _) {
                          final unreadCount = appState.unreadStaffNotificationsCount;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOut,
                                child: IconButton(
                                  onPressed: () => _showNotificationsModal(context),
                                  icon: const Icon(Icons.notifications_none_rounded, color: PortalColors.textDark),
                                ),
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  right: 10,
                                  top: 8,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: PortalColors.danger,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Main Content View
                Expanded(child: widget.body),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, {int? badge}) {
    final bool isSelected = widget.selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? PortalColors.primary.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Stack(
        children: [
          if (isSelected)
            Positioned(
              left: 0,
              top: 8,
              bottom: 8,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: PortalColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ListTile(
            onTap: () => widget.onDestinationSelected(index),
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: PortalColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(color: PortalColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  )
                : null,
            dense: true,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
        ],
      ),
    );
  }
}
