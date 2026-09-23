import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/report.dart';

class ComplaintDetailsPage extends StatefulWidget {
  final Report report;
  const ComplaintDetailsPage({super.key, required this.report});

  @override
  State<ComplaintDetailsPage> createState() => _ComplaintDetailsPageState();
}

class _ComplaintDetailsPageState extends State<ComplaintDetailsPage> {
  final _notesController = TextEditingController();
  final _actionController = TextEditingController();
  late ReportStatus _selectedStatus;
  String? _assignedStaffId;
  late String _selectedPriority;

  @override
  void initState() {
    super.initState();
    _notesController.text = widget.report.investigationNotes ?? '';
    _actionController.text = widget.report.actionTaken ?? '';
    _selectedStatus = widget.report.status;
    _assignedStaffId = widget.report.assignedToId;
    _selectedPriority = widget.report.priority;
  }

  void _saveChanges() {
    final appState = context.read<AppState>();
    
    appState.updateReportStatus(
      widget.report.id, 
      _selectedStatus, 
      notes: _notesController.text,
      actionTaken: _actionController.text,
    );
    
    if (_assignedStaffId != widget.report.assignedToId && _assignedStaffId != null) {
      appState.assignStaff(widget.report.id, _assignedStaffId!);
    }
    
    appState.updatePriority(widget.report.id, _selectedPriority);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Changes saved successfully.')));
  }

  @override
  Widget build(BuildContext context) {
    final staffList = context.watch<AppState>().staffList;

    return Scaffold(
      appBar: AppBar(
        title: Text('Complaint: ${widget.report.id}'),
        actions: [
          ElevatedButton.icon(
            onPressed: _saveChanges,
            icon: const Icon(Icons.save),
            label: const Text('Save Changes'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Info
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('Complainant Information', [
                    _buildInfoTile('Name', widget.report.complainantName),
                    _buildInfoTile('Phone', widget.report.complainantPhone),
                    _buildInfoTile('Email', widget.report.complainantEmail ?? 'N/A'),
                  ]),
                  const SizedBox(height: 24),
                  _buildSection('Incident Details', [
                    _buildInfoTile('Category', widget.report.category),
                    _buildInfoTile('Location', widget.report.incidentLocation),
                    _buildInfoTile('Date/Time', widget.report.incidentDateTime.toString()),
                    _buildInfoTile('Description', widget.report.description, isMultiLine: true),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 24),
            // Right Column: Investigation & Actions
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('Management & Investigation', [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<ReportStatus>(
                            value: _selectedStatus,
                            decoration: const InputDecoration(labelText: 'Current Status', border: OutlineInputBorder()),
                            items: ReportStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()))).toList(),
                            onChanged: (v) => setState(() => _selectedStatus = v!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedPriority,
                            decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                            items: ['Low', 'Medium', 'High'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                            onChanged: (v) => setState(() => _selectedPriority = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _assignedStaffId,
                      decoration: const InputDecoration(labelText: 'Assign to Staff', border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Unassigned')),
                        ...staffList.map((s) => DropdownMenuItem(value: s.id, child: Text("${s.name} (${s.staffRole?.name ?? 'Staff'})"))),
                      ],
                      onChanged: (v) => setState(() => _assignedStaffId = v),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notesController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Investigation Notes',
                        border: OutlineInputBorder(),
                        hintText: 'Add findings from investigation...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _actionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Action Taken',
                        border: OutlineInputBorder(),
                        hintText: 'What steps were taken to resolve this?',
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 30),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, {bool isMultiLine = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: isMultiLine ? FontWeight.normal : FontWeight.w500)),
        ],
      ),
    );
  }
}
