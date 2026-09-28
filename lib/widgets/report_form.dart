import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models/report.dart';
import '../models/user.dart';
import '../utils_validators.dart';

void showReportForm(BuildContext context, {String initialCategory = 'Waste Management'}) {
  final titleController = TextEditingController();
  final descController = TextEditingController();
  final contactController = TextEditingController();
  String category = initialCategory;
  bool hasMedia = false;
  bool simulatingChecks = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('New Community Report', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Provide details about the issue you want to report.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Short Title',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: Provider.of<AppState>(context, listen: false).categories.contains(category)
                  ? category
                  : Provider.of<AppState>(context, listen: false).categories.first,
              items: Provider.of<AppState>(context).categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) => category = val!,
              decoration: InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.category_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: 'Detailed Description',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            if (Provider.of<AppState>(context, listen: false).currentUser?.role == UserRole.guest) ...[
              const SizedBox(height: 16),
              TextField(
                controller: contactController,
                decoration: InputDecoration(
                  labelText: 'Optional Contact info (Email/Phone)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  helperText: 'Providing contact increases report credibility.',
                ),
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                setState(() => hasMedia = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Photo Evidence Attached (EXIF Verified)')),
                );
              },
              icon: Icon(hasMedia ? Icons.check_circle : Icons.camera_alt, color: hasMedia ? Colors.green : null),
              label: Text(hasMedia ? 'Evidence Attached' : 'Attach Photo/Video Evidence'),
            ),
            if (simulatingChecks)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 10),
                    Text('Analyzing metadata & detecting duplicates...', style: TextStyle(fontSize: 12, color: Colors.blue)),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: simulatingChecks ? null : () async {
                final appState = context.read<AppState>();
                final user = appState.currentUser!;
                
                if (user.role == UserRole.guest && !hasMedia) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mandatory: Anonymous reports must include visual proof.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (descController.text.length < 10) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Description is too short.')),
                  );
                  return;
                }

                // Validate optional contact info if provided
                final contactErr = UtilsValidators.validateOptionalContact(contactController.text);
                if (contactErr != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(contactErr), backgroundColor: Colors.red.shade700),
                  );
                  return;
                }

                setState(() => simulatingChecks = true);
                await Future.delayed(const Duration(seconds: 2));

                // Simulated Checks
                bool isDuplicate = appState.reports.any((r) => r.description == descController.text);
                bool metadataValid = true; // Simulated

                final isGuest = user.role == UserRole.guest;
                final report = Report(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: titleController.text,
                  category: category,
                  description: descController.text,
                  purok: user.purok == 'Unknown' || user.purok.isEmpty ? 'Purok 1' : user.purok,
                  timestamp: DateTime.now(),
                  reporterId: user.id,
                  complainantName: isGuest ? '' : user.name,
                  complainantPhone: isGuest ? contactController.text : user.phoneNumber,
                  complainantEmail: null,
                  isAnonymous: isGuest,
                  hasMedia: hasMedia,
                  metadataValid: metadataValid,
                  isPotentialDuplicate: isDuplicate,
                  contactInfo: isGuest ? contactController.text : user.phoneNumber,
                );
                
                final finalReport = Report(
                  id: report.id,
                  title: report.title,
                  category: report.category,
                  description: report.description,
                  purok: report.purok,
                  timestamp: report.timestamp,
                  reporterId: report.reporterId,
                  complainantName: report.complainantName,
                  complainantPhone: report.complainantPhone,
                  complainantEmail: report.complainantEmail,
                  isAnonymous: report.isAnonymous,
                  hasMedia: report.hasMedia,
                  metadataValid: report.metadataValid,
                  isPotentialDuplicate: report.isPotentialDuplicate,
                  riskScore: appState.calculateRisk(report),
                  contactInfo: report.contactInfo,
                );

                appState.addReport(finalReport);
                if (context.mounted) Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report submitted successfully!')),
                  );
                }
              },
              icon: const Icon(Icons.campaign_rounded, size: 20),
              label: const Text('Submit Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    ),
  ),
);
}
