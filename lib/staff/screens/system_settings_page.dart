import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../widgets/portal_theme.dart';

class SystemSettingsPage extends StatefulWidget {
  const SystemSettingsPage({super.key});

  @override
  State<SystemSettingsPage> createState() => _SystemSettingsPageState();
}

class _SystemSettingsPageState extends State<SystemSettingsPage> {
  final TextEditingController _nameController = TextEditingController(text: 'Barangay Tuntungin-Putho');
  final TextEditingController _municipalityController = TextEditingController(text: 'Los Baños');
  final TextEditingController _provinceController = TextEditingController(text: 'Laguna');
  final TextEditingController _contactController = TextEditingController(text: '(049) 536-1234 / +63 912 345');
  final TextEditingController _emailController = TextEditingController(text: 'contact@tuntunginputho-losb');
  final TextEditingController _addressController = TextEditingController(text: 'Barangay Putho Road Brgy. Tuntungin-Putho Los Baños, Laguna');
  final TextEditingController _hoursController = TextEditingController(text: 'Mon - Fri (8:00 AM - 5:00 PM) with 24/7 Tanod Desk');

  bool _hasUnsavedChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('barangay_info').get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = (data['name'] as String?) ?? 'Barangay Tuntungin-Putho';
          _municipalityController.text = (data['municipality'] as String?) ?? 'Los Baños';
          _provinceController.text = (data['province'] as String?) ?? 'Laguna';
          _contactController.text = (data['contact'] as String?) ?? '(049) 536-1234 / +63 912 345';
          _emailController.text = (data['email'] as String?) ?? 'contact@tuntunginputho-losb';
          _addressController.text = (data['address'] as String?) ?? 'Barangay Putho Road Brgy. Tuntungin-Putho Los Baños, Laguna';
          _hoursController.text = (data['hours'] as String?) ?? 'Mon - Fri (8:00 AM - 5:00 PM) with 24/7 Tanod Desk';
          _hasUnsavedChanges = false;
        });
      }
    } catch (_) {}
  }

  void _markChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  void _discardChanges() {
    _loadSettings();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Changes discarded.')),
    );
  }

  Future<void> _saveSettings() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final appState = Provider.of<AppState>(context, listen: false);
    final data = {
      'name': _nameController.text.trim(),
      'municipality': _municipalityController.text.trim(),
      'province': _provinceController.text.trim(),
      'contact': _contactController.text.trim(),
      'email': _emailController.text.trim(),
      'address': _addressController.text.trim(),
      'hours': _hoursController.text.trim(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    try {
      await FirebaseFirestore.instance.collection('settings').doc('barangay_info').set(data);
      appState.logActivity(action: 'Save Settings', complaintId: 'N/A', description: 'Updated system settings & office credentials');
      if (!mounted) return;
      setState(() {
        _hasUnsavedChanges = false;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuration saved successfully.')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save settings: $e')));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _municipalityController.dispose();
    _provinceController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header
        Container(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
          color: PortalColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'System Settings',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: PortalColors.textDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0E7FF),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                'CIVIC TECH v2.4',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3730A3),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Configure official barangay office credentials, jurisdiction details, and contact hotlines.',
                          style: TextStyle(fontSize: 13, color: PortalColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Body Content: General Office Profile
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(28),
            children: [
              _buildGeneralOfficeProfile(),
            ],
          ),
        ),

        // Bottom Action Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          decoration: const BoxDecoration(
            color: PortalColors.surface,
            border: Border(top: BorderSide(color: PortalColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (_hasUnsavedChanges)
                    Row(
                      children: [
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
                          'Unsaved changes pending save',
                          style: TextStyle(fontSize: 12, color: PortalColors.warning, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: _discardChanges,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PortalColors.textDark,
                      backgroundColor: const Color(0xFFF1F5F9),
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Discard All Changes'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveSettings,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_outline_rounded, size: 18),
                    label: Text(_isSaving ? 'Saving...' : 'Save Configuration Changes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  Widget _buildGeneralOfficeProfile() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PortalColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PortalColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.apartment_rounded, color: Color(0xFF2563EB), size: 22),
                  const SizedBox(width: 10),
                  const Text(
                    'Official Barangay Office Profile',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: PortalColors.textDark),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'LGU Verified',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Official jurisdiction identifiers formatted on blotter summaries, certificates, and resident clearances.',
            style: TextStyle(fontSize: 12, color: PortalColors.textMuted),
          ),
          const SizedBox(height: 24),

          // Barangay Official Name
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Barangay Official Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: PortalColors.textDark)),
              Text('${_nameController.text.length} / 100', style: const TextStyle(fontSize: 11, color: PortalColors.textMuted)),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            maxLength: 100,
            buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (_) => _markChanged(),
          ),
          const SizedBox(height: 16),

          // Municipality & Province
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Municipality / City', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: PortalColors.textDark)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _municipalityController,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (_) => _markChanged(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Province', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: PortalColors.textDark)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _provinceController,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (_) => _markChanged(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Hotline & Email
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Official Contact Hotline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: PortalColors.textDark)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _contactController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (_) => _markChanged(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Official Desk Email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: PortalColors.textDark)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email_outlined, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (_) => _markChanged(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Address
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Barangay Hall Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: PortalColors.textDark)),
              Text('${_addressController.text.length} / 150', style: const TextStyle(fontSize: 11, color: PortalColors.textMuted)),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _addressController,
            maxLines: 2,
            maxLength: 150,
            buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (_) => _markChanged(),
          ),
          const SizedBox(height: 16),

          // Operating Hours
          const Text('Office Operating Hours', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: PortalColors.textDark)),
          const SizedBox(height: 6),
          TextField(
            controller: _hoursController,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (_) => _markChanged(),
          ),
        ],
      ),
    );
  }
}
