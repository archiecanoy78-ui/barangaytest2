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

  double? acquiredLat;
  double? acquiredLng;
  bool isFetchingLocation = false;
  String locationStatusText = 'Tap below to capture your exact GPS location for emergency dispatches.';

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
            const Text('Select the reason for your emergency alert. Get your current GPS location so responders can pinpoint your exact location.', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
            const SizedBox(height: 20),

            // Get Current Location Button & Live Status Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: acquiredLat != null ? Colors.green.shade50 : Colors.red.shade50.withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: acquiredLat != null ? Colors.green.shade300 : Colors.red.shade200,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  OutlinedButton.icon(
                    onPressed: isFetchingLocation
                        ? null
                        : () async {
                            setState(() {
                              isFetchingLocation = true;
                              locationStatusText = 'Acquiring high-accuracy GPS coordinates...';
                            });
                            try {
                              bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                              if (!serviceEnabled) {
                                setState(() {
                                  isFetchingLocation = false;
                                  locationStatusText = '📍 Location services are disabled on your device.';
                                });
                                return;
                              }
                              LocationPermission permission = await Geolocator.checkPermission();
                              if (permission == LocationPermission.denied) {
                                permission = await Geolocator.requestPermission();
                              }
                              if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
                                setState(() {
                                  isFetchingLocation = false;
                                  locationStatusText = '📍 Location permission denied. Defaulting to Barangay Center.';
                                });
                                return;
                              }
                              Position position = await Geolocator.getCurrentPosition(
                                locationSettings: const LocationSettings(
                                  accuracy: LocationAccuracy.high,
                                  timeLimit: Duration(seconds: 8),
                                ),
                              );
                              setState(() {
                                acquiredLat = position.latitude;
                                acquiredLng = position.longitude;
                                isFetchingLocation = false;
                                locationStatusText = '📍 GPS Location Captured: ${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
                              });
                            } catch (e) {
                              setState(() {
                                isFetchingLocation = false;
                                locationStatusText = '📍 Unable to get GPS coordinates: $e';
                              });
                            }
                          },
                    icon: isFetchingLocation
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(
                            acquiredLat != null ? Icons.my_location_rounded : Icons.location_searching_rounded,
                            color: acquiredLat != null ? Colors.green.shade800 : Colors.red.shade800,
                            size: 20,
                          ),
                    label: Text(
                      acquiredLat != null ? 'Location Captured' : 'Get Current Precise Location',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: acquiredLat != null ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      side: BorderSide(color: acquiredLat != null ? Colors.green.shade600 : Colors.red.shade400, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    locationStatusText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: acquiredLat != null ? Colors.green.shade900 : Colors.red.shade900,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _confirmSOS(context, () async {
                  double? lat = acquiredLat;
                  double? lng = acquiredLng;

                  // Auto-fetch if user hadn't pressed Get Location button manually
                  if (lat == null || lng == null) {
                    try {
                      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                      if (serviceEnabled) {
                        LocationPermission permission = await Geolocator.checkPermission();
                        if (permission == LocationPermission.denied) {
                          permission = await Geolocator.requestPermission();
                        }
                        if (permission != LocationPermission.denied && permission != LocationPermission.deniedForever) {
                          Position position = await Geolocator.getCurrentPosition(
                            locationSettings: const LocationSettings(
                              accuracy: LocationAccuracy.high,
                              timeLimit: Duration(seconds: 5),
                            ),
                          );
                          lat = position.latitude;
                          lng = position.longitude;
                        }
                      }
                    } catch (e) {
                      debugPrint("Auto location error: $e");
                    }
                  }

                  // Fallback to barangay center if location unavailable
                  lat ??= 14.1520;
                  lng ??= 121.2518;

                  if (!context.mounted) return;
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
                  
                  if (context.mounted) {
                    Navigator.pop(context); // Close Modal
                    _showSuccessDialog(context);
                  }
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
