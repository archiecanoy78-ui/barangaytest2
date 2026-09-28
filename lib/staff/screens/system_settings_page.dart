import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../widgets/portal_theme.dart';
import '../widgets/page_header.dart';

class SystemSettingsPage extends StatefulWidget {
  const SystemSettingsPage({super.key});

  @override
  State<SystemSettingsPage> createState() => _SystemSettingsPageState();
}

class _SystemSettingsPageState extends State<SystemSettingsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _contactFocusNode = FocusNode();
  final FocusNode _addressFocusNode = FocusNode();

  String? _nameError;
  String? _contactError;
  String? _addressError;

  bool _allowGuest = true;
  bool _requireEvidence = true;
  bool _allowAnonymous = false;
  bool _autoGenerateId = true;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();

    _nameFocusNode.addListener(() {
      if (!_nameFocusNode.hasFocus) {
        setState(() => _validateName());
      }
    });

    _contactFocusNode.addListener(() {
      if (!_contactFocusNode.hasFocus) {
        setState(() => _validateContact());
      }
    });

    _addressFocusNode.addListener(() {
      if (!_addressFocusNode.hasFocus) {
        setState(() => _validateAddress());
      }
    });

    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final doc = await FirebaseFirestore.instance.collection('settings').doc('barangay_info').get();
    if (doc.exists) {
      final data = doc.data()!;
      _nameController.text = (data['name'] as String?) ?? 'Barangay San Isidro';
      
      // Clean raw contact to digits only
      final rawContact = (data['contact'] as String?) ?? '09171234567';
      _contactController.text = rawContact.replaceAll(RegExp(r'[^0-9]'), '');
      
      _addressController.text = (data['address'] as String?) ?? 'San Isidro, Bulacan';
      setState(() {
        _allowGuest = (data['allowGuest'] as bool?) ?? true;
        _requireEvidence = (data['requireEvidence'] as bool?) ?? true;
        _allowAnonymous = (data['allowAnonymous'] as bool?) ?? false;
        _autoGenerateId = (data['autoGenerateId'] as bool?) ?? true;
        _hasUnsavedChanges = false;
        _nameError = null;
        _contactError = null;
        _addressError = null;
      });
    } else {
      _nameController.text = 'Barangay San Isidro';
      _contactController.text = '09171234567';
      _addressController.text = 'San Isidro, Bulacan';
    }
  }

  void _markChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  void _validateName() {
    final text = _nameController.text.trim();
    if (text.isEmpty) {
      _nameError = 'Barangay Name is required.';
    } else if (_nameController.text.length > 150) {
      _nameError = 'Maximum 150 characters allowed.';
    } else {
      _nameError = null;
    }
  }

  void _validateContact() {
    final text = _contactController.text.trim();
    if (text.length != 11 || !text.startsWith('09')) {
      _contactError = 'Enter 11 digits starting with 09, e.g. 09171234567';
    } else {
      _contactError = null;
    }
  }

  void _validateAddress() {
    final text = _addressController.text.trim();
    if (text.isEmpty) {
      _addressError = 'Barangay Hall Address is required.';
    } else if (_addressController.text.length > 150) {
      _addressError = 'Maximum 150 characters allowed.';
    } else {
      _addressError = null;
    }
  }

  bool _validateAll() {
    setState(() {
      _validateName();
      _validateContact();
      _validateAddress();
    });
    return _nameError == null && _contactError == null && _addressError == null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _addressController.dispose();

    _nameFocusNode.dispose();
    _contactFocusNode.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_validateAll()) return;

    final appState = Provider.of<AppState>(context, listen: false);
    final data = {
      'name': _nameController.text.trim(),
      'contact': _contactController.text.trim(),
      'address': _addressController.text.trim(),
      'allowGuest': _allowGuest,
      'requireEvidence': _requireEvidence,
      'allowAnonymous': _allowAnonymous,
      'autoGenerateId': _autoGenerateId,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    try {
      await FirebaseFirestore.instance.collection('settings').doc('barangay_info').set(data);
      appState.logActivity(action: 'Save Settings', complaintId: 'N/A', description: 'Updated barangay configuration');
      if (!mounted) return;
      setState(() => _hasUnsavedChanges = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved successfully.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save settings: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isFormValid = _nameError == null &&
        _contactError == null &&
        _addressError == null &&
        _contactController.text.trim().length == 11 &&
        _contactController.text.trim().startsWith('09') &&
        _nameController.text.trim().isNotEmpty &&
        _addressController.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'System Settings',
          description: 'Configure barangay office information, operational preferences, and complaint reporting rules.',
          breadcrumbs: const ['Dashboard', 'Settings'],
          actionButton: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_hasUnsavedChanges) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: PortalColors.warning,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Unsaved changes',
                  style: TextStyle(
                    color: PortalColors.warning,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              ElevatedButton.icon(
                onPressed: (_hasUnsavedChanges && isFormValid)
                    ? () {
                        if (_validateAll()) {
                          _saveSettings();
                        }
                      }
                    : null,
                icon: const Icon(Icons.save_rounded, size: 16),
                label: const Text('Save changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PortalColors.primary,
                  disabledBackgroundColor: PortalColors.border,
                  disabledForegroundColor: PortalColors.textMuted,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(28),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Barangay Info
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: PortalColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: PortalColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Barangay Office Profile',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: PortalColors.textDark),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Official details displayed on resident headers and exported blotter forms.',
                            style: TextStyle(fontSize: 12, color: PortalColors.textMuted),
                          ),
                          const SizedBox(height: 24),

                          // Barangay Name (150 char max + live counter)
                          TextField(
                            controller: _nameController,
                            focusNode: _nameFocusNode,
                            maxLength: 150,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(150),
                            ],
                            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                            decoration: InputDecoration(
                              labelText: 'Barangay Name',
                              errorText: _nameError,
                              counterText: '',
                            ),
                            onChanged: (_) {
                              _markChanged();
                              setState(() => _validateName());
                            },
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${_nameController.text.length} / 150',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: _nameController.text.length > 150 ? PortalColors.danger : PortalColors.textMuted,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Official Contact Number (11 digits starting with 09)
                          TextField(
                            controller: _contactController,
                            focusNode: _contactFocusNode,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Official Contact Number',
                              hintText: '09171234567',
                              errorText: _contactError,
                              errorMaxLines: 2,
                            ),
                            onChanged: (_) {
                              _markChanged();
                              setState(() => _validateContact());
                            },
                          ),
                          const SizedBox(height: 16),

                          // Barangay Hall Address (150 char max + live counter)
                          TextField(
                            controller: _addressController,
                            focusNode: _addressFocusNode,
                            maxLines: 3,
                            maxLength: 150,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(150),
                            ],
                            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                            decoration: InputDecoration(
                              labelText: 'Barangay Hall Address',
                              errorText: _addressError,
                              counterText: '',
                            ),
                            onChanged: (_) {
                              _markChanged();
                              setState(() => _validateAddress());
                            },
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${_addressController.text.length} / 150',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: _addressController.text.length > 150 ? PortalColors.danger : PortalColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Right Column: Complaint Rules & Configuration
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: PortalColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: PortalColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Complaint Reporting Rules',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: PortalColors.textDark),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Define reporting permissions and validation constraints for resident submissions.',
                            style: TextStyle(fontSize: 12, color: PortalColors.textMuted),
                          ),
                          const SizedBox(height: 20),
                          _buildSettingToggleCard(
                            title: 'Allow Guest Submissions',
                            subtitle: 'Allow unregistered visitors to file basic incident reports.',
                            value: _allowGuest,
                            accentColor: PortalColors.warning, // Amber accent for loosening restrictions
                            onChanged: (v) {
                              setState(() => _allowGuest = v);
                              _markChanged();
                            },
                          ),
                          _buildSettingToggleCard(
                            title: 'Require Evidence Attachment',
                            subtitle: 'Mandate photo or document evidence for formal complaint verification.',
                            value: _requireEvidence,
                            accentColor: PortalColors.success, // Green accent for tightening submissions
                            onChanged: (v) {
                              setState(() => _requireEvidence = v);
                              _markChanged();
                            },
                          ),
                          _buildSettingToggleCard(
                            title: 'Allow Anonymous Reporting',
                            subtitle: 'Allow residents to file complaints without disclosing their name.',
                            value: _allowAnonymous,
                            accentColor: PortalColors.warning, // Amber accent for loosening restrictions
                            onChanged: (v) {
                              setState(() => _allowAnonymous = v);
                              _markChanged();
                            },
                          ),
                          _buildSettingToggleCard(
                            title: 'Auto-Generate Complaint Reference ID',
                            subtitle: 'Automatically assign structured tracking numbers (e.g. BRGY-2026-XXXX).',
                            value: _autoGenerateId,
                            accentColor: PortalColors.success, // Green accent for tightening submissions
                            onChanged: (v) {
                              setState(() => _autoGenerateId = v);
                              _markChanged();
                            },
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Database Maintenance & Danger Zone',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Permanent database operations. Use with extreme caution.',
                            style: TextStyle(fontSize: 12, color: PortalColors.textMuted),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Delete All Complaints',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 14),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Permanently remove all resident complaints and incident reports from Firestore.',
                                        style: TextStyle(fontSize: 12, color: PortalColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => _showDeleteAllConfirmationDialog(context),
                                  child: const Text('Delete All'),
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
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteAllConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete All Complaints?', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: const Text(
          'This action is PERMANENT and cannot be undone. All resident complaints, emergency records, and tracking logs will be deleted from the database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                final appState = Provider.of<AppState>(context, listen: false);
                await appState.deleteAllComplaints();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All complaints have been deleted from the database.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete complaints: $e')),
                  );
                }
              }
            },
            child: const Text('Confirm Delete All'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingToggleCard({
    required String title,
    required String subtitle,
    required bool value,
    required Color accentColor,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: PortalColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          top: const BorderSide(color: PortalColors.border),
          right: const BorderSide(color: PortalColors.border),
          bottom: const BorderSide(color: PortalColors.border),
          left: BorderSide(color: accentColor, width: 4),
        ),
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: PortalColors.textDark)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: PortalColors.textMuted)),
        value: value,
        activeColor: PortalColors.primary,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
