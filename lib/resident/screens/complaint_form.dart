import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/report.dart';
import '../../utils_validators.dart';

import '../../models/user.dart';

class ComplaintForm extends StatefulWidget {
  const ComplaintForm({super.key});

  @override
  State<ComplaintForm> createState() => _ComplaintFormState();
}

class _ComplaintFormState extends State<ComplaintForm> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 1;

  // Form Fields
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  String? _selectedCategory;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _purokController = TextEditingController();
  
  DateTime _incidentDate = DateTime.now();
  TimeOfDay _incidentTime = TimeOfDay.now();
  
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AppState>().currentUser;
    if (user != null && user.role != UserRole.guest) {
      _nameController.text = user.name;
      _phoneController.text = user.phoneNumber;
      _purokController.text = user.purok;
    }
  }

  void _nextStep() {
    if (_currentStep < 4) {
      if (_currentStep == 1) {
        if (_nameController.text.isEmpty || UtilsValidators.validatePhone(_phoneController.text) != null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields correctly.')));
          return;
        }
      }
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 1) setState(() => _currentStep--);
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final appState = context.read<AppState>();
    final user = appState.currentUser;
    final isGuest = user == null || user.role == UserRole.guest;
    
    final report = Report(
      id: appState.generateComplaintId(),
      title: _titleController.text,
      category: _selectedCategory ?? 'Other',
      description: _descriptionController.text,
      incidentLocation: _locationController.text,
      incidentDateTime: DateTime(_incidentDate.year, _incidentDate.month, _incidentDate.day, _incidentTime.hour, _incidentTime.minute),
      purok: _purokController.text.isNotEmpty ? _purokController.text : (user?.purok ?? 'Purok 1'),
      complainantName: _nameController.text,
      complainantPhone: _phoneController.text,
      complainantEmail: _emailController.text.isEmpty ? null : _emailController.text,
      timestamp: DateTime.now(),
      status: ReportStatus.pending,
      reporterId: user?.id,
      isAnonymous: isGuest,
      contactInfo: _phoneController.text,
    );

    try {
      final id = await appState.submitComplaint(report);
      if (mounted) _showSuccessDialog(id);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog(String id) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 24),
            const Text('Complaint Successfully Submitted', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Your Complaint ID:'),
            const SizedBox(height: 8),
            Text(id, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
            const SizedBox(height: 24),
            const Text(
              'Please save this ID. You will need it to track the status of your complaint.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
              child: const Text('Back to Home'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(title: const Text('File a Complaint'), centerTitle: true),
      body: Center(
        child: Container(
          width: 800,
          margin: const EdgeInsets.symmetric(vertical: 40),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              _buildProgressIndicator(),
              const SizedBox(height: 40),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildStepContent(),
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 1)
                    OutlinedButton(
                      onPressed: _prevStep,
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox(),
                  ElevatedButton(
                    onPressed: _currentStep == 4 ? (_isSubmitting ? null : _submit) : _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    ),
                    child: _isSubmitting 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_currentStep == 4 ? 'Submit Complaint' : 'Next'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        _stepCircle(1, 'Details'),
        _stepLine(1),
        _stepCircle(2, 'Description'),
        _stepLine(2),
        _stepCircle(3, 'Evidence'),
        _stepLine(3),
        _stepCircle(4, 'Review'),
      ],
    );
  }

  Widget _stepCircle(int step, String label) {
    bool isCompleted = _currentStep > step;
    bool isActive = _currentStep == step;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted || isActive ? const Color(0xFF2563EB) : Colors.white,
            border: Border.all(color: const Color(0xFF2563EB)),
          ),
          child: Center(
            child: isCompleted 
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Text('$step', style: TextStyle(color: isActive ? Colors.white : const Color(0xFF2563EB), fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _stepLine(int step) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: _currentStep > step ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1: return _step1Details();
      case 2: return _step2Description();
      case 3: return _step3Evidence();
      case 4: return _step4Review();
      default: return const SizedBox();
    }
  }

  Widget _step1Details() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        _textField('Full Name', _nameController, hint: 'John Doe'),
        const SizedBox(height: 20),
        _textField('Phone Number', _phoneController, hint: '09xxxxxxxxx', keyboard: TextInputType.phone),
        const SizedBox(height: 20),
        _textField('Email (Optional)', _emailController, hint: 'you@example.com', keyboard: TextInputType.emailAddress),
      ],
    );
  }

  Widget _step2Description() {
    final categories = context.watch<AppState>().categories;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Incident Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Complaint Category', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                    decoration: const InputDecoration(hintText: 'Select category'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(child: _textField('Location', _locationController, hint: 'Barangay, Purok / Exact location')),
          ],
        ),
        const SizedBox(height: 20),
        _textField('Complaint Title', _titleController, hint: 'Brief title of the issue'),
        const SizedBox(height: 20),
        _textField('Description', _descriptionController, hint: 'Describe the issue in detail...', lines: 4),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Date of Incident', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(context: context, initialDate: _incidentDate, firstDate: DateTime(2020), lastDate: DateTime.now());
                      if (picked != null) setState(() => _incidentDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 10),
                          Text("${_incidentDate.toLocal()}".split(' ')[0]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(child: _textField('Purok / Zone', _purokController, hint: 'Purok 1, Zone A')),
          ],
        ),
      ],
    );
  }

  Widget _step3Evidence() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Attach Evidence (Optional)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            children: [
              Icon(Icons.cloud_upload_outlined, size: 48, color: Color(0xFF64748B)),
              SizedBox(height: 16),
              Text('Click to upload or drag and drop', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('JPG, PNG, MP4 (Max 10MB)', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _step4Review() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Review Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        _reviewRow('Name', _nameController.text),
        _reviewRow('Phone', _phoneController.text),
        _reviewRow('Category', _selectedCategory ?? 'Other'),
        _reviewRow('Title', _titleController.text),
        _reviewRow('Location', _locationController.text),
        _reviewRow('Date', "${_incidentDate.toLocal()}".split(' ')[0]),
        const SizedBox(height: 20),
        const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(_descriptionController.text),
      ],
    );
  }

  Widget _textField(String label, TextEditingController controller, {String? hint, int lines = 1, TextInputType keyboard = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: lines,
          keyboardType: keyboard,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
