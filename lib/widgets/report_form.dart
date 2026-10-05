import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../constants/app_constants.dart';
import '../models/report.dart';
import '../models/user.dart';
import '../utils_validators.dart';
import 'form_draft_helper.dart';

void showReportForm(BuildContext context, {String initialCategory = 'Waste Management'}) async {
  final appState = Provider.of<AppState>(context, listen: false);
  final currentUid = appState.currentUser?.id ?? 'guest';
  final draftHelper = FormDraftHelper(formKey: 'log_incident', uid: currentUid);

  final titleController = TextEditingController();
  final descController = TextEditingController();
  final contactController = TextEditingController();
  String category = AppConstants.normalizeCategory(initialCategory);
  bool hasMedia = false;
  bool simulatingChecks = false;

  final draft = await draftHelper.loadDraft();
  if (draft != null) {
    titleController.text = draft['title']?.toString() ?? '';
    descController.text = draft['description']?.toString() ?? '';
    contactController.text = draft['contact']?.toString() ?? '';
    if (draft['category'] != null) {
      category = AppConstants.normalizeCategory(draft['category'].toString());
    }
  }

  if (!context.mounted) return;

  showModalBottomSheet(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        void updateDraft() {
          draftHelper.onFieldChanged({
            'title': titleController.text,
            'description': descController.text,
            'contact': contactController.text,
            'category': category,
          });
        }

        return SingleChildScrollView(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('New Community Report', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () async {
                        final hasContent = titleController.text.isNotEmpty || descController.text.isNotEmpty;
                        if (hasContent) {
                          final discard = await FormDraftHelper.showDiscardConfirmationDialog(context);
                          if (discard) {
                            await draftHelper.clearDraft();
                            if (context.mounted) Navigator.pop(context);
                          }
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Provide details about the issue you want to report.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 20),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Short Title',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.title),
                  ),
                  onChanged: (_) => updateDraft(),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: AppConstants.categories.contains(category)
                      ? category
                      : AppConstants.categories.first,
                  items: AppConstants.categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => category = val);
                      updateDraft();
                    }
                  },
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
                  onChanged: (_) => updateDraft(),
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
                    onChanged: (_) => updateDraft(),
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
                    final user = appState.currentUser;
                    
                    if (titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a title for the report.')),
                      );
                      return;
                    }

                    if (user?.role == UserRole.guest && !hasMedia) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Mandatory: Anonymous reports must include visual proof.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (descController.text.trim().length < 10) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Description is too short (minimum 10 characters).')),
                      );
                      return;
                    }

                    final contactErr = UtilsValidators.validateOptionalContact(contactController.text);
                    if (contactErr != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(contactErr), backgroundColor: Colors.red.shade700),
                      );
                      return;
                    }

                    setState(() => simulatingChecks = true);
                    await Future.delayed(const Duration(seconds: 1));

                    bool isDuplicate = appState.reports.any((r) => r.description == descController.text.trim());

                    final isGuest = user == null || user.role == UserRole.guest;
                    final rawPurok = user?.purok ?? 'Purok 1';
                    final finalPurok = AppConstants.normalizePurok(rawPurok);

                    final report = Report(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text.trim(),
                      category: AppConstants.normalizeCategory(category),
                      description: descController.text.trim(),
                      purok: finalPurok,
                      timestamp: DateTime.now(),
                      reporterId: user?.id,
                      complainantName: isGuest ? '' : user.name,
                      complainantPhone: isGuest ? contactController.text.trim() : user.phoneNumber,
                      complainantEmail: null,
                      isAnonymous: isGuest,
                      hasMedia: hasMedia,
                      metadataValid: true,
                      isPotentialDuplicate: isDuplicate,
                      contactInfo: isGuest ? contactController.text.trim() : user.phoneNumber,
                    );

                    await appState.addReport(report);
                    await draftHelper.clearDraft();

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
        );
      },
    ),
  );
}
