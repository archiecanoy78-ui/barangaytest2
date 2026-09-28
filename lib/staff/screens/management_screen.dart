import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../utils_validators.dart';
import '../../models/user.dart';

class ManagementScreen extends StatefulWidget {
  const ManagementScreen({super.key});

  @override
  State<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends State<ManagementScreen> {
  int _activeTab = 1; // Default to Staff (Tab 1) as seen in reference image
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 0;
  static const int _pageSize = 10;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    
    // Categorize users based on state
    final residents = appState.allUsers.where((u) => u.role == UserRole.resident).toList();
    final staff = appState.allUsers.where((u) => u.role == UserRole.staff).toList();
    final archived = appState.archivedUsers;

    // Filter current list by query
    List<User> currentList = [];
    if (_activeTab == 0) currentList = residents;
    if (_activeTab == 1) currentList = staff;
    if (_activeTab == 2) currentList = archived;

    if (_searchQuery.isNotEmpty) {
      currentList = currentList
          .where((u) => u.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              u.purok.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    final int totalPages = max(1, (currentList.length / _pageSize).ceil());
    if (_currentPage >= totalPages) {
      _currentPage = totalPages - 1;
    }
    final paginatedUsers = currentList.skip(_currentPage * _pageSize).take(_pageSize).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 14),

            // ── Top Micro Tag & Sign Out ─────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'BARANGAY CENTRAL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => appState.logout(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.logout_rounded, color: Color(0xFF475569), size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Sign Out',
                          style: TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Title Header Row ─────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Barangay Directory',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Manage profiles and official records',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF2563EB),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    onPressed: () => _showAddUserDialog(context),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Punong Barangay Premium Profile Feature Card ────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.01),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Flexible(
                              child: Text(
                                'Capt. Pedro Santos',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 14),
                          ],
                        ),
                        const SizedBox(height: 1),
                        const Text(
                          'PUNONG BARANGAY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2563EB),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F4EA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Color(0xFF137333),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: Color(0xFF137333),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Metrics Row Cards ────────────────────────────────────────────
            Row(
              children: [
                _buildMetricsCard(
                  title: 'TOTAL STAFF',
                  value: staff.length.toString(),
                  subtext: '12 On Duty',
                  valueColor: const Color(0xFF0F172A),
                  accentColor: const Color(0xFF3B82F6),
                  icon: Icons.person_rounded,
                ),
                const SizedBox(width: 8),
                _buildMetricsCard(
                  title: 'PENDING',
                  value: residents.where((r) => !r.isVerified).length.toString(),
                  subtext: 'Requires ID',
                  valueColor: const Color(0xFFD97706),
                  accentColor: const Color(0xFFFBBF24),
                  icon: Icons.watch_later_rounded,
                ),
                const SizedBox(width: 8),
                _buildMetricsCard(
                  title: 'RESIDENTS',
                  value: residents.length.toString(),
                  subtext: '98% Verified',
                  valueColor: const Color(0xFF10B981),
                  accentColor: const Color(0xFF34D399),
                  icon: Icons.check_circle_outline_rounded,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Pill Row Selection Bar ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildTabPill(0, 'Residents', residents.length),
                  _buildTabPill(1, 'Staff', staff.length),
                  _buildTabPill(2, 'Archived', archived.length),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Minimalist Search & Filter Bar ───────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() {
                        _searchQuery = val;
                        _currentPage = 0;
                      }),
                      decoration: const InputDecoration(
                        hintText: 'Search staff name, role, purok...',
                        hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(Icons.tune_rounded, color: Color(0xFF475569), size: 20),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Clean User List Cards ────────────────────────────────────────
            if (currentList.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: const Center(
                  child: Text(
                    'No records found matching criteria.',
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ),
              )
            else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: paginatedUsers.length,
                itemBuilder: (context, index) {
                  final u = paginatedUsers[index];
                  return _buildModernUserCard(context, u, appState);
                },
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing ${currentList.isEmpty ? 0 : _currentPage * _pageSize + 1} - ${min((_currentPage + 1) * _pageSize, currentList.length)} of ${currentList.length}',
                      style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
                          onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                        ),
                        Text(
                          'Page ${_currentPage + 1} of $totalPages',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 12),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                          onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsCard({
    required String title,
    required String value,
    required String subtext,
    required Color valueColor,
    required Color accentColor,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accentColor, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtext,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPill(int index, String label, int count) {
    final bool isSelected = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _activeTab = index;
          _currentPage = 0;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernUserCard(BuildContext context, User u, AppState appState) {
    final String initials = u.name.isNotEmpty ? u.name.split(' ').map((e) => e[0]).take(2).join().toUpperCase() : 'U';
    final bool isStaff = u.role == UserRole.staff;
    final bool isArchived = appState.archivedUsers.any((arch) => arch.id == u.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: isStaff ? const Color(0xFFEFF6FF) : const Color(0xFFFEF3C7),
                child: Text(
                  initials,
                  style: TextStyle(
                    color: isStaff ? const Color(0xFF2563EB) : const Color(0xFFD97706),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          u.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (u.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 14),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isStaff
                          ? (u.staffRole?.name.toUpperCase() ?? 'STAFF PERSONNEL')
                          : '${u.purok} • Resident Account',
                      style: TextStyle(
                        fontSize: 12,
                        color: isStaff ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                        fontWeight: isStaff ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    Text(
                      u.phoneNumber,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Color(0xFF94A3B8)),
                onPressed: () => _showUserCRUD(context, u, isArchived),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isArchived)
                OutlinedButton.icon(
                  onPressed: () => appState.restoreUser(u.id),
                  icon: const Icon(Icons.restore, size: 14),
                  label: const Text('Restore Personnel', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981),
                    side: const BorderSide(color: Color(0xFF10B981)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                )
              else if (!u.isVerified)
                ElevatedButton(
                  onPressed: () => appState.verifyResident(u.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Verify User', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                )
              else ...[
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Task Assignment triggered.')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF475569),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Assign Task', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _showUserProfile(context, u),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    foregroundColor: const Color(0xFF1E293B),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Profile', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showUserCRUD(BuildContext context, User user, bool isArchived) {
    final appState = context.read<AppState>();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('User Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('View Full Profile'),
              subtitle: const Text('ID, Photo, and Biometric status'),
              onTap: () {
                Navigator.pop(context);
                _showUserProfile(context, user);
              },
            ),
            if (!isArchived) ...[
              if (!user.isVerified && user.role == UserRole.resident)
                ListTile(
                  leading: const Icon(Icons.verified_user_outlined, color: Color(0xFF2563EB)),
                  title: const Text('Verify User', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
                  subtitle: const Text('Mark account as verified resident'),
                  onTap: () {
                    Navigator.pop(context);
                    appState.verifyResident(user.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Resident ${user.name} verified successfully.')),
                    );
                  },
                ),
              if (user.role != UserRole.resident)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit Information'),
                  subtitle: const Text('Update name, purok, or phone'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditUser(context, user);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.archive_outlined, color: Colors.red),
                title: const Text('Archive User', style: TextStyle(color: Colors.red)),
                subtitle: const Text('Hide from active directory'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmArchive(context, user);
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.restore, color: Colors.green),
                title: const Text('Restore User', style: TextStyle(color: Colors.green)),
                subtitle: const Text('Move back to active directory'),
                onTap: () {
                  Navigator.pop(context);
                  appState.restoreUser(user.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
                title: const Text('Delete Permanently', style: TextStyle(color: Colors.red)),
                subtitle: const Text('Permanently remove archived user'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteUser(context, user);
                },
              ),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showUserProfile(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${user.name}\'s Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${user.id}'),
            Text('Purok: ${user.purok}'),
            Text('Phone: ${user.phoneNumber}'),
            Text('Status: ${user.isVerified ? "Verified" : "Pending"}'),
            const SizedBox(height: 10),
            Container(
              height: 100,
              width: double.infinity,
              color: Colors.grey.shade200,
              child: const Center(child: Icon(Icons.image_outlined, size: 40, color: Colors.grey)),
            ),
            const Center(child: Text('Simulated ID Card Image', style: TextStyle(fontSize: 10, color: Colors.grey))),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE'))],
      ),
    );
  }

  void _showEditUser(BuildContext context, User user) {
    final nameCtrl = TextEditingController(text: user.name);
    final purokCtrl = TextEditingController(text: user.purok);
    final phoneCtrl = TextEditingController(text: user.phoneNumber);

    showDialog(
      context: context,
      builder: (context) {
        String? nameErr;
        String? phoneErr;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit User Info'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
                  if (nameErr != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(nameErr!, style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
                    ),
                  TextField(controller: purokCtrl, decoration: const InputDecoration(labelText: 'Purok')),
                  TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
                  if (phoneErr != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(phoneErr!, style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
                    ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
                ElevatedButton(
                  onPressed: () {
                    final nErr = UtilsValidators.validateName(nameCtrl.text);
                    final pErr = UtilsValidators.validatePhone(phoneCtrl.text);
                    if (nErr != null || pErr != null) {
                      setState(() {
                        nameErr = nErr;
                        phoneErr = pErr;
                      });
                      return;
                    }

                    final updated = User(
                      id: user.id,
                      name: nameCtrl.text,
                      role: user.role,
                      staffRole: user.staffRole,
                      purok: purokCtrl.text,
                      phoneNumber: phoneCtrl.text,
                      isVerified: user.isVerified,
                      idImagePath: user.idImagePath,
                      faceData: user.faceData,
                      isArchived: user.isArchived,
                    );
                    context.read<AppState>().updateUser(updated);
                    Navigator.pop(context);
                  },
                  child: const Text('SAVE'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmArchive(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive User?'),
        content: Text('Are you sure you want to archive ${user.name}? They will no longer appear in the active directory.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              context.read<AppState>().archiveUser(user.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User archived.')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ARCHIVE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    if (_activeTab == 1) {
      _showAddStaffDialog(context);
    } else {
      _showAddResidentDialog(context);
    }
  }

  void _showAddStaffDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final purokCtrl = TextEditingController(text: 'Main');
    final passwordCtrl = TextEditingController(text: 'password');
    StaffRole selectedStaffRole = StaffRole.tanod;
    UserRole selectedUserRole = UserRole.staff;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Add Staff Member'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name *')),
                  const SizedBox(height: 10),
                  TextField(controller: usernameCtrl, decoration: const InputDecoration(labelText: 'Username *')),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<StaffRole>(
                    initialValue: selectedStaffRole,
                    decoration: const InputDecoration(labelText: 'Staff Role'),
                    items: StaffRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r.name.toUpperCase()))).toList(),
                    onChanged: (val) { if (val != null) setModalState(() => selectedStaffRole = val); },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<UserRole>(
                    initialValue: selectedUserRole,
                    decoration: const InputDecoration(labelText: 'Access Role'),
                    items: const [
                      DropdownMenuItem(value: UserRole.staff, child: Text('STAFF')),
                      DropdownMenuItem(value: UserRole.admin, child: Text('ADMINISTRATOR')),
                    ],
                    onChanged: (val) { if (val != null) setModalState(() => selectedUserRole = val); },
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: purokCtrl, decoration: const InputDecoration(labelText: 'Purok')),
                  const SizedBox(height: 10),
                  TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
                  const SizedBox(height: 10),
                  TextField(controller: passwordCtrl, decoration: const InputDecoration(labelText: 'Password *')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || usernameCtrl.text.trim().isEmpty || passwordCtrl.text.trim().isEmpty) return;
                await context.read<AppState>().addStaff(
                  name: nameCtrl.text.trim(),
                  username: usernameCtrl.text.trim(),
                  staffRole: selectedStaffRole,
                  purok: purokCtrl.text.trim().isEmpty ? 'Main' : purokCtrl.text.trim(),
                  phoneNumber: phoneCtrl.text.trim().isEmpty ? 'N/A' : phoneCtrl.text.trim(),
                  password: passwordCtrl.text.trim(),
                  role: selectedUserRole,
                );
                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff member added successfully.')));
                }
              },
              child: const Text('ADD STAFF'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddResidentDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final purokCtrl = TextEditingController(text: 'Purok 1');
    final passwordCtrl = TextEditingController(text: 'password');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Add Resident Record'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name *')),
                const SizedBox(height: 10),
                TextField(controller: usernameCtrl, decoration: const InputDecoration(labelText: 'Username *')),
                const SizedBox(height: 10),
                TextField(controller: purokCtrl, decoration: const InputDecoration(labelText: 'Purok *')),
                const SizedBox(height: 10),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
                const SizedBox(height: 10),
                TextField(controller: passwordCtrl, decoration: const InputDecoration(labelText: 'Password *')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || usernameCtrl.text.trim().isEmpty || passwordCtrl.text.trim().isEmpty) return;
              await context.read<AppState>().addResident(
                name: nameCtrl.text.trim(),
                username: usernameCtrl.text.trim(),
                purok: purokCtrl.text.trim().isEmpty ? 'Purok 1' : purokCtrl.text.trim(),
                phoneNumber: phoneCtrl.text.trim().isEmpty ? 'N/A' : phoneCtrl.text.trim(),
                password: passwordCtrl.text.trim(),
                isVerified: true,
              );
              if (dialogCtx.mounted) {
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resident record added successfully.')));
              }
            },
            child: const Text('ADD RESIDENT'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(BuildContext context, User user) {
    if (user.role == UserRole.resident && !user.isArchived) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete active resident. Resident must be archived first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete User Permanently?'),
        content: Text('Are you sure you want to permanently delete ${user.name}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final err = await context.read<AppState>().deleteUser(user.id);
              if (dialogCtx.mounted) {
                Navigator.pop(dialogCtx);
                if (err != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User ${user.name} permanently deleted.')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
