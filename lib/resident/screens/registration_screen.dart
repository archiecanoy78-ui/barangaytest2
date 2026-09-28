import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../utils_validators.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  int _currentStep = 0;
  
  // Input Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedPurok;
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  String? _idPath;
  String? _faceData;
  bool _isScanning = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Password Complexity Checker Rules
  bool get _hasMinMaxLen => _passwordController.text.length >= 8 && _passwordController.text.length <= 12;
  bool get _hasUppercase => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasLowercase => _passwordController.text.contains(RegExp(r'[a-z]'));
  bool get _hasDigits => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecialChar => _passwordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/]'));

  bool get _isPasswordValid => _hasMinMaxLen && _hasUppercase && _hasLowercase && _hasDigits && _hasSpecialChar;

  bool get _isStep0Valid =>
      UtilsValidators.validateName(_firstNameController.text) == null &&
      UtilsValidators.validateName(_lastNameController.text) == null &&
      UtilsValidators.validateUsername(_usernameController.text) == null &&
      _selectedPurok != null &&
      UtilsValidators.validatePhone(_phoneController.text.trim()) == null &&
      _isPasswordValid;

  void _nextStep() {
    if (_currentStep == 0 && !_isStep0Valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields and fulfill all password criteria.')),
      );
      return;
    }
    if (_currentStep == 2 && _faceData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric Face Scan is mandatory to continue.')),
      );
      return;
    }
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Modern Step Indicators
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Row(
                children: [
                  _buildStepIndicator(0, 'Info'),
                  _buildStepDivider(0),
                  _buildStepIndicator(1, 'ID (Optional)'),
                  _buildStepDivider(1),
                  _buildStepIndicator(2, 'Scan'),
                  _buildStepDivider(2),
                  _buildStepIndicator(3, 'Review'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Step Content Box
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                  ),
                  child: _buildCurrentStepContent(),
                ),
              ),
            ),

            // Footer Navigation Buttons
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: Row(
                children: [
                  if (_currentStep > 0) ...[
                    OutlinedButton(
                      onPressed: _prevStep,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF475569),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Back'),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _currentStep == 3 ? _submitRegistration : _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(_currentStep == 3 ? 'Complete Registration' : 'Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int index, String label) {
    final bool isDone = _currentStep > index;
    final bool isActive = _currentStep == index;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: isDone
              ? const Color(0xFFE6F4EA)
              : (isActive ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9)),
          child: isDone
              ? const Icon(Icons.check, color: Color(0xFF137333), size: 14)
              : Text(
                  (index + 1).toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : const Color(0xFF94A3B8),
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider(int index) {
    final bool isPassed = _currentStep > index;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Divider(
          color: isPassed ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          thickness: 2,
          indent: 8,
          endIndent: 8,
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep0Info();
      case 1:
        return _buildStep1ID();
      case 2:
        return _buildStep2Face();
      case 3:
        return _buildStep3Review();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep0Info() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
        const SizedBox(height: 4),
        const Text('Please fill out your identity details to initialize verification.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        const SizedBox(height: 20),
        
        Row(
          children: [
            Expanded(child: _buildInputField(_firstNameController, 'First Name', Icons.person_outline)),
            const SizedBox(width: 12),
            Expanded(child: _buildInputField(_lastNameController, 'Last Name', Icons.person_outline)),
          ],
        ),
        const SizedBox(height: 12),
        _buildInputField(_usernameController, 'Username', Icons.alternate_email_rounded),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              value: _selectedPurok,
              hint: const Text('Select Purok / Area', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.location_on_outlined, color: Color(0xFF94A3B8), size: 18),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              items: ['Purok 1', 'Purok 2', 'Purok 3', 'Purok 4', 'Purok 5', 'Purok 6']
                  .map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 14))))
                  .toList(),
              onChanged: (val) => setState(() => _selectedPurok = val),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildInputField(_phoneController, 'Phone Number', Icons.phone_android_outlined, keyboardType: TextInputType.phone),
        Builder(builder: (_) {
          final err = UtilsValidators.validatePhone(_phoneController.text.trim());
          return err == null || _phoneController.text.trim().isEmpty
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(err, style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
                );
        }),
        const SizedBox(height: 12),
        
        // Password Input
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: 'Account Password',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              prefixIcon: const Icon(Icons.lock_open_rounded, color: Color(0xFF94A3B8), size: 18),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF94A3B8), size: 18),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        const Text('Password Requirements Check:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
        const SizedBox(height: 8),
        _buildCriteriaRow('8 to 12 characters length', _hasMinMaxLen),
        _buildCriteriaRow('Contains uppercase letter (A-Z)', _hasUppercase),
        _buildCriteriaRow('Contains lowercase letter (a-z)', _hasLowercase),
        _buildCriteriaRow('Contains number digit (0-9)', _hasDigits),
        _buildCriteriaRow(r'Contains special symbol (e.g. !, @, #, $, %)', _hasSpecialChar),
      ],
    );
  }

  Widget _buildCriteriaRow(String label, bool isValid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(isValid ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isValid ? const Color(0xFF10B981) : const Color(0xFF94A3B8), size: 14),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 11, color: isValid ? const Color(0xFF1E293B) : const Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildInputField(TextEditingController ctrl, String hint, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildStep1ID() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('ID Verification', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            Chip(
              label: Text('OPTIONAL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
              backgroundColor: Color(0xFFF1F5F9),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text('You can upload a government ID to achieve instant auto-verification, or skip this step to verify manually later.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        const SizedBox(height: 30),
        
        Center(
          child: GestureDetector(
            onTap: () {
              setState(() => _idPath = 'mock_id_card_img.jpg');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ID Image attached successfully.')),
              );
            },
            child: Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _idPath != null ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1), width: 1.5, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_idPath != null ? Icons.file_present_rounded : Icons.cloud_upload_outlined,
                      color: _idPath != null ? const Color(0xFF2563EB) : const Color(0xFF94A3B8), size: 36),
                  const SizedBox(height: 10),
                  Text(
                    _idPath != null ? '✓ ID Attached: $_idPath' : 'Tap to upload Government/Barangay ID',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _idPath != null ? const Color(0xFF2563EB) : const Color(0xFF475569)),
                  ),
                  if (_idPath == null) ...[
                    const SizedBox(height: 2),
                    const Text('Supports JPG, PNG formats', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  ]
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2Face() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Biometric Face Scan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
            Chip(
              label: Text('MANDATORY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
              backgroundColor: Color(0xFFDC2626),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Mandatory face scan authentication secures your residency profile records against fraud.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        const SizedBox(height: 30),
        
        Center(
          child: Column(
            children: [
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF8FAFC),
                  border: Border.all(color: _faceData != null ? const Color(0xFF10B981) : const Color(0xFFE2E8F0), width: 2),
                ),
                child: Icon(
                  _faceData != null ? Icons.face_retouching_natural_rounded : Icons.face_rounded,
                  size: 60,
                  color: _faceData != null ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 24),
              if (_faceData == null)
                OutlinedButton.icon(
                  onPressed: _simulateFaceScan,
                  icon: const Icon(Icons.document_scanner_rounded, size: 16),
                  label: const Text('Initialize Biometric Scan', style: TextStyle(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    side: const BorderSide(color: Color(0xFF2563EB)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )
              else
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                    SizedBox(width: 8),
                    Text('Face Scan Recorded Successfully', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF137333), fontSize: 13)),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3Review() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Review Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
        const SizedBox(height: 4),
        const Text('Confirm your particulars match valid government documents before submitting.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        const SizedBox(height: 20),
        
        _buildReviewRow('First Name', _firstNameController.text.trim()),
        _buildReviewRow('Last Name', _lastNameController.text.trim()),
        _buildReviewRow('Purok Location', _selectedPurok ?? 'Not Selected'),
        _buildReviewRow('Phone Number', _phoneController.text.trim()),
        _buildReviewRow('ID Upload', _idPath != null ? 'Provided ($_idPath)' : 'Skipped (Optional)'),
        _buildReviewRow('Biometrics', _faceData != null ? 'Enrolled (Mandatory)' : 'Missing', valueColor: _faceData != null ? const Color(0xFF137333) : const Color(0xFFDC2626)),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value, {Color valueColor = const Color(0xFF1E293B)}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor)),
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
            Future.delayed(const Duration(milliseconds: 500), () {
              setDialogState(() => _isScanning = true);
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) {
                  setState(() {
                    _faceData = 'mock_face_biometrics_hash_9982';
                    _isScanning = false;
                  });
                  Navigator.pop(context);
                }
              });
            });
          }

          return Dialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              padding: const EdgeInsets.all(24),
              height: 380,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF3B82F6), width: 3),
                    ),
                    child: const Icon(Icons.face_retouching_natural, size: 80, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Align face inside the frame indicator',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (_isScanning) ...[
                    const SizedBox(
                      width: 120,
                      child: LinearProgressIndicator(
                        backgroundColor: Color(0xFF334155),
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Scanning biometrics...', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 12, fontWeight: FontWeight.w500)),
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
    if (!_isStep0Valid || _faceData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration invalid. Fulfill all mandatory data and face scan constraints.')),
      );
      return;
    }

    final String mergedFullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';

    context.read<AppState>().registerResident(
          name: mergedFullName,
          username: _usernameController.text.trim(),
          purok: _selectedPurok!,
          phoneNumber: _phoneController.text.trim(),
          idPath: _idPath ?? 'no_id_provided',
          faceData: _faceData!,
          password: _passwordController.text,
        );
    
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Residency registration completed successfully!')),
    );
  }
}
