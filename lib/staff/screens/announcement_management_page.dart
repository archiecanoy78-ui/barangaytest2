import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/announcement.dart';
import '../widgets/portal_theme.dart';
import '../widgets/page_header.dart';
import '../widgets/badge_pill.dart';

class AnnouncementManagementPage extends StatefulWidget {
  const AnnouncementManagementPage({super.key});

  @override
  State<AnnouncementManagementPage> createState() => _AnnouncementManagementPageState();
}

class _AnnouncementManagementPageState extends State<AnnouncementManagementPage> {
  String? _selectedCategory;
  int _currentPage = 0;
  static const int _pageSize = 8;

  final List<String> _categoryOptions = [
    'Water Service',
    'Community Clean-up',
    'Public Health',
    'Road Advisory',
    'Community Sports',
    'Emergency Prep',
    'General Notice',
  ];

  final List<String> _priorityOptions = ['High', 'Normal', 'Low'];
  final List<String> _zoneOptions = [
    'All Puroks',
    'All Zones',
    'Zone 1-4',
    'Health Center',
    'Mabini St.',
    'Gymnasium',
    'Hall A',
    'Purok 1',
    'Purok 2',
    'Purok 3',
    'Purok 4',
    'Purok 5',
    'Purok 6',
  ];
  final List<String> _statusOptions = ['Active', 'Draft', 'Archived'];

  void _showAnnouncementDialog([Announcement? announcement]) {
    final titleController = TextEditingController(text: announcement?.title ?? '');
    final contentController = TextEditingController(text: announcement?.content ?? '');
    String category = announcement?.type ?? _categoryOptions.first;
    String priority = announcement?.priority ?? 'Normal';
    String zone = announcement?.zone ?? 'All Puroks';
    String status = announcement?.status ?? 'Active';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: Text(
            announcement == null ? 'Create Barangay Announcement' : 'Edit Announcement',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. Water Service Interruption Advisory'),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: category,
                          decoration: const InputDecoration(labelText: 'Category'),
                          items: _categoryOptions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => setModalState(() => category = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: priority,
                          decoration: const InputDecoration(labelText: 'Priority'),
                          items: _priorityOptions.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                          onChanged: (v) => setModalState(() => priority = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: zone,
                          decoration: const InputDecoration(labelText: 'Target Purok'),
                          items: _zoneOptions.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
                          onChanged: (v) => setModalState(() => zone = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: status,
                          decoration: const InputDecoration(labelText: 'Status'),
                          items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) => setModalState(() => status = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Announcement Content', hintText: 'Provide full details here...'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;
                final appState = context.read<AppState>();
                final newAnnouncement = Announcement(
                  id: announcement?.id,
                  title: titleController.text.trim(),
                  content: contentController.text.trim(),
                  date: announcement?.date ?? DateTime.now(),
                  type: category,
                  priority: priority,
                  zone: zone,
                  status: status,
                );

                if (announcement == null) {
                  await appState.addAnnouncement(newAnnouncement);
                } else {
                  await appState.updateAnnouncement(newAnnouncement);
                }

                if (mounted) Navigator.pop(dialogContext);
              },
              child: Text(announcement == null ? 'Publish' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Announcement announcement) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text('Delete Announcement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('Are you sure you want to delete "${announcement.title}"? This action cannot be undone.'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: PortalColors.danger),
            onPressed: () async {
              await context.read<AppState>().deleteAnnouncement(announcement.id ?? announcement.title);
              if (mounted) Navigator.pop(dialogCtx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final announcements = appState.announcements;

    final filtered = announcements.where((a) {
      if (_selectedCategory == null) return true;
      return a.type == _selectedCategory;
    }).toList();

    final totalPages = max(1, (filtered.length / _pageSize).ceil());
    if (_currentPage >= totalPages) _currentPage = totalPages - 1;
    final paginated = filtered.skip(_currentPage * _pageSize).take(_pageSize).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Barangay Announcements',
          description: 'Publish advisories, emergency alerts, and public notices to resident apps.',
          breadcrumbs: const ['Dashboard', 'Announcements'],
          actionButton: ElevatedButton.icon(
            onPressed: () => _showAnnouncementDialog(),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('New Announcement'),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Container(
              decoration: BoxDecoration(
                color: PortalColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: PortalColors.border),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: paginated.isEmpty
                        ? const Center(child: Text('No announcements posted.', style: TextStyle(color: PortalColors.textMuted)))
                        : SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: MaterialStateProperty.all(PortalColors.background),
                                dataRowMinHeight: 52,
                                dataRowMaxHeight: 52,
                                columns: const [
                                  DataColumn(label: Text('Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataColumn(label: Text('Target Purok', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataColumn(label: Text('Priority', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                ],
                                rows: paginated.map((a) {
                                  return DataRow(cells: [
                                    DataCell(Text(a.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                                    DataCell(Text(a.type, style: const TextStyle(fontSize: 12))),
                                    DataCell(Text(a.zone.isNotEmpty ? a.zone : 'All Puroks', style: const TextStyle(fontSize: 12))),
                                    DataCell(BadgePill.priority(a.priority)),
                                    DataCell(Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: a.status == 'Active' ? PortalColors.success.withOpacity(0.1) : PortalColors.warning.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        a.status,
                                        style: TextStyle(
                                          color: a.status == 'Active' ? PortalColors.success : PortalColors.warning,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    )),
                                    DataCell(Text(a.date.toLocal().toString().split(' ')[0], style: const TextStyle(fontSize: 12))),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined, size: 16, color: PortalColors.primary),
                                            onPressed: () => _showAnnouncementDialog(a),
                                            tooltip: 'Edit',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: PortalColors.danger),
                                            onPressed: () => _confirmDelete(a),
                                            tooltip: 'Delete',
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
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
