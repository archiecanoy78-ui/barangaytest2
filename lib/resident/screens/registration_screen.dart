import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/user.dart';
import '../../validators.dart';
import '../../screens/camera_liveness_screen.dart';
import '../../screens/registration_confirmation_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Field Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedPurok;

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _firstNameController.addListener(_onFormFieldChanged);
    _lastNameController.addListener(_onFormFieldChanged);
    _usernameController.addListener(_onFormFieldChanged);
    _phoneController.addListener(_onFormFieldChanged);
    _passwordController.addListener(_onFormFieldChanged);
  }

  void _onFormFieldChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Password Rules Checkers
  bool get _hasMinMaxLen => _passwordController.text.length >= 8 && _passwordController.text.length <= 12;
  bool get _hasUppercase => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasLowercase => _passwordController.text.contains(RegExp(r'[a-z]'));
  bool get _hasDigits => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecialChar => _passwordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/]'));

  bool get _isPasswordValid => _hasMinMaxLen && _hasUppercase && _hasLowercase && _hasDigits && _hasSpecialChar;

  bool get _isFormValid =>
      Validators.validateFirstName(_firstNameController.text) == null &&
      Validators.validateLastName(_lastNameController.text) == null &&
      Validators.validateUsername(_usernameController.text) == null &&
      Validators.validatePhone(_phoneController.text) == null &&
      _selectedPurok != null &&
      _isPasswordValid;

  void _navigateToCameraVerification() {
    if (!_isFormValid) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CameraLivenessScreen(
          onSuccessWithPhoto: (photoBytes) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => RegistrationConfirmationScreen(
                  firstName: _firstNameController.text,
                  lastName: _lastNameController.text,
                  username: _usernameController.text,
                  purok: _selectedPurok ?? 'Purok 1',
                  password: _passwordController.text,
                  capturedFaceBytes: photoBytes,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _completeRegistration() async {
    final appState = Provider.of<AppState>(context, listen: false);

    final fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
    final newUser = User(
      id: 'res_${DateTime.now().millisecondsSinceEpoch}',
      name: fullName,
      username: _usernameController.text.trim(),
      role: UserRole.resident,
      purok: _selectedPurok ?? 'Purok 1',
      phoneNumber: _phoneController.text.trim(),
      password: _passwordController.text,
      isVerified: true, // Human Liveness Verified!
    );

    await appState.registerUser(newUser);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text('Account Created!'),
          ],
        ),
        content: Text(
          'Welcome, $fullName! Your human liveness verification was successful and your account is now active.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Close Dialog
              Navigator.pop(context); // Return to main / login
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            child: const Text('Go to Home', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Resident Registration', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF0F172A))),
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Personal Credentials', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        const SizedBox(height: 4),
                        const Text('Fill out all fields below to prepare for human camera verification.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        const SizedBox(height: 24),

                        // First Name
                        TextFormField(
                          controller: _firstNameController,
                          maxLength: 100,
                          decoration: _buildInputDecoration('First Name', Icons.person_outline_rounded),
                          validator: (v) => Validators.validateFirstName(v ?? ''),
                        ),
                        const SizedBox(height: 12),

                        // Last Name
                        TextFormField(
                          controller: _lastNameController,
                          maxLength: 100,
                          decoration: _buildInputDecoration('Last Name', Icons.person_outline_rounded),
                          validator: (v) => Validators.validateLastName(v ?? ''),
                        ),
                        const SizedBox(height: 12),

                        // Username
                        TextFormField(
                          controller: _usernameController,
                          maxLength: 50,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(50),
                            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_\.]')),
                          ],
                          decoration: _buildInputDecoration('Username', Icons.alternate_email_rounded),
                          validator: (v) => Validators.validateUsername(v ?? ''),
                        ),
                        const SizedBox(height: 12),

                        // Phone Number
                        TextFormField(
                          controller: _phoneController,
                          maxLength: 11,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                          decoration: _buildInputDecoration('Phone Number (e.g. 09123456789)', Icons.phone_android_rounded),
                          validator: (v) => Validators.validatePhone(v ?? ''),
                        ),
                        const SizedBox(height: 12),

                        // Purok Dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedPurok,
                          hint: const Text('Select Purok / Area', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
                          decoration: _buildInputDecoration('Purok / Area', Icons.location_on_outlined),
                          items: ['Purok 1', 'Purok 2', 'Purok 3', 'Purok 4', 'Purok 5', 'Purok 6']
                              .map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 14))))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedPurok = val),
                          validator: (v) => v == null ? 'Please select a Purok' : null,
                        ),
                        const SizedBox(height: 16),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: _buildInputDecoration('Password', Icons.lock_outline_rounded).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) => Validators.validatePassword(v ?? ''),
                        ),
                        const SizedBox(height: 12),

                        // Password criteria feedback list
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildRuleItem('8-12 characters long', _hasMinMaxLen),
                              _buildRuleItem('At least one uppercase letter (A-Z)', _hasUppercase),
                              _buildRuleItem('At least one lowercase letter (a-z)', _hasLowercase),
                              _buildRuleItem('At least one digit (0-9)', _hasDigits),
                              _buildRuleItem('At least one special character (!@#\$%^&*)', _hasSpecialChar),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Continue Button (Disabled until _isFormValid)
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isFormValid ? _navigateToCameraVerification : null,
                  icon: const Icon(Icons.verified_user_rounded, size: 20),
                  label: const Text('Continue to Camera Verification', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    disabledBackgroundColor: const Color(0xFFCBD5E1),
                    disabledForegroundColor: Colors.white,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF64748B)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildRuleItem(String label, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 14,
            color: isMet ? Colors.green : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isMet ? const Color(0xFF15803D) : const Color(0xFF64748B),
              fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
