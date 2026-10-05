import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/report.dart';
import '../../models/user.dart';
import '../widgets/report_card.dart';
import 'community_report_details_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';
  String _sortBy = 'Newest First';
  bool _isLoading = false;
  String? _error;

  Future<void> _refreshFeed() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleUpvote(Report report) async {
    final appState = context.read<AppState>();
    if (appState.currentUser == null || appState.currentUser?.role == UserRole.guest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in as a resident to upvote community reports.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      await appState.toggleUpvote(report.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentUserId = appState.currentUser?.id;

    List<Report> filteredReports = appState.reports.where((r) {
      if (_selectedCategory != 'All' && r.category != _selectedCategory) {
        return false;
      }
      if (_selectedStatus != 'All') {
        if (_selectedStatus == 'Pending' && r.status != ReportStatus.pending) return false;
        if (_selectedStatus == 'In Progress' && r.status != ReportStatus.under_investigation) return false;
        if (_selectedStatus == 'Resolved' && r.status != ReportStatus.resolved) return false;
      }
      return true;
    }).toList();

    if (_sortBy == 'Most Upvoted') {
      filteredReports.sort((a, b) => b.upvoteCount.compareTo(a.upvoteCount));
    } else {
      filteredReports.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }

    final categories = ['All', ...appState.categories];
    final statusList = ['All', 'Pending', 'In Progress', 'Resolved'];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Community Feed',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0F172A)),
            onPressed: _refreshFeed,
            tooltip: 'Refresh Feed',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshFeed,
        color: const Color(0xFF1D4ED8),
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Public Incident Reports',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _sortBy,
                              isDense: true,
                              icon: const Icon(Icons.sort_rounded, size: 16, color: Color(0xFF1D4ED8)),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                              items: const [
                                DropdownMenuItem(value: 'Newest First', child: Text('Newest First')),
                                DropdownMenuItem(value: 'Most Upvoted', child: Text('Most Upvoted')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _sortBy = v);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isSelected = _selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor: const Color(0xFF1D4ED8),
                          backgroundColor: const Color(0xFFF1F5F9),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFF475569),
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _selectedCategory = cat);
                          },
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          showCheckmark: false,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 32,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: statusList.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        final st = statusList[index];
                        final isSelected = _selectedStatus == st;
                        return FilterChip(
                          label: Text(st),
                          selected: isSelected,
                          selectedColor: const Color(0xFFDBEAFE),
                          backgroundColor: Colors.transparent,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _selectedStatus = st);
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          showCheckmark: false,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF1D4ED8)))
                  : (_error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 48),
                              const SizedBox(height: 12),
                              Text(_error!, style: const TextStyle(color: Color(0xFF475569))),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _refreshFeed,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : (filteredReports.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.people_outline_rounded, size: 64, color: Color(0xFFCBD5E1)),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No community reports yet.',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Public complaints and reports logged by residents will appear here.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton.icon(
                                      onPressed: _refreshFeed,
                                      icon: const Icon(Icons.refresh_rounded),
                                      label: const Text('Refresh Feed'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF1D4ED8),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredReports.length,
                              itemBuilder: (context, index) {
                                final report = filteredReports[index];
                                return ReportCard(
                                  report: report,
                                  currentUserId: currentUserId,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CommunityReportDetailsScreen(report: report),
                                      ),
                                    );
                                  },
                                  onUpvote: () => _handleUpvote(report),
                                );
                              },
                            ))),
            ),
          ],
        ),
      ),
    );
  }
}
