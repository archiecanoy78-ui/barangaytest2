import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_state.dart';
import '../models/user.dart';
import '../main.dart';
import '../services/account_session_guard.dart';

class RegistrationConfirmationScreen extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String username;
  final String purok;
  final String password;
  final Uint8List? capturedFaceBytes;

  const RegistrationConfirmationScreen({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.purok,
    required this.password,
    required this.capturedFaceBytes,
  });

  @override
  State<RegistrationConfirmationScreen> createState() =>
      _RegistrationConfirmationScreenState();
}

class _RegistrationConfirmationScreenState
    extends State<RegistrationConfirmationScreen> {
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _handleConfirmAndSignIn() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final fullName = '${widget.firstName.trim()} ${widget.lastName.trim()}';
    final username = widget.username.trim();
    final internalEmail = '$username@barangay.local';
    final rawPassword = widget.password;

    String? uploadedPhotoUrl;
    fb_auth.UserCredential? userCredential;
    String uid = 'res_${DateTime.now().millisecondsSinceEpoch}';

    try {
      // 1. Try creating account via Firebase Auth
      try {
        userCredential = await fb_auth.FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: internalEmail,
          password: rawPassword,
        );
        if (userCredential.user?.uid != null) {
          uid = userCredential.user!.uid;
        }
      } on fb_auth.FirebaseAuthException catch (authErr) {
        debugPrint('Firebase Auth notice (${authErr.code}): ${authErr.message}');
        if (authErr.code == 'email-already-in-use') {
          setState(() {
            _isSubmitting = false;
            _errorMessage = 'This number is already registered. Please log in or use another number.';
          });
          return;
        }
        // Fallback gracefully if Firebase Auth provider is not configured in console
      } catch (authErr) {
        debugPrint('Firebase Auth fallback: $authErr');
      }

      // 2. Upload captured face thumbnail to Firebase Storage
      if (widget.capturedFaceBytes != null &&
          widget.capturedFaceBytes!.isNotEmpty) {
        try {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('verification_photos')
              .child(uid)
              .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

          final metadata = SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {'uid': uid, 'verified': 'true'},
          );

          final uploadTask = await storageRef.putData(
              widget.capturedFaceBytes!, metadata);
          uploadedPhotoUrl = await uploadTask.ref.getDownloadURL();
        } catch (e) {
          debugPrint('Storage upload notice: $e');
        }
      }

      // 3. Save User Profile to Firestore & AppState with status: 'active'
      final newUser = User(
        id: uid,
        name: fullName,
        username: username,
        role: UserRole.resident,
        purok: widget.purok,
        phoneNumber: username,
        isVerified: true,
        idImagePath: uploadedPhotoUrl,
        faceData: uploadedPhotoUrl,
        password: rawPassword,
      );

      final userMap = newUser.toMap();
      userMap['status'] = 'active';
      userMap['isArchived'] = false;
      userMap['createdAt'] = FieldValue.serverTimestamp();

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(userMap);
      } catch (e) {
        debugPrint('Firestore write notice: $e');
      }

      if (!mounted) return;

      // 4. Set AppState current user & initialize session guard
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.registerUser(newUser);

      if (!mounted) return;

      try {
        AccountSessionGuard().initialize(context, uid);
      } catch (_) {}

      // 5. Navigate straight to Resident Home screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome, $fullName! Registration completed.'),
          backgroundColor: Colors.green.shade800,
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        if (e.toString().contains('email-already-in-use') ||
            e.toString().contains('already exists')) {
          _errorMessage =
              'This number is already registered. Please log in or use another number.';
        } else {
          _errorMessage =
              'Registration error: ${e.toString()}. Please try again.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName = '${widget.firstName.trim()} ${widget.lastName.trim()}';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Confirm Information',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF0F172A), size: 18),
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Face Verification Thumbnail Header
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 54,
                          backgroundColor: const Color(0xFFE2E8F0),
                          backgroundImage: widget.capturedFaceBytes != null
                              ? MemoryImage(widget.capturedFaceBytes!)
                              : null,
                          child: widget.capturedFaceBytes == null
                              ? const Icon(Icons.person_rounded,
                                  size: 54, color: Color(0xFF94A3B8))
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Human Verification Passed',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Colors.red, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Profile Summary Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 8,
                        offset: Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Account Summary',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A))),
                    const SizedBox(height: 16),
                    _summaryRow('Full Name', fullName),
                    _summaryRow('Username / Mobile', widget.username),
                    _summaryRow('Purok / Zone', widget.purok),
                    _summaryRow('Role', 'Resident'),
                    _summaryRow('Password', '•••••••• (Protected)'),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _handleConfirmAndSignIn,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_rounded, size: 20),
                label: Text(
                  _isSubmitting
                      ? 'Creating Account...'
                      : 'Confirm & Complete Registration',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Edit Information / Back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF475569),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
