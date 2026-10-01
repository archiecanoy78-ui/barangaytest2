import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/user.dart';
import '../../validators.dart';
import '../../widgets/form_draft_helper.dart';

class StaffManagementPage extends StatefulWidget {
  const StaffManagementPage({super.key});

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage> {
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
    final staffList = appState.staffList.where((s) => s.username != 'admin' && s.role != UserRole.admin).toList();

    final filteredStaff = staffList.where((s) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final name = s.name.toLowerCase();
      final username = (s.username ?? '').toLowerCase();
      final role = (s.staffRole?.name ?? '').toLowerCase();
      final phone = s.phoneNumber.toLowerCase();
      return name.contains(q) || username.contains(q) || role.contains(q) || phone.contains(q);
    }).toList();

    final int totalPages = max(1, (filteredStaff.length / _pageSize).ceil());
    if (_currentPage >= totalPages) {
      _currentPage = totalPages - 1;
    }

    final paginatedStaff = filteredStaff.skip(_currentPage * _pageSize).take(_pageSize).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Staff Management', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showAddStaffDialog(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Staff'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 24),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                        _currentPage = 0;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search staff by name, role, username, or phone...',
                      hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                                _currentPage = 0;
                              }),
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Total Staff: ${staffList.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Table Data View
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x05000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: filteredStaff.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.badge_outlined, size: 48, color: Color(0xFFCBD5E1)),
                                  SizedBox(height: 12),
                                  Text(
                                    'No staff records found.',
                                    style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 350),
                                  child: DataTable(
                                    headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                                    dataRowMaxHeight: 64,
                                    columns: const [
                                      DataColumn(label: Text('Staff Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Username', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Role / Designation', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Phone Number', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                    rows: paginatedStaff.map((User s) {
                                      return DataRow(cells: [
                                        DataCell(
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 18,
                                                backgroundColor: const Color(0xFFDBEAFE),
                                                child: Text(
                                                  s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S',
                                                  style: const TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                                  Text(s.purok, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        DataCell(Text(s.username ?? 'N/A', style: const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
                                        DataCell(_roleBadge(s)),
                                        DataCell(Text(s.phoneNumber, style: const TextStyle(fontSize: 13))),
                                        DataCell(_statusBadge(s.isArchived)),
                                        DataCell(
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF2563EB)),
                                                tooltip: 'View Profile',
                                                onPressed: () => _showStaffDetails(context, s),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0284C7)),
                                                tooltip: 'Edit Staff',
                                                onPressed: () => _showEditStaffDialog(context, s),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  s.isArchived ? Icons.restore_rounded : Icons.block_rounded,
                                                  size: 18,
                                                  color: s.isArchived ? Colors.green : Colors.orange.shade800,
                                                ),
                                                tooltip: s.isArchived ? 'Restore Staff' : 'Disable Staff',
                                                onPressed: () => _toggleArchiveStaff(context, s),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                                tooltip: 'Delete Staff',
                                                onPressed: () => _confirmDeleteStaff(context, s),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ]);
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),

                  // Pagination Controls
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing ${filteredStaff.isEmpty ? 0 : _currentPage * _pageSize + 1} - ${min((_currentPage + 1) * _pageSize, filteredStaff.length)} of ${filteredStaff.length} staff',
                          style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                              icon: const Icon(Icons.arrow_back_ios_rounded, size: 14),
                              label: const Text('Previous'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Page ${_currentPage + 1} of $totalPages',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                              label: const Text('Next'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
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
    );
  }

  Widget _roleBadge(User s) {
    final roleName = s.staffRole != null
        ? s.staffRole!.name.toUpperCase()
        : (s.role == UserRole.admin ? 'ADMINISTRATOR' : 'STAFF');
    Color bg = const Color(0xFFEFF6FF);
    Color fg = const Color(0xFF1D4ED8);

    if (s.role == UserRole.admin) {
      bg = const Color(0xFFFFE4E6);
      fg = const Color(0xFFE11D48);
    } else if (s.staffRole == StaffRole.captain) {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFD97706);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        roleName,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _statusBadge(bool isArchived) {
    Color color = isArchived ? Colors.red : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(
        isArchived ? 'INACTIVE' : 'ACTIVE',
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showAddStaffDialog(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final currentUid = appState.currentUser?.id ?? 'admin';
    final draftHelper = FormDraftHelper(formKey: 'add_staff', uid: currentUid);

    final firstNameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final purokCtrl = TextEditingController(text: 'Main');
    final passwordCtrl = TextEditingController();
    StaffRole selectedStaffRole = StaffRole.tanod;
    UserRole selectedUserRole = UserRole.staff;
    bool obscurePassword = true;
    String? errorMsg;
    String? attachedIdPhotoName;

    final draft = await draftHelper.loadDraft();
    if (draft != null) {
      firstNameCtrl.text = draft['firstName']?.toString() ?? '';
      lastNameCtrl.text = draft['lastName']?.toString() ?? '';
      usernameCtrl.text = draft['username']?.toString() ?? '';
      purokCtrl.text = draft['purok']?.toString() ?? 'Main';
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setModalState) {
          void updateDraft() {
            draftHelper.onFieldChanged({
              'firstName': firstNameCtrl.text,
              'lastName': lastNameCtrl.text,
              'username': usernameCtrl.text,
              'purok': purokCtrl.text,
            });
            setModalState(() {});
          }

          final pass = passwordCtrl.text;
          final hasMinMax = pass.length >= 8;
          final hasUpper = pass.contains(RegExp(r'[A-Z]'));
          final hasLower = pass.contains(RegExp(r'[a-z]'));
          final hasDigit = pass.contains(RegExp(r'[0-9]'));
          final hasSpecial = pass.contains(RegExp(r'[^A-Za-z0-9]'));

          final isFormValid =
              Validators.validateFirstName(firstNameCtrl.text) == null &&
              Validators.validateLastName(lastNameCtrl.text) == null &&
              Validators.validateUsernameMobile(usernameCtrl.text) == null &&
              Validators.validatePassword(passwordCtrl.text) == null &&
              attachedIdPhotoName != null;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Add New Staff Member', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 440,
                child: Form(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (errorMsg != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: firstNameCtrl,
                              maxLength: 50,
                              inputFormatters: [LengthLimitingTextInputFormatter(50)],
                              decoration: const InputDecoration(labelText: 'First Name *', prefixIcon: Icon(Icons.person_outline)),
                              validator: (v) => Validators.validateFirstName(v ?? ''),
                              onChanged: (_) => updateDraft(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: lastNameCtrl,
                              maxLength: 50,
                              inputFormatters: [LengthLimitingTextInputFormatter(50)],
                              decoration: const InputDecoration(labelText: 'Last Name *', prefixIcon: Icon(Icons.person_outline)),
                              validator: (v) => Validators.validateLastName(v ?? ''),
                              onChanged: (_) => updateDraft(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: usernameCtrl,
                        maxLength: 11,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Username (11-digit Mobile Number starting with 09) *',
                          prefixIcon: Icon(Icons.phone_android_rounded),
                        ),
                        validator: (v) => Validators.validateUsernameMobile(v ?? ''),
                        onChanged: (_) => updateDraft(),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<StaffRole>(
                        initialValue: selectedStaffRole,
                        decoration: const InputDecoration(labelText: 'Staff Role Designation', prefixIcon: Icon(Icons.badge)),
                        items: StaffRole.values.map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(role.name.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedStaffRole = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<UserRole>(
                        initialValue: selectedUserRole,
                        decoration: const InputDecoration(labelText: 'Access Level', prefixIcon: Icon(Icons.security)),
                        items: const [
                          DropdownMenuItem(value: UserRole.staff, child: Text('Staff')),
                          DropdownMenuItem(value: UserRole.admin, child: Text('Administrator')),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedUserRole = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: purokCtrl,
                        decoration: const InputDecoration(labelText: 'Assigned Area / Purok', prefixIcon: Icon(Icons.location_on_outlined)),
                        onChanged: (_) => updateDraft(),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passwordCtrl,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Account Password *',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                            onPressed: () => setModalState(() => obscurePassword = !obscurePassword),
                          ),
                        ),
                        validator: (v) => Validators.validatePassword(v ?? ''),
                        onChanged: (_) => updateDraft(),
                      ),
                      const SizedBox(height: 10),
                      // Password Criteria Checklist
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ruleItem('8+ characters long', hasMinMax),
                            _ruleItem('At least one uppercase letter (A-Z)', hasUpper),
                            _ruleItem('At least one lowercase letter (a-z)', hasLower),
                            _ruleItem('At least one digit (0-9)', hasDigit),
                            _ruleItem('At least one special character (!@#\$%^&*)', hasSpecial),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Mandatory ID Photo Upload Field
                      InkWell(
                        onTap: () {
                          setModalState(() {
                            attachedIdPhotoName = 'staff_id_${DateTime.now().millisecondsSinceEpoch}.jpg';
                            errorMsg = null;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                          decoration: BoxDecoration(
                            color: attachedIdPhotoName != null ? Colors.green.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: attachedIdPhotoName != null ? Colors.green : const Color(0xFFCBD5E1),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                attachedIdPhotoName != null ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                                size: 18,
                                color: attachedIdPhotoName != null ? Colors.green : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  attachedIdPhotoName != null ? 'ID Attached: $attachedIdPhotoName (Tap to replace)' : 'Upload ID Photo * (JPG/PNG/PDF, max 5MB)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: attachedIdPhotoName != null ? Colors.green.shade700 : const Color(0xFF64748B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final hasContent = firstNameCtrl.text.isNotEmpty || lastNameCtrl.text.isNotEmpty || usernameCtrl.text.isNotEmpty;
                  if (hasContent) {
                    final discard = await FormDraftHelper.showDiscardConfirmationDialog(context);
                    if (discard) {
                      await draftHelper.clearDraft();
                      if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                    }
                  } else {
                    Navigator.pop(dialogCtx);
                  }
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isFormValid
                    ? () async {
                        final fullName = '${firstNameCtrl.text.trim()} ${lastNameCtrl.text.trim()}';
                        final username = usernameCtrl.text.trim();
                        final purok = purokCtrl.text.trim().isEmpty ? 'Main' : purokCtrl.text.trim();
                        final password = passwordCtrl.text;

                        final newStaff = User(
                          id: 'staff_${DateTime.now().millisecondsSinceEpoch}',
                          name: fullName,
                          username: username,
                          role: selectedUserRole,
                          staffRole: selectedStaffRole,
                          purok: purok,
                          phoneNumber: username,
                          isVerified: true,
                          password: password,
                          idImagePath: attachedIdPhotoName,
                        );

                        final err = await appState.registerUserWithoutSigningOutAdmin(newStaff);

                        if (err != null) {
                          setModalState(() => errorMsg = err);
                          return;
                        }

                        await draftHelper.clearDraft();
                        if (dialogCtx.mounted) {
                          Navigator.pop(dialogCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Staff member "$fullName" added successfully!')),
                          );
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add Staff Member'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _ruleItem(String label, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 13,
            color: isMet ? Colors.green : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isMet ? const Color(0xFF15803D) : const Color(0xFF64748B),
              fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditStaffDialog(BuildContext context, User staff) {
    final nameCtrl = TextEditingController(text: staff.name);
    final usernameCtrl = TextEditingController(text: staff.username ?? '');
    final phoneCtrl = TextEditingController(text: staff.phoneNumber);
    final purokCtrl = TextEditingController(text: staff.purok);
    final passwordCtrl = TextEditingController(text: staff.password ?? 'password');
    StaffRole selectedStaffRole = staff.staffRole ?? StaffRole.tanod;
    UserRole selectedUserRole = staff.role == UserRole.admin ? UserRole.admin : UserRole.staff;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Edit Staff: ${staff.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (errorMsg != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: usernameCtrl,
                    decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.account_circle)),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<StaffRole>(
                    initialValue: selectedStaffRole,
                    decoration: const InputDecoration(labelText: 'Staff Role Designation', prefixIcon: Icon(Icons.badge)),
                    items: StaffRole.values.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedStaffRole = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<UserRole>(
                    initialValue: selectedUserRole,
                    decoration: const InputDecoration(labelText: 'Access Level', prefixIcon: Icon(Icons.security)),
                    items: const [
                      DropdownMenuItem(value: UserRole.staff, child: Text('Staff')),
                      DropdownMenuItem(value: UserRole.admin, child: Text('Administrator')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedUserRole = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: purokCtrl,
                    decoration: const InputDecoration(labelText: 'Assigned Area / Purok', prefixIcon: Icon(Icons.location_on)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordCtrl,
                    decoration: const InputDecoration(labelText: 'Account Password', prefixIcon: Icon(Icons.lock)),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final username = usernameCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                final purok = purokCtrl.text.trim();
                final password = passwordCtrl.text.trim();

                if (name.isEmpty || username.isEmpty) {
                  setModalState(() => errorMsg = 'Name and Username cannot be empty.');
                  return;
                }

                final updatedUser = User(
                  id: staff.id,
                  name: name,
                  username: username,
                  role: selectedUserRole,
                  staffRole: selectedStaffRole,
                  purok: purok,
                  phoneNumber: phone,
                  isVerified: staff.isVerified,
                  idImagePath: staff.idImagePath,
                  faceData: staff.faceData,
                  isArchived: staff.isArchived,
                  password: password,
                );

                await context.read<AppState>().updateUser(updatedUser);

                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Staff member "$name" updated successfully!')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleArchiveStaff(BuildContext context, User staff) {
    final isCurrentlyArchived = staff.isArchived;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(isCurrentlyArchived ? 'Restore Staff Member?' : 'Disable Staff Member?'),
        content: Text(
          isCurrentlyArchived
              ? 'Are you sure you want to restore ${staff.name} to active status?'
              : 'Are you sure you want to disable ${staff.name}? They will not be able to perform staff duties.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (isCurrentlyArchived) {
                await context.read<AppState>().restoreUser(staff.id);
              } else {
                await context.read<AppState>().archiveUser(staff.id);
              }
              if (dialogCtx.mounted) {
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isCurrentlyArchived
                          ? '${staff.name} restored to active status.'
                          : '${staff.name} disabled.',
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentlyArchived ? Colors.green : Colors.orange.shade800,
              foregroundColor: Colors.white,
            ),
            child: Text(isCurrentlyArchived ? 'Restore' : 'Disable'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteStaff(BuildContext context, User staff) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Permanently Delete Staff?'),
        content: Text('Are you sure you want to permanently delete ${staff.name}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await context.read<AppState>().deleteUser(staff.id);
              if (dialogCtx.mounted) {
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Staff member "${staff.name}" deleted.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  void _showStaffDetails(BuildContext context, User staff) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.badge_rounded, color: Color(0xFF2563EB)),
            const SizedBox(width: 10),
            Expanded(child: Text(staff.name, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('User ID', staff.id),
            _detailRow('Username', staff.username ?? 'N/A'),
            _detailRow('Designation', staff.staffRole?.name.toUpperCase() ?? 'STAFF'),
            _detailRow('Access Level', staff.role.name.toUpperCase()),
            _detailRow('Assigned Purok', staff.purok),
            _detailRow('Phone Number', staff.phoneNumber),
            _detailRow('Account Status', staff.isArchived ? 'INACTIVE (Disabled)' : 'ACTIVE'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogCtx);
              _showEditStaffDialog(context, staff);
            },
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit Info'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
