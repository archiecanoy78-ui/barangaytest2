import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/report.dart';
import '../../utils_validators.dart';
import 'dart:math';

class ComplaintForm extends StatefulWidget {
  const ComplaintForm({super.key});

  @override
  State<ComplaintForm> createState() => _ComplaintFormState();
}

class _ComplaintFormState extends State<ComplaintForm> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Step 1: Complainant Info
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  // Step 2: Incident Details
  String? _selectedCategory;
  final _locationController = TextEditingController();
  DateTime _incidentDate = DateTime.now();
  TimeOfDay _incidentTime = TimeOfDay.now();
  final _descriptionController = TextEditingController();

  bool _isSubmitting = false;

  String _generateComplaintId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final incidentDateTime = DateTime(
        _incidentDate.year,
        _incidentDate.month,
        _incidentDate.day,
        _incidentTime.hour,
        _incidentTime.minute,
      );

      final newComplaint = Report(
        id: _generateComplaintId(),
        category: _selectedCategory ?? 'Others',
        description: _descriptionController.text,
        incidentLocation: _locationController.text,
        incidentDateTime: incidentDateTime,
        complainantName: _nameController.text,
        complainantPhone: _phoneController.text,
        complainantEmail: _emailController.text.isEmpty ? null : _emailController.text,
        timestamp: DateTime.now(),
        status: ReportStatus.pending,
      );

      final appState = context.read<AppState>();
      final complaintId = await appState.submitComplaint(newComplaint);

      if (mounted) {
        _showSuccessDialog(complaintId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog(String id) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Complaint Submitted!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Your Complaint Reference Number is:'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Text(
                id,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Please save this ID to track your complaint status.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to landing page
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<AppState>().categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('File a Complaint'),
        elevation: 0,
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Stepper(
                type: StepperType.vertical,
                currentStep: _currentStep,
                onStepContinue: () {
                  if (_currentStep < 2) {
                    setState(() => _currentStep++);
                  } else {
                    _submit();
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) {
                    setState(() => _currentStep--);
                  }
                },
                steps: [
                  Step(
                    title: const Text('Personal Information'),
                    isActive: _currentStep >= 0,
                    content: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number (11 digits)',
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (v) => UtilsValidators.validatePhone(v),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email Address (Optional)',
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ],
                    ),
                  ),
                  Step(
                    title: const Text('Incident Details'),
                    isActive: _currentStep >= 1,
                    content: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(labelText: 'Complaint Category'),
                          items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => setState(() => _selectedCategory = v),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'Incident Location / Purok',
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                title: const Text('Date'),
                                subtitle: Text("${_incidentDate.toLocal()}".split(' ')[0]),
                                trailing: const Icon(Icons.calendar_today),
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _incidentDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) setState(() => _incidentDate = picked);
                                },
                              ),
                            ),
                            Expanded(
                              child: ListTile(
                                title: const Text('Time'),
                                subtitle: Text(_incidentTime.format(context)),
                                trailing: const Icon(Icons.access_time),
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: _incidentTime,
                                  );
                                  if (picked != null) setState(() => _incidentTime = picked);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Step(
                    title: const Text('Description'),
                    isActive: _currentStep >= 2,
                    content: Column(
                      children: [
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'Complaint Description',
                            hintText: 'Provide as much detail as possible...',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v?.length ?? 0) < 10 ? 'Description too short' : null,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'By submitting, you agree that the information provided is true and correct.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
