import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/report.dart';
import '../../models/user.dart';
import '../widgets/portal_theme.dart';
import '../widgets/page_header.dart';
import '../widgets/status_badge.dart';
import '../widgets/badge_pill.dart';

class ComplaintListPage extends StatefulWidget {
  const ComplaintListPage({super.key});

  @override
  State<ComplaintListPage> createState() => _ComplaintListPageState();
}

class _ComplaintListPageState extends State<ComplaintListPage> {
  String _searchQuery = '';
  ReportStatus? _filterStatus;
  String? _filterCategory;
  String? _filterPurok;
  int _currentPage = 0;
  int _pageSize = 10;

  // Sorting
  String _sortColumn = 'Date';
  bool _sortAscending = false;

  Report? _selectedReportForDrawer;

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _filterStatus = null;
      _filterCategory = null;
      _filterPurok = null;
      _currentPage = 0;
    });
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _getRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return _formatDate(dt);
  }

  User? _resolveReporter(AppState appState, Report report) {
    if (report.reporterId == null || report.reporterId!.trim().isEmpty) return null;
    try {
      return appState.allUsers.firstWhere((user) => user.id == report.reporterId);
    } catch (_) {
      return null;
    }
  }

  bool _isAnonymousReport(AppState appState, Report report) {
    if (report.isAnonymous) return true;
    final reporter = _resolveReporter(appState, report);
    if (reporter != null && reporter.role != UserRole.guest) {
      return false;
    }
    return report.complainantName.trim().isEmpty;
  }

  String _resolveComplainantName(AppState appState, Report report) {
    if (report.complainantName.trim().isNotEmpty) {
      return report.complainantName.trim();
    }

    final reporter = _resolveReporter(appState, report);
    if (reporter != null && reporter.role != UserRole.guest) {
      return reporter.name;
    }

    return 'Anonymous';
  }

  String? _resolveAssignedStaffName(AppState appState, Report report) {
    if (report.assignedToId == null || report.assignedToId!.trim().isEmpty) {
      return null;
    }
    try {
      final user = appState.allUsers.firstWhere((u) => u.id == report.assignedToId);
      if (user.name.trim().isNotEmpty) return user.name.trim();
    } catch (_) {}
    return 'Assigned Staff';
  }

  void _showComplaintDialog(Report report) {
    final appState = context.read<AppState>();
    final reporter = _resolveReporter(appState, report);
    final isAnonymous = _isAnonymousReport(appState, report);
    final displayName = _resolveComplainantName(appState, report);
    final displayPhone = report.complainantPhone.isNotEmpty
        ? report.complainantPhone
        : (report.contactInfo?.isNotEmpty == true ? report.contactInfo! : (reporter != null && reporter.role != UserRole.guest ? reporter.phoneNumber : 'N/A'));
    final displayEmail = report.complainantEmail?.isNotEmpty == true ? report.complainantEmail! : 'N/A';
    ReportStatus selectedStatus = report.status;
    String? assignedStaffId = report.assignedToId;
    final staffList = appState.staffList;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.all(24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900, maxHeight: 720),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: PortalColors.border)),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Complaint Details',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Current Status:', style: TextStyle(fontWeight: FontWeight.w600, color: PortalColors.textMuted)),
                                StatusBadge(status: selectedStatus),
                              ],
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<ReportStatus>(
                              value: selectedStatus,
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'Update Status'),
                              items: ReportStatus.values.map((status) => DropdownMenuItem(value: status, child: Text(status.label, overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setDialogState(() => selectedStatus = value);
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: assignedStaffId,
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'Assign Staff to Take Action'),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Unassigned', overflow: TextOverflow.ellipsis)),
                                ...staffList.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis))),
                              ],
                              onChanged: (value) {
                                setDialogState(() => assignedStaffId = value);
                              },
                            ),
                            const SizedBox(height: 20),
                            const Text('Title', style: TextStyle(fontWeight: FontWeight.w600, color: PortalColors.textMuted, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(report.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 16),
                            const Text('Complainant', style: TextStyle(fontWeight: FontWeight.w600, color: PortalColors.textMuted, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              displayName,
                              style: TextStyle(
                                fontStyle: isAnonymous ? FontStyle.italic : FontStyle.normal,
                                color: isAnonymous ? PortalColors.textMuted : PortalColors.textDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text('Account Status', style: TextStyle(fontWeight: FontWeight.w600, color: PortalColors.textMuted, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(isAnonymous ? 'Anonymous Reporter' : (reporter != null && reporter.role != UserRole.guest ? 'Registered Resident' : 'Unknown')),
                            const SizedBox(height: 16),
                            const Text('Category & Location', style: TextStyle(fontWeight: FontWeight.w600, color: PortalColors.textMuted, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('${report.category} • ${report.purok.isNotEmpty ? report.purok : 'Purok 1'}'),
                            const SizedBox(height: 16),
                            const Text('Contact Details', style: TextStyle(fontWeight: FontWeight.w600, color: PortalColors.textMuted, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text('Phone: $displayPhone\nEmail: $displayEmail', style: const TextStyle(height: 1.6)),
                            const SizedBox(height: 16),
                            const Text('Description', style: TextStyle(fontWeight: FontWeight.w600, color: PortalColors.textMuted, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(report.description, style: const TextStyle(height: 1.6)),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: PortalColors.border)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('Close'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              context.read<AppState>().updateReportStatus(report.id, selectedStatus);
                              if (assignedStaffId != null) {
                                context.read<AppState>().assignStaff(report.id, assignedStaffId!);
                              }
                              Navigator.of(dialogContext).pop();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complaint updated successfully.')));
                              }
                            },
                            child: const Text('Save Changes'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final categories = appState.categories;
    final purokOptions = ['Purok 1', 'Purok 2', 'Purok 3', 'Purok 4', 'Purok 5', 'Purok 6'];

    List<Report> filteredReports = appState.reports.where((r) {
      final resolvedComplainantName = _resolveComplainantName(appState, r);
      final reporterName = _resolveReporter(appState, r)?.name ?? '';
      final matchesSearch = resolvedComplainantName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          reporterName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.id.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = _filterStatus == null || r.status == _filterStatus;
      final matchesCategory = _filterCategory == null || r.category == _filterCategory;
      final matchesPurok = _filterPurok == null || r.purok == _filterPurok;

      return matchesSearch && matchesStatus && matchesCategory && matchesPurok;
    }).toList();

    // Sorting
    filteredReports.sort((a, b) {
      int cmp = 0;
      if (_sortColumn == 'Date') {
        cmp = a.timestamp.compareTo(b.timestamp);
      } else if (_sortColumn == 'Status') {
        cmp = a.status.name.compareTo(b.status.name);
      } else if (_sortColumn == 'Category') {
        cmp = a.category.compareTo(b.category);
      }
      return _sortAscending ? cmp : -cmp;
    });

    final int totalPages = max(1, (filteredReports.length / _pageSize).ceil());
    if (_currentPage >= totalPages) {
      _currentPage = totalPages - 1;
    }

    final paginatedReports = filteredReports.skip(_currentPage * _pageSize).take(_pageSize).toList();
    final screenWidth = MediaQuery.of(context).size.width;
    final hideLowPriorityColumns = screenWidth < 1200;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Complaint Management',
                description: 'Review, assign, and manage resident complaints and emergency dispatches.',
                breadcrumbs: const ['Dashboard', 'Complaints'],
              ),
              // Filter Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                decoration: const BoxDecoration(
                  color: PortalColors.surface,
                  border: Border(bottom: BorderSide(color: PortalColors.border)),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            SizedBox(
                              width: 280,
                              child: TextField(
                                decoration: const InputDecoration(
                                  hintText: 'Search name, ref no., or description',
                                  prefixIcon: Icon(Icons.search_rounded, size: 18, color: PortalColors.textMuted),
                                ),
                                onChanged: (v) {
                                  setState(() {
                                    _searchQuery = v;
                                    _currentPage = 0;
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              width: 180,
                              child: DropdownButtonFormField<String>(
                                value: _filterCategory,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: 'Category'),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('All Categories', overflow: TextOverflow.ellipsis)),
                                  ...categories.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))),
                                ],
                                onChanged: (v) {
                                  setState(() {
                                    _filterCategory = v;
                                    _currentPage = 0;
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              width: 150,
                              child: DropdownButtonFormField<String>(
                                value: _filterPurok,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: 'Purok'),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('All Puroks', overflow: TextOverflow.ellipsis)),
                                  ...purokOptions.map((p) => DropdownMenuItem(value: p, child: Text(p, overflow: TextOverflow.ellipsis))),
                                ],
                                onChanged: (v) {
                                  setState(() {
                                    _filterPurok = v;
                                    _currentPage = 0;
                                  });
                                },
                              ),
                            ),
                            SizedBox(
                              width: 160,
                              child: DropdownButtonFormField<ReportStatus>(
                                value: _filterStatus,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: 'Status'),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('All Status', overflow: TextOverflow.ellipsis)),
                                  ...ReportStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label, overflow: TextOverflow.ellipsis))),
                                ],
                                onChanged: (v) {
                                  setState(() {
                                    _filterStatus = v;
                                    _currentPage = 0;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        // Right-aligned Reset & Refresh
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded, size: 18, color: PortalColors.textMuted),
                              onPressed: _resetFilters,
                              tooltip: 'Reset Filters',
                            ),
                            TextButton.icon(
                              onPressed: _resetFilters,
                              icon: const Icon(Icons.close_rounded, size: 16),
                              label: const Text('Reset'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              onPressed: () => _showDeleteAllConfirmationDialog(context),
                              icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                              label: const Text('Delete All'),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              // DataTable View
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
                          child: filteredReports.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.search_off_rounded, size: 48, color: PortalColors.textMuted),
                                      const SizedBox(height: 12),
                                      const Text('No complaints match your filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 8),
                                      const Text('Try adjusting your search query or filter options.', style: TextStyle(color: PortalColors.textMuted, fontSize: 13)),
                                      const SizedBox(height: 16),
                                      OutlinedButton(
                                        onPressed: _resetFilters,
                                        child: const Text('Reset Filters'),
                                      ),
                                    ],
                                  ),
                                )
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    return SingleChildScrollView(
                                      scrollDirection: Axis.vertical,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                        child: DataTable(
                                          headingRowColor: MaterialStateProperty.all(PortalColors.background),
                                          dataRowMinHeight: 52,
                                          dataRowMaxHeight: 52,
                                          showCheckboxColumn: false,
                                          columns: [
                                            const DataColumn(label: Text('Complainant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                            DataColumn(
                                              label: const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                              onSort: (_, __) {
                                                setState(() {
                                                  if (_sortColumn == 'Category') {
                                                    _sortAscending = !_sortAscending;
                                                  } else {
                                                    _sortColumn = 'Category';
                                                    _sortAscending = true;
                                                  }
                                                });
                                              },
                                            ),
                                            const DataColumn(label: Text('Purok', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                            DataColumn(
                                              label: const Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                              onSort: (_, __) {
                                                setState(() {
                                                  if (_sortColumn == 'Date') {
                                                    _sortAscending = !_sortAscending;
                                                  } else {
                                                    _sortColumn = 'Date';
                                                    _sortAscending = true;
                                                  }
                                                });
                                              },
                                            ),
                                            DataColumn(
                                              label: const Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                              onSort: (_, __) {
                                                setState(() {
                                                  if (_sortColumn == 'Status') {
                                                    _sortAscending = !_sortAscending;
                                                  } else {
                                                    _sortColumn = 'Status';
                                                    _sortAscending = true;
                                                  }
                                                });
                                              },
                                            ),
                                            if (!hideLowPriorityColumns)
                                              const DataColumn(label: Text('Assigned To', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                            const DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                          ],
                                          rows: paginatedReports.map((r) {
                                            final isSelected = _selectedReportForDrawer?.id == r.id;
                                            final isEmergency = r.category.toLowerCase().contains('emergency') || r.isSOS;

                                            Widget wrapCell(Widget child) {
                                              return GestureDetector(
                                                behavior: HitTestBehavior.opaque,
                                                onTap: () {
                                                  setState(() => _selectedReportForDrawer = r);
                                                  _showComplaintDialog(r);
                                                },
                                                child: MouseRegion(
                                                  cursor: SystemMouseCursors.click,
                                                  child: SizedBox(
                                                    width: double.infinity,
                                                    height: 52,
                                                    child: Align(
                                                      alignment: Alignment.centerLeft,
                                                      child: child,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }

                                            return DataRow(
                                              selected: isSelected,
                                              color: MaterialStateProperty.resolveWith<Color?>((states) {
                                                if (isSelected) return PortalColors.primary.withOpacity(0.06);
                                                if (states.contains(MaterialState.hovered)) return PortalColors.background;
                                                return null;
                                              }),
                                              cells: [
                                                DataCell(
                                                  wrapCell(
                                                    Text(
                                                      _resolveComplainantName(appState, r),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontStyle: _isAnonymousReport(appState, r) ? FontStyle.italic : FontStyle.normal,
                                                        color: _isAnonymousReport(appState, r) ? PortalColors.textMuted : PortalColors.textDark,
                                                      ),
                                                    ),
                                                  ),
                                                ),                                                DataCell(
                                                  wrapCell(
                                                    Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        if (isEmergency)
                                                          Container(
                                                            width: 6,
                                                            height: 6,
                                                            margin: const EdgeInsets.only(right: 6),
                                                            decoration: const BoxDecoration(color: PortalColors.danger, shape: BoxShape.circle),
                                                          ),
                                                        Text(r.category, style: const TextStyle(fontSize: 12)),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  wrapCell(
                                                    Text(r.purok.isNotEmpty ? r.purok : 'Purok 1', style: const TextStyle(fontSize: 12)),
                                                  ),
                                                ),
                                                DataCell(
                                                  wrapCell(
                                                    Tooltip(
                                                      message: _getRelativeTime(r.timestamp),
                                                      child: Text(_formatDate(r.timestamp), style: const TextStyle(fontSize: 12)),
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  wrapCell(
                                                    StatusBadge(status: r.status),
                                                  ),
                                                ),
                                                if (!hideLowPriorityColumns)
                                                  DataCell(
                                                    wrapCell(
                                                      r.assignedToId != null && r.assignedToId!.trim().isNotEmpty
                                                          ? BadgePill.assigned(staffName: _resolveAssignedStaffName(appState, r))
                                                          : BadgePill.unassigned(),
                                                    ),
                                                  ),
                                                DataCell(
                                                  TextButton.icon(
                                                    onPressed: () {
                                                      setState(() => _selectedReportForDrawer = r);
                                                      _showComplaintDialog(r);
                                                    },
                                                    icon: const Icon(Icons.visibility_outlined, size: 14),
                                                    label: const Text('View'),
                                                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                                  ),
                                                ),
                                              ],
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        // Compact Pagination Footer
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: PortalColors.border)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Showing ${filteredReports.isEmpty ? 0 : _currentPage * _pageSize + 1} - ${min((_currentPage + 1) * _pageSize, filteredReports.length)} of ${filteredReports.length}',
                                style: const TextStyle(color: PortalColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              Row(
                                children: [
                                  const Text('Rows per page:', style: TextStyle(color: PortalColors.textMuted, fontSize: 12)),
                                  const SizedBox(width: 8),
                                  DropdownButton<int>(
                                    value: _pageSize,
                                    items: [10, 25, 50].map((s) => DropdownMenuItem(value: s, child: Text('$s', style: const TextStyle(fontSize: 12)))).toList(),
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() {
                                          _pageSize = v;
                                          _currentPage = 0;
                                        });
                                      }
                                    },
                                    underline: const SizedBox(),
                                  ),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left_rounded, size: 20),
                                    onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                                    tooltip: 'Previous page',
                                  ),
                                  Text(
                                    'Page ${_currentPage + 1} of $totalPages',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right_rounded, size: 20),
                                    onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                                    tooltip: 'Next page',
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
}
