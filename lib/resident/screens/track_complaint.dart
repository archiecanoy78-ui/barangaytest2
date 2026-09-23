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
  final _searchController = TextEditingController();
  Report? _foundComplaint;
  bool _hasSearched = false;

  void _search() {
    final id = _searchController.text.trim().toUpperCase();
    if (id.isEmpty) return;

    final appState = context.read<AppState>();
    setState(() {
      _foundComplaint = appState.getReportById(id);
      _hasSearched = true;
    });
  }

  Color _getStatusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending: return Colors.orange;
      case ReportStatus.underReview: return Colors.blue;
      case ReportStatus.underInvestigation: return Colors.indigo;
      case ReportStatus.actionRequired: return Colors.red;
      case ReportStatus.resolved: return Colors.green;
      case ReportStatus.rejected: return Colors.grey;
      case ReportStatus.closed: return Colors.black54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Track Complaint')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Enter Complaint ID',
                hintText: 'e.g., A1B2C3D4',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _search,
                ),
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 30),
            if (_hasSearched)
              Expanded(
                child: _foundComplaint == null
                    ? const Center(child: Text('No complaint found with that ID.'))
                    : SingleChildScrollView(
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'ID: ${_foundComplaint!.id}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(_foundComplaint!.status).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: _getStatusColor(_foundComplaint!.status)),
                                      ),
                                      child: Text(
                                        _foundComplaint!.status.name.toUpperCase(),
                                        style: TextStyle(
                                          color: _getStatusColor(_foundComplaint!.status),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 30),
                                _buildInfoRow('Category', _foundComplaint!.category),
                                _buildInfoRow('Submitted', _foundComplaint!.timestamp.toString().split('.')[0]),
                                _buildInfoRow('Location', _foundComplaint!.incidentLocation),
                                const SizedBox(height: 20),
                                const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 5),
                                Text(_foundComplaint!.description),
                                const SizedBox(height: 20),
                                if (_foundComplaint!.investigationNotes != null) ...[
                                  const Text('Admin/Staff Notes:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                  const SizedBox(height: 5),
                                  Text(_foundComplaint!.investigationNotes!),
                                  const SizedBox(height: 20),
                                ],
                                if (_foundComplaint!.actionTaken != null) ...[
                                  const Text('Action Taken:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                  const SizedBox(height: 5),
                                  Text(_foundComplaint!.actionTaken!),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text('$label:', style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
