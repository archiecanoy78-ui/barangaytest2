import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/user.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.currentUser!;
    final isGuest = user.role == UserRole.guest;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => appState.logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(context, user),
            const SizedBox(height: 24),
            const Text(
              'Account Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoTile(context, Icons.person, 'Full Name', user.name),
            _buildInfoTile(context, Icons.location_on, 'Purok/Zone', user.purok),
            _buildInfoTile(context, Icons.phone, 'Phone Number', user.phoneNumber),
            const SizedBox(height: 24),
            const Text(
              'Verification Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildVerificationCard(user),
            const SizedBox(height: 32),
            if (!isGuest)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showEditProfile(context, user),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile Information'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, User user) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
              if (user.isVerified)
                const Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.verified, color: Colors.blue, size: 20),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            user.role == UserRole.guest ? 'Guest Session' : 'Verified Resident',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context, IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
      ),
    );
  }

  Widget _buildVerificationCard(User user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: user.isVerified ? Colors.green.shade50 : Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: user.isVerified ? Colors.green.shade200 : Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(
            user.isVerified ? Icons.verified_user : Icons.pending_actions,
            color: user.isVerified ? Colors.green : Colors.orange,
            size: 40,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.isVerified ? 'Fully Verified' : 'Verification Pending',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: user.isVerified ? Colors.green.shade800 : Colors.orange.shade800,
                  ),
                ),
                Text(
                  user.isVerified
                      ? 'You have full access to all barangay digital services.'
                      : 'Please wait for the barangay secretary to verify your ID.',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
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
    final purokCtrl = TextEditingController(text: user.purok);
    final phoneCtrl = TextEditingController(text: user.phoneNumber);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: purokCtrl,
                decoration: const InputDecoration(labelText: 'Purok/Zone'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedUser = User(
                id: user.id,
                name: nameCtrl.text,
                role: user.role,
                staffRole: user.staffRole,
                purok: purokCtrl.text,
                phoneNumber: phoneCtrl.text,
                isVerified: user.isVerified,
                idImagePath: user.idImagePath,
                faceData: user.faceData,
                isArchived: user.isArchived,
              );
              context.read<AppState>().updateUser(updatedUser);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated successfully!')),
              );
            },
            child: const Text('SAVE CHANGES'),
          ),
        ],
      ),
    );
  }
}
