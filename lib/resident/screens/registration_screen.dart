import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  int _currentStep = 0;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _purokController = TextEditingController();
  String? _idPath;
  String? _faceData;

  bool _isScanning = false;

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resident Registration')),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _nextStep,
        onStepCancel: _prevStep,
        controlsBuilder: (context, details) {
          if (_currentStep == 3) {
            return Padding(
              padding: const EdgeInsets.only(top: 20),
              child: ElevatedButton(
                onPressed: _submitRegistration,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('Complete Registration'),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              children: [
                ElevatedButton(onPressed: details.onStepContinue, child: const Text('Next')),
                if (_currentStep > 0)
                  TextButton(onPressed: details.onStepCancel, child: const Text('Back')),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Personal Information'),
            isActive: _currentStep >= 0,
            content: Column(
              children: [
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name')),
                TextField(controller: _purokController, decoration: const InputDecoration(labelText: 'Purok')),
                TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone Number')),
              ],
            ),
          ),
          Step(
            title: const Text('ID Verification'),
            isActive: _currentStep >= 1,
            content: Column(
              children: [
                const Text('Please upload a valid government ID or Barangay ID.'),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _idPath = 'mock_id_image.jpg');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ID Image Selected (Mock)')),
                    );
                  },
                  icon: const Icon(Icons.upload_file),
                  label: Text(_idPath == null ? 'Upload ID Photo' : 'ID Uploaded: $_idPath'),
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Face Scan'),
            isActive: _currentStep >= 2,
            content: Column(
              children: [
                const Text('Biometric verification requires a face scan.'),
                const SizedBox(height: 10),
                if (_faceData == null)
                  ElevatedButton.icon(
                    onPressed: _simulateFaceScan,
                    icon: const Icon(Icons.face),
                    label: const Text('Start Face Scan'),
                  )
                else
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 10),
                      Text('Face Scan Complete'),
                    ],
                  ),
              ],
            ),
          ),
          Step(
            title: const Text('Review & Submit'),
            isActive: _currentStep >= 3,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${_nameController.text}'),
                Text('Purok: ${_purokController.text}'),
                Text('Phone: ${_phoneController.text}'),
                const Text('ID Status: Uploaded'),
                const Text('Biometrics: Enrolled'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _simulateFaceScan() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          if (!_isScanning) {
            Future.delayed(const Duration(seconds: 1), () {
              setDialogState(() => _isScanning = true);
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted) {
                  setState(() {
                    _faceData = 'mock_face_hash_123';
                    _isScanning = false;
                  });
                  Navigator.pop(context);
                }
              });
            });
          }

          return Dialog(
            backgroundColor: Colors.black,
            child: Container(
              padding: const EdgeInsets.all(20),
              height: 400,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue, width: 4),
                    ),
                    child: const Icon(Icons.person, size: 100, color: Colors.white),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Position your face in the circle',
                    style: TextStyle(color: Colors.white),
                  ),
                  if (_isScanning) ...[
                    const SizedBox(height: 10),
                    const LinearProgressIndicator(),
                    const Text('Scanning...', style: TextStyle(color: Colors.blue)),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _submitRegistration() {
    if (_nameController.text.isEmpty || _idPath == null || _faceData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all steps including ID and Face Scan')),
      );
      return;
    }

    context.read<AppState>().registerResident(
          name: _nameController.text,
          purok: _purokController.text,
          phoneNumber: _phoneController.text,
          idPath: _idPath!,
          faceData: _faceData!,
        );
    
    Navigator.pop(context);
  }
}
