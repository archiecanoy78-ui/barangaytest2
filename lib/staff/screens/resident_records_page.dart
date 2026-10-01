import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/user.dart';
import '../../models/report.dart';
import '../../validators.dart';
import '../../widgets/form_draft_helper.dart';

class ResidentRecordsPage extends StatefulWidget {
  const ResidentRecordsPage({super.key});

  @override
  State<ResidentRecordsPage> createState() => _ResidentRecordsPageState();
}

class _ResidentRecordsPageState extends State<ResidentRecordsPage> {
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
    final allUsers = appState.allUsers;
    final reports = appState.reports;

    final residentsList = allUsers.where((u) => u.role == UserRole.resident).toList();

    final filteredResidents = residentsList.where((res) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final name = res.name.toLowerCase();
      final username = (res.username ?? '').toLowerCase();
      final purok = res.purok.toLowerCase();
      final phone = res.phoneNumber.toLowerCase();
      return name.contains(q) || username.contains(q) || purok.contains(q) || phone.contains(q);
    }).toList();

    final int totalPages = max(1, (filteredResidents.length / _pageSize).ceil());
    if (_currentPage >= totalPages) {
      _currentPage = totalPages - 1;
    }

    final paginatedResidents = filteredResidents.skip(_currentPage * _pageSize).take(_pageSize).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Residents Directory', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          ElevatedButton.icon(
            onPressed: () => _showAddResidentDialog(context),
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Add Resident'),
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
                      hintText: 'Search resident by name, username, purok, or phone...',
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
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Registered Residents: ${residentsList.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF059669),
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
                      child: filteredResidents.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline_rounded, size: 48, color: Color(0xFFCBD5E1)),
                                  SizedBox(height: 12),
                                  Text(
                                    'No resident records found.',
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
                                      DataColumn(label: Text('Resident Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Username', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Purok / Zone', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Phone Number', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Complaints Filed', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Verification Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                    rows: paginatedResidents.map((User res) {
                                      final userReports = reports.where((r) =>
                                          r.complainantPhone == res.phoneNumber ||
                                          r.complainantName.toLowerCase() == res.name.toLowerCase()).toList();

                                      return DataRow(cells: [
                                        DataCell(
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 18,
                                                backgroundColor: const Color(0xFFD1FAE5),
                                                child: Text(
                                                  res.name.isNotEmpty ? res.name[0].toUpperCase() : 'R',
                                                  style: const TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(res.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                            ],
                                          ),
                                        ),
                                        DataCell(Text(res.username ?? 'N/A', style: const TextStyle(fontSize: 13, color: Color(0xFF334155)))),
                                        DataCell(Text(res.purok, style: const TextStyle(fontSize: 13))),
                                        DataCell(Text(res.phoneNumber, style: const TextStyle(fontSize: 13))),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '${userReports.length} reports',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                            ),
                                          ),
                                        ),
                                        DataCell(_verificationBadge(context, res)),
                                        DataCell(
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF2563EB)),
                                                tooltip: 'View Profile & Complaints',
                                                onPressed: () => _showResidentDetails(context, res, userReports),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF2563EB)),
                                                tooltip: 'Edit Resident Profile',
                                                onPressed: () => _showEditResidentDialog(context, res),
                                              ),
                                              IconButton(
                                                icon: Icon(
                                                  res.isArchived ? Icons.restore_rounded : Icons.archive_rounded,
                                                  size: 18,
                                                  color: res.isArchived ? Colors.green : Colors.orange.shade800,
                                                ),
                                                tooltip: res.isArchived ? 'Restore Account' : 'Archive Account',
                                                onPressed: () => _toggleArchiveResident(context, res),
                                              ),
                                              if (res.isArchived)
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                                  tooltip: 'Delete Archived Account',
                                                  onPressed: () => _confirmDeleteResident(context, res),
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

                  // Pagination Footer Control
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing ${filteredResidents.isEmpty ? 0 : _currentPage * _pageSize + 1} - ${min((_currentPage + 1) * _pageSize, filteredResidents.length)} of ${filteredResidents.length} residents',
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
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Page ${_currentPage + 1} of $totalPages',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF059669), fontSize: 13),
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

  Widget _verificationBadge(BuildContext context, User res) {
    if (res.isVerified) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(12)),
        child: const Text('VERIFIED', style: TextStyle(color: Color(0xFF047857), fontSize: 10, fontWeight: FontWeight.bold)),
      );
    }

    return InkWell(
      onTap: () async {
        await context.read<AppState>().verifyResident(res.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Resident ${res.name} verified successfully!')),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(12)),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('PENDING (Verify)', style: TextStyle(color: Color(0xFFB45309), fontSize: 10, fontWeight: FontWeight.bold)),
            SizedBox(width: 4),
            Icon(Icons.check_circle_outline, size: 12, color: Color(0xFFB45309)),
          ],
        ),
      ),
    );
  }

  void _showAddResidentDialog(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final currentUid = appState.currentUser?.id ?? 'admin';
    final draftHelper = FormDraftHelper(formKey: 'add_resident', uid: currentUid);

    final firstNameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final purokCtrl = TextEditingController(text: 'Purok 1');
    final passwordCtrl = TextEditingController();

    bool obscurePassword = true;
    bool isVerified = true;
    String? errorMsg;

    // Load draft if available
    final draft = await draftHelper.loadDraft();
    if (draft != null) {
      firstNameCtrl.text = draft['firstName']?.toString() ?? '';
      lastNameCtrl.text = draft['lastName']?.toString() ?? '';
      usernameCtrl.text = draft['username']?.toString() ?? '';
      purokCtrl.text = draft['purok']?.toString() ?? 'Purok 1';
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
              Validators.validatePassword(passwordCtrl.text) == null;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Add New Resident Record', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      TextFormField(
                        controller: purokCtrl,
                        decoration: const InputDecoration(labelText: 'Purok / Zone *', prefixIcon: Icon(Icons.location_on_outlined)),
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
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Mark as Verified Resident', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Allow direct complaint filing', style: TextStyle(fontSize: 11)),
                        value: isVerified,
                        onChanged: (val) => setModalState(() => isVerified = val),
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
                        final purok = purokCtrl.text.trim().isEmpty ? 'Purok 1' : purokCtrl.text.trim();
                        final password = passwordCtrl.text;

                        final newUser = User(
                          id: 'res_${DateTime.now().millisecondsSinceEpoch}',
                          name: fullName,
                          username: username,
                          role: UserRole.resident,
                          purok: purok,
                          phoneNumber: username,
                          isVerified: isVerified,
                          password: password,
                        );

                        final err = await appState.registerUserWithoutSigningOutAdmin(newUser);

                        if (err != null) {
                          setModalState(() => errorMsg = err);
                          return;
                        }

                        await draftHelper.clearDraft();
                        if (dialogCtx.mounted) {
                          Navigator.pop(dialogCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Resident "$fullName" added successfully!')),
                          );
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add Resident'),
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

  void _showEditResidentDialog(BuildContext context, User resident) {
    final nameCtrl = TextEditingController(text: resident.name);
    final usernameCtrl = TextEditingController(text: resident.username ?? '');
    final phoneCtrl = TextEditingController(text: resident.phoneNumber);
    final purokCtrl = TextEditingController(text: resident.purok);
    final passwordCtrl = TextEditingController(text: resident.password ?? 'password');
    bool isVerified = resident.isVerified;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Edit Resident: ${resident.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  TextField(
                    controller: purokCtrl,
                    decoration: const InputDecoration(labelText: 'Purok / Zone', prefixIcon: Icon(Icons.location_on)),
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
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Verified Resident'),
                    value: isVerified,
                    onChanged: (val) => setModalState(() => isVerified = val),
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

                final updatedResident = User(
                  id: resident.id,
                  name: name,
                  username: username,
                  role: UserRole.resident,
                  purok: purok,
                  phoneNumber: phone,
                  isVerified: isVerified,
                  idImagePath: resident.idImagePath,
                  faceData: resident.faceData,
                  isArchived: resident.isArchived,
                  password: password,
                );

                await context.read<AppState>().updateUser(updatedResident);

                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Resident "$name" updated successfully!')),
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

  void _toggleArchiveResident(BuildContext context, User resident) {
    final isCurrentlyArchived = resident.isArchived;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(isCurrentlyArchived ? 'Restore Resident Account?' : 'Archive Resident Account?'),
        content: Text(
          isCurrentlyArchived
              ? 'Are you sure you want to restore ${resident.name}\'s account?'
              : 'Are you sure you want to archive ${resident.name}\'s account?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (isCurrentlyArchived) {
                await context.read<AppState>().restoreUser(resident.id);
              } else {
                await context.read<AppState>().archiveUser(resident.id);
              }
              if (dialogCtx.mounted) {
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isCurrentlyArchived
                          ? '${resident.name}\'s account restored.'
                          : '${resident.name}\'s account archived.',
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentlyArchived ? Colors.green : Colors.orange.shade800,
              foregroundColor: Colors.white,
            ),
            child: Text(isCurrentlyArchived ? 'Restore' : 'Archive'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteResident(BuildContext context, User resident) {
    if (!resident.isArchived) {
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
        title: const Text('Delete Archived Resident Record?'),
        content: Text('Are you sure you want to permanently delete archived resident ${resident.name}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final err = await context.read<AppState>().deleteUser(resident.id);
              if (dialogCtx.mounted) {
                Navigator.pop(dialogCtx);
                if (err != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Archived resident "${resident.name}" permanently deleted.')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  void _showResidentDetails(BuildContext context, User resident, List<Report> userReports) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.person_pin_rounded, color: Color(0xFF059669)),
            const SizedBox(width: 10),
            Expanded(child: Text(resident.name, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('User ID', resident.id),
                _detailRow('Username', resident.username ?? 'N/A'),
                _detailRow('Purok / Zone', resident.purok),
                _detailRow('Phone Number', resident.phoneNumber),
                _detailRow('Verification', resident.isVerified ? 'VERIFIED' : 'PENDING VERIFICATION'),
                _detailRow('Account Status', resident.isArchived ? 'ARCHIVED' : 'ACTIVE'),
                const Divider(height: 24),
                Text(
                  'Complaint History (${userReports.length} Submitted)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                if (userReports.isEmpty)
                  const Text('No complaints submitted by this resident.', style: TextStyle(fontSize: 12, color: Colors.grey))
                else
                  Column(
                    children: userReports.take(5).map((r) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  Text('${r.category} • ${r.purok}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDBEAFE),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                r.status.name.toUpperCase(),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Close'),
          ),
          if (!resident.isVerified)
            ElevatedButton.icon(
              onPressed: () async {
                await context.read<AppState>().verifyResident(resident.id);
                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Resident ${resident.name} verified successfully!')),
                  );
                }
              },
              icon: const Icon(Icons.verified_user_rounded, size: 16),
              label: const Text('Verify Resident'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
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
