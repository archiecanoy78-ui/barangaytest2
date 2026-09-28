import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../app_state.dart';
import '../models/report.dart';
import '../models/user.dart';

void showSOSModal(BuildContext context) {
  String emergencyType = 'Medical';
  String dispatchNeeded = 'Ambulance';
  final detailsController = TextEditingController();

  final Map<String, List<String>> dispatchMapping = {
    'Medical': ['Ambulance', 'Red Cross', 'Barangay Health Worker'],
    'Fire': ['Fire Truck (BFP)', 'Water Tanker', 'Assistance Only'],
    'Security/Crime': ['Barangay Tanod', 'Police Patrol', 'Peace & Order'],
    'Altercation/Suntukan': ['Tanod Patrol', 'Police Assistance'],
    'Natural Disaster': ['Rescue Team', 'Evacuation Service', 'Relief Goods'],
    'Other': ['General Assistance', 'Barangay Staff'],
  };

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 30),
                const SizedBox(width: 10),
                const Text('Request Emergency Help', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Select the reason for your emergency alert. Your location will be shared securely with authorized emergency administrators upon confirmation.', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 20),
            // Reasons Selection
            DropdownButtonFormField<String>(
              initialValue: emergencyType,
              items: dispatchMapping.keys
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  emergencyType = val!;
                  dispatchNeeded = dispatchMapping[emergencyType]![0];
                });
              },
              decoration: InputDecoration(
                labelText: 'Emergency Reason',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.help_outline),
              ),
            ),
            const SizedBox(height: 16),
            // Dispatch Selection
            DropdownButtonFormField<String>(
              initialValue: dispatchNeeded,
              items: dispatchMapping[emergencyType]!
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) => setState(() => dispatchNeeded = val!),
              decoration: InputDecoration(
                labelText: 'Specific Assistance Needed',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.people_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: detailsController,
              decoration: InputDecoration(
                labelText: 'Brief Situation Details',
                hintText: 'e.g., Patient is unconscious...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                alignLabelWithHint: true,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _confirmSOS(context, () async {
                  // Request Location Permission & Obtain GPS coordinates
                  double? lat;
                  double? lng;
                  try {
                    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                    if (serviceEnabled) {
                      LocationPermission permission = await Geolocator.checkPermission();
                      if (permission == LocationPermission.denied) {
                        permission = await Geolocator.requestPermission();
                      }
                      if (permission != LocationPermission.denied && permission != LocationPermission.deniedForever) {
                        Position position = await Geolocator.getCurrentPosition(
                          desiredAccuracy: LocationAccuracy.high,
                          timeLimit: const Duration(seconds: 5),
                        );
                        lat = position.latitude;
                        lng = position.longitude;
                      }
                    }
                  } catch (e) {
                    debugPrint("Error getting location: $e");
                  }

                  // Fallback to barangay center if location unavailable
                  lat ??= 14.1520;
                  lng ??= 121.2518;

                  final appState = context.read<AppState>();
                  final user = appState.currentUser!;
                  
                  final isGuest = user.role == UserRole.guest;
                  final sosReport = Report(
                    id: 'sos_${DateTime.now().millisecondsSinceEpoch}',
                    title: 'SOS: $emergencyType',
                    category: 'Emergency',
                    description: detailsController.text.isEmpty 
                        ? 'Reason: $emergencyType. Requested: $dispatchNeeded' 
                        : '$emergencyType - ${detailsController.text} (Team: $dispatchNeeded)',
                    purok: user.purok,
                    complainantName: isGuest ? '' : user.name,
                    complainantPhone: user.phoneNumber,
                    timestamp: DateTime.now(),
                    reporterId: user.id,
                    isAnonymous: isGuest,
                    isSOS: true,
                    status: ReportStatus.pending,
                    latitude: lat,
                    longitude: lng,
                  );
                  
                  appState.addReport(sosReport);
                  
                  Navigator.pop(context); // Close Modal
                  _showSuccessDialog(context);
                });
              },
              icon: const Icon(Icons.crisis_alert_rounded, size: 20),
              label: const Text('SEND SOS NOW', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    ),
  );
}

void _confirmSOS(BuildContext context, VoidCallback onConfirm) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.report_problem, color: Colors.red),
          SizedBox(width: 10),
          Text('Are you sure you want to report an emergency?'),
        ],
      ),
      content: const Text(
        'Sending an emergency alert will capture your current device GPS location and share it securely with authorized barangay emergency administrators. Do you want to report this emergency?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Report Emergency', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

void _showSuccessDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Emergency reported successfully'),
      content: const Text('Your location has been sent to the barangay admin. The Barangay Staff and Emergency Teams have been notified. Please stay calm and keep your line open.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('UNDERSTOOD'),
        ),
      ],
    ),
  );
}
