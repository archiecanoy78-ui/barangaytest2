import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app_state.dart';
import 'models/user.dart';
import 'resident/resident_main.dart';
import 'staff/staff_main.dart';
import 'resident/screens/registration_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const BarangayApp(),
    ),
  );
}

class BarangayApp extends StatelessWidget {
  const BarangayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Reportyan',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (appState.currentUser == null) {
      return const RoleSelectionScreen();
    }
    
    return appState.currentUser!.role == UserRole.staff
        ? const StaffMain()
        : const ResidentMain();
  }
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade800, Colors.blue.shade400],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),
              // Hero Section
              const Icon(Icons.account_balance, size: 80, color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                'E-Reportyan',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const Text(
                'Community Service Portal',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 60),
              // Role Cards
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildRoleCard(
                          context,
                          title: 'I am a Resident',
                          subtitle: 'Report issues, request documents, and view announcements.',
                          icon: Icons.person_pin_circle,
                          color: Colors.blue.shade700,
                          onTap: () => appState.login(UserRole.resident),
                        ),
                        const SizedBox(height: 15),
                        _buildRoleCard(
                          context,
                          title: 'Enter as Guest',
                          subtitle: 'File anonymous reports with mandatory evidence.',
                          icon: Icons.person_outline,
                          color: Colors.orange.shade800,
                          onTap: () => appState.login(UserRole.guest),
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                            );
                          },
                          icon: Icon(Icons.person_add_rounded, size: 18, color: Colors.blue.shade700),
                          label: Text(
                            'New Resident? Create an Account',
                            style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.blue.shade200, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Row(
                            children: [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text('OFFICIAL USE', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),
                        ),
                        _buildRoleCard(
                          context,
                          title: 'Barangay Staff',
                          subtitle: 'Manage reports, personnel, and barangay operations.',
                          icon: Icons.admin_panel_settings,
                          color: Colors.blueGrey.shade800,
                          onTap: () => appState.login(UserRole.staff),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          color: color.withValues(alpha: 0.05),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}
