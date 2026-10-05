import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/report.dart';

class TrackComplaint extends StatefulWidget {
  const TrackComplaint({super.key});

  @override
  State<TrackComplaint> createState() => _TrackComplaintState();
}

class _TrackComplaintState extends State<TrackComplaint> {
  final _idController = TextEditingController();
  Report? _complaint;
  bool _hasSearched = false;

  void _search() {
    if (_idController.text.isEmpty) return;
    setState(() {
      _complaint = context.read<AppState>().getReportById(_idController.text.trim());
      _hasSearched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Track Complaint', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Center(
          child: SizedBox(
            width: 800,
            child: Column(
              children: [
                const Text(
                  'Track your complaint status',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -1),
                ),
                const SizedBox(height: 12),
                const Text('Enter your unique reference ID below to see real-time updates.', style: TextStyle(color: Color(0xFF64748B))),
                const SizedBox(height: 48),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _idController,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: 'e.g. BR-2026-001248',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        onSubmitted: (_) => _search(),
                      ),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: _search,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 28),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Search', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 60),
                if (_hasSearched)
                  _complaint == null 
                    ? _buildNotFound()
                    : _buildComplaintStatus(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotFound() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626)),
          SizedBox(width: 16),
          Text('No complaint found with that reference ID. Please check and try again.', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildComplaintStatus() {
    final status = _complaint!.status;
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 40, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_complaint!.id, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text(_complaint!.category, style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500, fontSize: 16)),
                ],
              ),
              _statusBadge(status),
            ],
          ),
          const SizedBox(height: 60),
          const Text('Status Timeline', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 40),
          _buildTimeline(),
        ],
      ),
    );
  }

  Widget _statusBadge(ReportStatus status) {
    Color color = const Color(0xFFF59E0B);
    if (status == ReportStatus.resolved) color = const Color(0xFF10B981);
    if (status == ReportStatus.rejected) color = const Color(0xFFEF4444);
    if (status == ReportStatus.under_investigation) color = const Color(0xFF2563EB);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildTimeline() {
    return Column(
      children: [
        _timelineItem('Submitted', 'Complaint successfully filed (Guest)', _isCompleted(ReportStatus.pending), true),
        _timelineItem('Received by Barangay', 'Admin reviewed and logged submission', _isCompleted(ReportStatus.under_investigation), true),
        _timelineItem('Under Investigation', 'Assigned to Barangay Response Team', _isCompleted(ReportStatus.under_investigation), true),
        _timelineItem('Resolved', 'Issue addressed and record finalized', _isCompleted(ReportStatus.resolved), false),
      ],
    );
  }

  bool _isCompleted(ReportStatus step) {
    final order = ReportStatus.values.indexOf(_complaint!.status);
    final stepOrder = ReportStatus.values.indexOf(step);
    return order >= stepOrder;
  }

  Widget _timelineItem(String title, String subtitle, bool isDone, bool hasNext) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? const Color(0xFF2563EB) : Colors.white,
                border: Border.all(color: isDone ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0), width: 3),
                boxShadow: isDone ? [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.3), blurRadius: 10)] : null,
              ),
              child: isDone ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
            ),
            if (hasNext)
              Container(
                width: 2,
                height: 60,
                color: isDone ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
              ),
          ],
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: isDone ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: isDone ? const Color(0xFF64748B) : const Color(0xFFCBD5E1),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }
}
