import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../app_state.dart';

class SystemSettingsPage extends StatefulWidget {
  const SystemSettingsPage({super.key});

  @override
  State<SystemSettingsPage> createState() => _SystemSettingsPageState();
}

class _SystemSettingsPageState extends State<SystemSettingsPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _allowGuest = true;
  bool _requireEvidence = true;
  bool _allowAnonymous = false;
  bool _autoGenerateId = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final doc = await FirebaseFirestore.instance.collection('settings').doc('barangay_info').get();
    if (doc.exists) {
      final data = doc.data()!;
      _nameController.text = (data['name'] as String?) ?? 'Barangay San Isidro';
      _contactController.text = (data['contact'] as String?) ?? '0917-123-4567';
      _addressController.text = (data['address'] as String?) ?? 'San Isidro, Bulacan';
      // load flags if stored
      setState(() {
        _allowGuest = (data['allowGuest'] as bool?) ?? true;
        _requireEvidence = (data['requireEvidence'] as bool?) ?? true;
        _allowAnonymous = (data['allowAnonymous'] as bool?) ?? false;
        _autoGenerateId = (data['autoGenerateId'] as bool?) ?? true;
      });
    } else {
      // defaults
      _nameController.text = 'Barangay San Isidro';
      _contactController.text = '0917-123-4567';
      _addressController.text = 'San Isidro, Bulacan';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
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
      appState.logActivity(action: 'Save Settings', complaintId: 'N/A', description: 'Updated barangay settings');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save settings: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('System Settings'), backgroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Barangay Info
            Expanded(
              child: _settingsSection('Barangay Information', [
                _textField('Barangay Name', controller: _nameController),
                const SizedBox(height: 20),
                _textField('Contact Number', controller: _contactController),
                const SizedBox(height: 20),
                _textField('Address', controller: _addressController, lines: 3),
              ]),
            ),
            const SizedBox(width: 32),
            // Right Column: System Config
            Expanded(
              child: Column(
                children: [
                  _settingsSection('Complaint Settings', [
                    _switchTile('Allow Guest Complaints', _allowGuest, (v) => setState(() => _allowGuest = v)),
                    _switchTile('Require Evidence', _requireEvidence, (v) => setState(() => _requireEvidence = v)),
                    _switchTile('Allow Anonymous Reports', _allowAnonymous, (v) => setState(() => _allowAnonymous = v)),
                    _switchTile('Auto Generate Complaint ID', _autoGenerateId, (v) => setState(() => _autoGenerateId = v)),
                  ]),
                  const SizedBox(height: 32),
                  _settingsSection('Notification Settings', [
                    _switchTile('Complaint Submitted', true, (v) {}),
                    _switchTile('Status Changed', true, (v) {}),
                    _switchTile('Complaint Resolved', false, (v) {}),
                  ]),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Save Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsSection(String title, List<Widget> content) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          ...content,
        ],
      ),
    );
  }

  Widget _textField(String label, {required TextEditingController controller, int lines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: lines,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ],
    );
  }

  Widget _switchTile(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFF2563EB)),
        ],
      ),
    );
  }
}
