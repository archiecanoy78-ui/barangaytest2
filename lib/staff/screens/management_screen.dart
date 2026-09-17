import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_state.dart';
import '../../models/user.dart';

class ManagementScreen extends StatelessWidget {
  const ManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final residents = appState.allUsers.where((u) => u.role == UserRole.resident).toList();
    final staff = appState.allUsers.where((u) => u.role == UserRole.staff).toList();
    final archived = appState.archivedUsers;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('User Management'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Residents'),
              Tab(text: 'Staff'),
              Tab(text: 'Archived'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUserList(context, residents, true, false),
            _buildUserList(context, staff, false, false),
            _buildUserList(context, archived, false, true),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(BuildContext context, List<User> users, bool isResidentTab, bool isArchivedTab) {
    final appState = context.read<AppState>();
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(user.name),
          subtitle: Text('${user.purok} - ${user.phoneNumber}'),
          onTap: () => _showUserCRUD(context, user, isArchivedTab),
          trailing: isArchivedTab
              ? IconButton(
                  icon: const Icon(Icons.restore, color: Colors.green),
                  onPressed: () => appState.restoreUser(user.id),
                )
              : (isResidentTab
                  ? (user.isVerified
                      ? const Icon(Icons.verified, color: Colors.blue)
                      : ElevatedButton(
                          onPressed: () => appState.verifyResident(user.id),
                          child: const Text('Verify'),
                        ))
                  : Chip(label: Text(user.staffRole?.name.toUpperCase() ?? 'STAFF'))),
        );
      },
    );
  }

  void _showUserCRUD(BuildContext context, User user, bool isArchived) {
    final appState = context.read<AppState>();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('User Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('View Full Profile'),
              subtitle: const Text('ID, Photo, and Biometric status'),
              onTap: () {
                Navigator.pop(context);
                _showUserProfile(context, user);
              },
            ),
            if (!isArchived) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Information'),
                subtitle: const Text('Update name, purok, or phone'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditUser(context, user);
                },
              ),
              ListTile(
                leading: const Icon(Icons.archive_outlined, color: Colors.red),
                title: const Text('Archive User', style: TextStyle(color: Colors.red)),
                subtitle: const Text('Hide from active directory'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmArchive(context, user);
                },
              ),
            ] else
              ListTile(
                leading: const Icon(Icons.restore, color: Colors.green),
                title: const Text('Restore User', style: TextStyle(color: Colors.green)),
                subtitle: const Text('Move back to active directory'),
                onTap: () {
                  Navigator.pop(context);
                  appState.restoreUser(user.id);
                },
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showUserProfile(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${user.name}\'s Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${user.id}'),
            Text('Purok: ${user.purok}'),
            Text('Phone: ${user.phoneNumber}'),
            Text('Status: ${user.isVerified ? "Verified" : "Pending"}'),
            const SizedBox(height: 10),
            Container(
              height: 100,
              width: double.infinity,
              color: Colors.grey.shade200,
              child: const Center(child: Icon(Icons.image_outlined, size: 40, color: Colors.grey)),
            ),
            const Center(child: Text('Simulated ID Card Image', style: TextStyle(fontSize: 10, color: Colors.grey))),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE'))],
      ),
    );
  }

  void _showEditUser(BuildContext context, User user) {
    final nameCtrl = TextEditingController(text: user.name);
    final purokCtrl = TextEditingController(text: user.purok);
    final phoneCtrl = TextEditingController(text: user.phoneNumber);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
            TextField(controller: purokCtrl, decoration: const InputDecoration(labelText: 'Purok')),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              final updated = User(
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
              context.read<AppState>().updateUser(updated);
              Navigator.pop(context);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _confirmArchive(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archive User?'),
        content: Text('Are you sure you want to archive ${user.name}? They will no longer appear in the active directory.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              context.read<AppState>().archiveUser(user.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User archived.')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ARCHIVE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
