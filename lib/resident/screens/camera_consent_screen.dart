import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../../app_state.dart';
import '../../models/camera_consent.dart';
import '../../screens/camera_liveness_screen.dart';

class CameraConsentScreen extends StatefulWidget {
  final String userId;
  final ValueChanged<Uint8List?> onSuccessWithPhoto;

  const CameraConsentScreen({
    super.key,
    required this.userId,
    required this.onSuccessWithPhoto,
  });

  @override
  State<CameraConsentScreen> createState() => _CameraConsentScreenState();
}

class _CameraConsentScreenState extends State<CameraConsentScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;
  bool _isChecked = false;
  bool _isSavingConsent = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - 30) {
      if (!_hasScrolledToBottom) {
        setState(() {
          _hasScrolledToBottom = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _showDeclineInfoDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 24),
            SizedBox(width: 8),
            Text('Camera Consent Declined', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: const Text(
          'Without camera verification, automated online resident registration cannot be completed.\n\nAlternative Option:\nYou may complete your resident registration in person by visiting the Barangay Hall with a valid government ID. An administrative officer will assist you.',
          style: TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            child: const Text('Return to Registration', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Privacy Policy & Terms', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(),
            const Expanded(
              child: SingleChildScrollView(
                child: Text(
                  'Full Barangay Data Privacy Policy\n\nIn compliance with the Data Privacy Act of 2012 (Republic Act No. 10173), all personal data collected during registration and report filing are handled with strict confidentiality. Data is encrypted and accessible only by authorized personnel for official barangay administration.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleConsentAccepted() async {
    setState(() => _isSavingConsent = true);

    final appState = context.read<AppState>();
    final consentRecord = CameraConsent(
      id: 'consent_${DateTime.now().millisecondsSinceEpoch}',
      userId: widget.userId,
      agreementVersion: 'v1.0',
      timestamp: DateTime.now(),
      appVersion: '1.0.0',
      consentTextHash: 'v1.0-data-privacy-act-2012',
      agreed: true,
    );

    await appState.recordCameraConsent(consentRecord);

    if (!mounted) return;
    setState(() => _isSavingConsent = false);

    if (kIsWeb) {
      _navigateToCamera();
      return;
    }

    final status = await Permission.camera.request();
    if (status.isGranted) {
      _navigateToCamera();
    } else if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog(isPermanent: true);
    } else {
      _showPermissionDeniedDialog(isPermanent: false);
    }
  }

  void _navigateToCamera() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CameraLivenessScreen(
          onSuccessWithPhoto: widget.onSuccessWithPhoto,
        ),
      ),
    );
  }

  void _showPermissionDeniedDialog({required bool isPermanent}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: Text(
          isPermanent
              ? 'Camera permission is permanently denied. Please open your device settings to enable camera access for registration.'
              : 'Camera permission is required to perform human liveness identity verification.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (isPermanent) {
                await openAppSettings();
              } else {
                _handleConsentAccepted();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            child: Text(isPermanent ? 'Open Settings' : 'Retry Permission', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canAgree = _hasScrolledToBottom && _isChecked && !_isSavingConsent;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Camera Use Agreement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0F172A))),
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
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(12)),
                    child: const Text('Step 2 of 3', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Consent & Identity Verification',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.shield_outlined, color: Color(0xFF1D4ED8), size: 28),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Please read the complete agreement below before proceeding to camera verification.',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E40AF), height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSection(
                      '1. Why We Need the Camera',
                      'We require temporary access to your device camera to conduct human liveness verification and identity authentication. This ensures that every resident account belongs to a real, unique individual and prevents fraudulent or automated registrations.',
                    ),
                    _buildSection(
                      '2. What We Capture',
                      'During verification, the application captures:\n• Live facial liveness video frames (head movements, blinking)\n• A single verified facial snapshot photo\n• Photos of your government-issued ID (if applicable)',
                    ),
                    _buildSection(
                      '3. How Images Are Used',
                      'Captured images are used strictly for:\n• Verifying your barangay residency and identity\n• Authenticating incident reports filed under your account by authorized barangay officials only',
                    ),
                    _buildSection(
                      '4. Storage and Security Protections',
                      'All images and face descriptors are stored securely using industry-standard AES-256 encryption at rest. Access is strictly restricted to authorized barangay personnel via role-based access controls. Data is retained for 1 year or until account termination.',
                    ),
                    _buildSection(
                      '5. Who Can See Your Information',
                      'Your captured identity images are accessible strictly to authorized Barangay Staff and Administrators. We do not sell, rent, or share your data with third parties, except as explicitly mandated by Philippine law enforcement or court order.',
                    ),
                    _buildSection(
                      '6. Your Rights Under the Data Privacy Act (RA 10173)',
                      'Under Republic Act No. 10173 (Data Privacy Act of 2012), you have the right to:\n• Request access to or correction of your personal data\n• Withdraw your consent at any time\n• Request deletion of your image records subject to legal retention guidelines',
                    ),
                    _buildSection(
                      '7. What Happens If You Decline',
                      'If you choose not to consent to camera access, online registration cannot be completed automatically. However, you may visit the Barangay Hall in person with a valid ID to complete manual registration with an administrative officer.',
                    ),
                    _buildSection(
                      '8. Data Protection Officer (DPO) Contact',
                      'For privacy inquiries or to exercise your privacy rights, contact our Data Protection Desk at:\nEmail: dpo@barangay.gov.ph\nOffice: Barangay Privacy & Information Desk',
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton.icon(
                        onPressed: _showPrivacyPolicyModal,
                        icon: const Icon(Icons.policy_outlined, size: 16),
                        label: const Text('View Full Privacy Policy & Terms of Use', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (!_hasScrolledToBottom)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.arrow_downward_rounded, size: 16, color: Color(0xFFD97706)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Scroll to the bottom of the text to enable the agreement checkbox.',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: _hasScrolledToBottom
                        ? () => setState(() => _isChecked = !_isChecked)
                        : null,
                    borderRadius: BorderRadius.circular(10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _isChecked,
                          onChanged: _hasScrolledToBottom
                              ? (v) => setState(() => _isChecked = v ?? false)
                              : null,
                          activeColor: const Color(0xFF2563EB),
                        ),
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'I have read and understood this agreement and I consent to the use of my camera as described.',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _showDeclineInfoDialog,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF475569),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            minimumSize: const Size(44, 48),
                          ),
                          child: const Text('Decline / Not Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: canAgree ? _handleConsentAccepted : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            disabledBackgroundColor: const Color(0xFFCBD5E1),
                            disabledForegroundColor: Colors.white,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            minimumSize: const Size(44, 48),
                            elevation: 0,
                          ),
                          child: _isSavingConsent
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('I Agree & Continue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.45),
          ),
        ],
      ),
    );
  }
}
