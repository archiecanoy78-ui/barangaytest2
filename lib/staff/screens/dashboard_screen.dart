import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/report.dart';
import '../../models/announcement.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final statusCounts = appState.getReportCountsByStatus();
    final categoryCounts = appState.getReportCountsByCategory();
    final user = appState.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Stack(
        children: [
          // Background glow blobs
          Positioned(
            top: -60,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2563EB).withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 150,
            left: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1D4ED8).withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 12),

                // ── Top Bar ──────────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'BARANGAY CENTRAL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.55),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Staff Dashboard',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => appState.logout(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.logout_rounded,
                                color: Colors.white.withValues(alpha: 0.8), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Sign Out',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Hero Summary Card ─────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1D4ED8).withValues(alpha: 0.5),
                        blurRadius: 28,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Staff badge
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.shield_rounded,
                                color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name ?? 'Staff Member',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                user?.staffRole?.name.toUpperCase() ?? 'STAFF',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 10,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Total Incidents Logged',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appState.reports.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Mini stats row
                      Row(
                        children: [
                          _buildMiniStatChip(
                            'Verified Residents',
                            appState.allUsers
                                .where((u) => u.isVerified)
                                .length
                                .toString(),
                            Icons.verified_user_rounded,
                          ),
                          const SizedBox(width: 12),
                          _buildMiniStatChip(
                            'Pending',
                            appState.reports
                                .where((r) => r.status == ReportStatus.pending)
                                .length
                                .toString(),
                            Icons.pending_actions_rounded,
                          ),
                          const SizedBox(width: 12),
                          _buildMiniStatChip(
                            'Total Users',
                            appState.allUsers.length.toString(),
                            Icons.group_rounded,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Operational Overview ──────────────────────────────────────
                _buildSectionLabel('Operational Overview'),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.55,
                  children: [
                    _buildStatusCard(
                      'Assigned',
                      statusCounts[ReportStatus.assigned.name] ?? 0,
                      const Color(0xFF3B82F6),
                      Icons.assignment_ind_rounded,
                    ),
                    _buildStatusCard(
                      'In Progress',
                      statusCounts[ReportStatus.inProgress.name] ?? 0,
                      const Color(0xFF8B5CF6),
                      Icons.pending_rounded,
                    ),
                    _buildStatusCard(
                      'Resolved',
                      statusCounts[ReportStatus.resolved.name] ?? 0,
                      const Color(0xFF10B981),
                      Icons.check_circle_rounded,
                    ),
                    _buildStatusCard(
                      'Closed',
                      statusCounts[ReportStatus.closed.name] ?? 0,
                      const Color(0xFF64748B),
                      Icons.archive_rounded,
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ── Reports by Category ───────────────────────────────────────
                _buildSectionLabel('Reports by Category'),
                const SizedBox(height: 14),
                if (categoryCounts.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2744),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.inbox_rounded,
                            color: Colors.white.withValues(alpha: 0.25), size: 40),
                        const SizedBox(height: 10),
                        Text(
                          'No reports yet',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...categoryCounts.entries.map((e) => _buildCategoryRow(e.key, e.value)),

                const SizedBox(height: 28),

                // ── Broadcast Announcement ────────────────────────────────────
                _buildSectionLabel('Quick Actions'),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => _showAnnouncementForm(context),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A2744),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1D4ED8).withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.campaign_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Post Announcement',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'Broadcast to all residents',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Icon(Icons.arrow_forward_ios_rounded,
                            color: Colors.white.withValues(alpha: 0.3), size: 16),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatChip(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.75), size: 16),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildStatusCard(String title, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2744),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(String category, int count) {
    const colors = [
      Color(0xFF3B82F6),
      Color(0xFF8B5CF6),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
    ];
    final color = colors[category.hashCode % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2744),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              category,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAnnouncementForm(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String type = 'Alert';
    String? mockImageUrl;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F1E36),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 24,
            right: 24,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Broadcast Announcement',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'This will be sent to all residents.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              _modalTextField(titleController, 'Announcement Title', Icons.title_rounded),
              const SizedBox(height: 14),
              // Type picker
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2744),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: type,
                    dropdownColor: const Color(0xFF1A2744),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    icon: Icon(Icons.expand_more_rounded,
                        color: Colors.white.withValues(alpha: 0.5)),
                    items: ['Alert', 'Event', 'News']
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t,
                                  style: const TextStyle(color: Colors.white)),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => type = val!),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _modalTextField(contentController, 'Message Content', Icons.message_rounded, maxLines: 4),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () {
                  setState(() => mockImageUrl = 'mock_img.jpg');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Image attached.')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2744),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: mockImageUrl != null
                          ? const Color(0xFF10B981)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        mockImageUrl != null ? Icons.image_rounded : Icons.add_a_photo_rounded,
                        color: mockImageUrl != null
                            ? const Color(0xFF10B981)
                            : Colors.white.withValues(alpha: 0.4),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        mockImageUrl != null ? '✓ Image Attached' : 'Add Header Image (Optional)',
                        style: TextStyle(
                          color: mockImageUrl != null
                              ? const Color(0xFF10B981)
                              : Colors.white.withValues(alpha: 0.4),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  if (titleController.text.isNotEmpty &&
                      contentController.text.isNotEmpty) {
                    context.read<AppState>().addAnnouncement(Announcement(
                          title: titleController.text,
                          content: contentController.text,
                          date: DateTime.now(),
                          type: type,
                          imageUrl: mockImageUrl,
                        ));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Announcement broadcasted!')),
                    );
                  }
                },
                icon: const Icon(Icons.send_rounded),
                label: const Text('Post Now',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modalTextField(
      TextEditingController ctrl, String hint, IconData icon,
      {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A2744),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
          prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.4), size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
