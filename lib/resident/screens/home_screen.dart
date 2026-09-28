import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/user.dart';
import '../../widgets/centralized_report_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'All Updates';
  String _currentSort = 'Newest';

  // Social feed interactive states
  final Set<String> _likedPosts = {};
  final Set<String> _savedPosts = {};

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    final allAnnouncements = appState.announcements.map((ann) => {
      'id': ann.id ?? 'ann_${ann.hashCode}',
      'avatarText': 'BRG',
      'avatarBg': const Color(0xFFD6E4FF),
      'avatarColor': const Color(0xFF1D39C4),
      'author': 'Barangay Official',
      'isVerified': true,
      'subtitle': ann.zone.isNotEmpty ? ann.zone : 'Barangay Office',
      'time': '${ann.date.toLocal()}'.split(' ')[0],
      'category': ann.type,
      'tagText': ann.priority,
      'tagBg': const Color(0xFFE3F2FD),
      'tagColor': const Color(0xFF1565C0),
      'title': ann.title,
      'content': ann.content,
      'likes': 10,
      'comments': 2,
    }).toList();

    // Filter announcements based on active category
    final filteredAnnouncements = _selectedCategory == 'All Updates'
        ? allAnnouncements
        : allAnnouncements.where((a) => a['category'] == _selectedCategory).toList();

    final bool isGuest = appState.currentUser?.role == UserRole.guest;
    if (isGuest) {
      return _buildGuestScreen(context, appState);
    }


    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            const SizedBox(height: 12),

            // Top Status Bar: Location Tag & Actions
            _buildTopBar(context, appState),
            const SizedBox(height: 16),

            // Filter Chips Carousel
            _buildFilterChips(),
            const SizedBox(height: 18),

            // High Priority Featured Alert Card
            _buildHighPriorityCard(context),
            const SizedBox(height: 14),

            // Need Community Assistance? Report Banner
            _buildAssistanceBanner(context),
            const SizedBox(height: 20),

            // Community Feed Header
            _buildFeedHeader(),
            const SizedBox(height: 12),

            // Community Feed Cards
            if (filteredAnnouncements.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'No announcements in $_selectedCategory',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ),
              )
            else
              ...filteredAnnouncements.map((post) => _buildFeedCard(post)),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// ─── GUEST SCREEN ───────────────────────────────────────────────────────────
  Widget _buildGuestScreen(BuildContext context, AppState appState) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Stack(
        children: [
          // Background gradient blobs
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2563EB).withOpacity(0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1D4ED8).withOpacity(0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Top App Bar ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8, height: 8,
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
                                  color: Colors.white.withOpacity(0.55),
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Guest Access',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      // Logout button
                      GestureDetector(
                        onTap: () => appState.logout(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.logout_rounded, color: Colors.white.withOpacity(0.8), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Sign Out',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
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
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // ── Hero / Welcome Card ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF3B82F6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1D4ED8).withOpacity(0.45),
                                blurRadius: 28,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.waving_hand_rounded, color: Colors.white, size: 28),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Welcome, Guest!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'You\'re browsing as a guest. Sign up to unlock all barangay services, announcements, and community features.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 13.5,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => appState.logout(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF1D4ED8),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    '✨  Create Free Account',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Locked features ──
                        Text(
                          'Unlock These Features',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 12),

                        _buildLockedFeatureRow(
                          icon: Icons.campaign_rounded,
                          color: const Color(0xFF8B5CF6),
                          title: 'Live Announcements',
                          subtitle: 'Stay updated with official barangay news',
                        ),
                        const SizedBox(height: 10),
                        _buildLockedFeatureRow(
                          icon: Icons.assignment_turned_in_rounded,
                          color: const Color(0xFF10B981),
                          title: 'Barangay Services',
                          subtitle: 'Access 4Ps, PWD, AICS and more programs',
                        ),
                        const SizedBox(height: 10),
                        _buildLockedFeatureRow(
                          icon: Icons.groups_rounded,
                          color: const Color(0xFFF59E0B),
                          title: 'Community Directory',
                          subtitle: 'Find officials and barangay contacts',
                        ),
                        const SizedBox(height: 10),
                        _buildLockedFeatureRow(
                          icon: Icons.shield_rounded,
                          color: const Color(0xFF3B82F6),
                          title: 'Full Report History',
                          subtitle: 'Track and manage all your reports',
                        ),

                        const SizedBox(height: 28),

                        // ── Emergency Report section ──
                        Text(
                          'Emergency Assistance',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A2744),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFEF4444).withOpacity(0.4),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 32),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Emergency Report',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Even as a guest, you can report emergencies directly to the barangay for immediate response.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    showCentralizedReportModal(context);
                                  },
                                  icon: const Icon(Icons.campaign_rounded, size: 20),
                                  label: const Text(
                                    'Send Emergency Report',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEF4444),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedFeatureRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2744),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.lock_rounded, color: Colors.white.withOpacity(0.25), size: 18),
        ],
      ),
    );
  }

  /// Top Bar with Location Subtitle, "Announcements" Title, Search & Notification icons
  Widget _buildTopBar(BuildContext context, AppState appState) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Green dot + BARANGAY CENTRAL
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
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Main Title "Announcements" + Search & Bell Icons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Announcements',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
                letterSpacing: -0.5,
              ),
            ),
            Row(
              children: [
                // Search Button
                InkWell(
                  onTap: () => _showSearchModal(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF475569)),
                  ),
                ),
                const SizedBox(width: 8),

                // Notifications Bell with orange unread dot
                InkWell(
                  onTap: () => _showNotificationsModal(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.notifications_none_rounded, size: 20, color: Color(0xFF475569)),
                        Positioned(
                          top: -1,
                          right: -1,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF5722),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Category filter pills matching the reference screenshot
  Widget _buildFilterChips() {
    final categories = [
      {'name': 'All Updates', 'label': 'All Updates', 'icon': null},
      {'name': 'Urgent Advisories', 'label': '⚠️ Urgent Advisories', 'icon': null},
      {'name': 'Health & Safety', 'label': '🏥 Health & Safety', 'icon': null},
      {'name': 'Eco & Sanitation', 'label': '🌿 Eco & Sanitation', 'icon': null},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat['name'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () => setState(() => _selectedCategory = cat['name'] as String),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1D4ED8) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF1D4ED8) : Colors.grey.shade200,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF1D4ED8).withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  cat['label'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// High Priority Featured Announcement Card
  Widget _buildHighPriorityCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF7A00), Color(0xFFFF3D24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5722).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: High Priority Tag, Affected Purok, Time
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDC2626),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'HIGH PRIORITY',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Purok 1, 2 & 3',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '25m ago',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          const Text(
            'Scheduled Water Supply Interruption & Relief Tank Station Setup',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),

          // Content preview
          Text(
            'Temporary line repairs on Main Ave starting at 1:00 PM today. Mobile potable water tankers stationed at Purok 1...',
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.35,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),

          // Footer: Desk & Read Details >
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ENG',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Barangay Engineering Desk',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _showWaterAdvisoryDetails(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Read Details',
                        style: TextStyle(
                          color: Color(0xFFEA580C),
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFFEA580C)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Community Assistance / Quick Report Banner
  Widget _buildAssistanceBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Exclamation badge
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFEDD5)),
            ),
            child: const Center(
              child: Icon(
                Icons.priority_high_rounded,
                color: Color(0xFFEA580C),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Texts
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need Community Assistance?',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Submit incident reports or request emergency response',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          // Report + Button
          InkWell(
            onTap: () => showCentralizedReportModal(context),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'Report +',
                style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Section Header: COMMUNITY FEED, 3 New, Sort Newest
  Widget _buildFeedHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Text(
              'COMMUNITY FEED',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF334155),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: const Text(
                '3 New',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
        InkWell(
          onTap: _showSortModal,
          child: Row(
            children: [
              Text(
                'Sort: $_currentSort',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563EB),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF2563EB)),
            ],
          ),
        ),
      ],
    );
  }

  /// Community Feed Card
  Widget _buildFeedCard(Map<String, dynamic> post) {
    final isLiked = _likedPosts.contains(post['id']);
    final isSaved = _savedPosts.contains(post['id']);
    final likesCount = post['likes'] + (isLiked ? 1 : 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: post['avatarBg'] as Color,
                child: Text(
                  post['avatarText'] as String,
                  style: TextStyle(
                    color: post['avatarColor'] as Color,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            post['author'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (post['isVerified'] == true) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, size: 15, color: Color(0xFF2563EB)),
                        ],
                      ],
                    ),
                    Text(
                      post['subtitle'] as String,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                post['time'] as String,
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Category pill tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: post['tagBg'] as Color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              post['tagText'] as String,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: post['tagColor'] as Color,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Title
          Text(
            post['title'] as String,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),

          // Content
          Text(
            post['content'] as String,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF475569),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),

          // Footer Actions: Like, Comment, Bookmark
          Row(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    if (isLiked) {
                      _likedPosts.remove(post['id']);
                    } else {
                      _likedPosts.add(post['id']);
                    }
                  });
                },
                child: Row(
                  children: [
                    Icon(
                      isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: 18,
                      color: isLiked ? Colors.red : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$likesCount',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isLiked ? Colors.red : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Viewing ${post['comments']} comments for this post.')),
                  );
                },
                child: Row(
                  children: [
                    const Icon(Icons.mode_comment_outlined, size: 17, color: Color(0xFF64748B)),
                    const SizedBox(width: 5),
                    Text(
                      '${post['comments']}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () {
                  setState(() {
                    if (isSaved) {
                      _savedPosts.remove(post['id']);
                    } else {
                      _savedPosts.add(post['id']);
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isSaved ? 'Removed from bookmarks' : 'Post bookmarked!'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Icon(
                  isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  size: 20,
                  color: isSaved ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showWaterAdvisoryDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'HIGH PRIORITY ADVISORY',
                    style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                const Spacer(),
                Text('Effective Today', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Scheduled Water Supply Interruption & Relief Tank Station Setup',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Due to emergency mainline repair along Main Avenue, water supply will be temporarily interrupted from 1:00 PM to 7:00 PM today affecting Purok 1, Purok 2, and Purok 3.\n\nWater relief tankers are stationed at:\n• Purok 1 Basketball Court\n• Purok 2 Barangay Outpost\n• Purok 3 Elementary School Gate',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Acknowledge & Close', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Sort Announcements By', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.access_time_rounded),
              title: const Text('Newest First'),
              trailing: _currentSort == 'Newest' ? const Icon(Icons.check, color: Colors.blue) : null,
              onTap: () {
                setState(() => _currentSort = 'Newest');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_fire_department_rounded),
              title: const Text('Most Urgent'),
              trailing: _currentSort == 'Most Urgent' ? const Icon(Icons.check, color: Colors.blue) : null,
              onTap: () {
                setState(() => _currentSort = 'Most Urgent');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.thumb_up_alt_rounded),
              title: const Text('Most Popular'),
              trailing: _currentSort == 'Most Popular' ? const Icon(Icons.check, color: Colors.blue) : null,
              onTap: () {
                setState(() => _currentSort = 'Most Popular');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Search Announcements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search by keyword, health, curfew, water...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onSubmitted: (query) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Searching for "$query"...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Mark all as read'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(0xFFFFEDD5),
                child: Icon(Icons.water_drop, color: Color(0xFFEA580C)),
              ),
              title: Text('Water Interruption Advisory', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text('Main Avenue repairs starting at 1:00 PM today.'),
              trailing: Text('25m ago', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ),
            const ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(0xFFDBEAFE),
                child: Icon(Icons.medical_services, color: Color(0xFF1D4ED8)),
              ),
              title: Text('Vaccination Mission Reminder', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text('Pediatric flu vaccines available this Saturday.'),
              trailing: Text('2h ago', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}
