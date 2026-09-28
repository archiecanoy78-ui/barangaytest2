import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../utils_validators.dart';
import '../../models/user.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser!;
    final isGuest = user.role == UserRole.guest;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: OutlinedButton.icon(
              onPressed: () => appState.logout(),
              icon: const Icon(Icons.logout_rounded, size: 14),
              label: const Text('Sign Out', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFFEE2E2)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(context, user),
            const SizedBox(height: 32),
            _buildSectionLabel('ACCOUNT INFORMATION'),
            const SizedBox(height: 12),
            _buildInfoCard([
              _buildInfoRow(Icons.alternate_email_rounded, 'Username', user.username ?? 'N/A'),
              const Divider(height: 1, indent: 40),
              _buildInfoRow(Icons.location_on_outlined, 'Purok Location', user.purok),
              const Divider(height: 1, indent: 40),
              _buildInfoRow(Icons.phone_android_outlined, 'Phone Number', user.phoneNumber),
            ]),
            const SizedBox(height: 28),
            _buildSectionLabel('VERIFICATION STATUS'),
            const SizedBox(height: 12),
            _buildVerificationCard(user),
            const SizedBox(height: 32),
            if (!isGuest)
              ElevatedButton.icon(
                onPressed: () => _showEditProfile(context, user),
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text('Update Profile Details', style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Color(0xFF64748B),
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, User user) {
    final String initials = user.name.isNotEmpty 
        ? user.name.split(' ').map((e) => e[0]).take(2).join().toUpperCase() 
        : 'U';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ),
              if (user.isVerified)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 14),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: user.role == UserRole.guest ? const Color(0xFFF1F5F9) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user.role == UserRole.guest ? 'GUEST SESSION' : 'VERIFIED RESIDENT',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: user.role == UserRole.guest ? const Color(0xFF64748B) : const Color(0xFF2563EB),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard(User user) {
    final bool isVerified = user.isVerified;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isVerified ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isVerified ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isVerified ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isVerified ? Icons.verified_user_rounded : Icons.pending_actions_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isVerified ? 'Fully Authenticated' : 'Pending Verification',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: isVerified ? const Color(0xFF065F46) : const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isVerified
                      ? 'All digital services are active.'
                      : 'Waiting for official ID approval.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isVerified ? const Color(0xFF059669).withValues(alpha: 0.8) : const Color(0xFFD97706).withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfile(BuildContext context, User user) {
    final nameCtrl = TextEditingController(text: user.name);
    final phoneCtrl = TextEditingController(text: user.phoneNumber);
    String? nameError;
    String? phoneError;
    
    // Normalize purok value to match dropdown items (handle old lowercase data)
    final List<String> purokOptions = ['Purok 1', 'Purok 2', 'Purok 3', 'Purok 4', 'Purok 5', 'Purok 6'];
    String? selectedPurok;
    
    if (user.purok.isNotEmpty) {
      selectedPurok = purokOptions.firstWhere(
        (p) => p.toLowerCase() == user.purok.toLowerCase(),
        orElse: () => purokOptions.first,
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Update Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              const SizedBox(height: 20),
              _buildModalField(nameCtrl, 'Full Name', Icons.person_outline),
              Builder(builder: (_) {
                final err = UtilsValidators.validateName(nameCtrl.text);
                return err == null ? const SizedBox.shrink() : Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(err, style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
                );
              }),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedPurok,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.location_on_outlined, color: Color(0xFF94A3B8), size: 18),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    items: purokOptions
                        .map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 14))))
                        .toList(),
                    onChanged: (val) => setModalState(() => selectedPurok = val),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildModalField(phoneCtrl, 'Phone Number', Icons.phone_android_outlined, keyboardType: TextInputType.phone),
              Builder(builder: (_) {
                final err = UtilsValidators.validatePhone(phoneCtrl.text);
                return err == null ? const SizedBox.shrink() : Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(err, style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
                );
              }),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () {
                  final nameErr = UtilsValidators.validateName(nameCtrl.text);
                                    final phoneErr = UtilsValidators.validatePhone(phoneCtrl.text);
                  if (nameErr != null || phoneErr != null || selectedPurok == null) {
                    setModalState(() {
                      nameError = nameErr;
                      phoneError = phoneErr;
                    });
                    return;
                  }

                  final updatedUser = User(
                    id: user.id,
                    name: nameCtrl.text,
                    username: user.username,
                    role: user.role,
                    staffRole: user.staffRole,
                    purok: selectedPurok!,
                    phoneNumber: phoneCtrl.text,
                    isVerified: user.isVerified,
                    idImagePath: user.idImagePath,
                    faceData: user.faceData,
                    isArchived: user.isArchived,
                    password: user.password,
                  );
                  context.read<AppState>().updateUser(updatedUser);
                  Navigator.pop(context);
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalField(TextEditingController ctrl, String hint, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
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
}
