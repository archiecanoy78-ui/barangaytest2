import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../app_state.dart';
import '../../models/report.dart';
import '../widgets/portal_theme.dart';

class EmergencyMapPage extends StatefulWidget {
  const EmergencyMapPage({super.key});

  @override
  State<EmergencyMapPage> createState() => _EmergencyMapPageState();
}

class _EmergencyMapPageState extends State<EmergencyMapPage> {
  final MapController _mapController = MapController();
  Report? _selectedEmergency;

  // Barangay Putho Tuntungin, Los Baños, Laguna, Philippines Boundaries & Center
  static const LatLng _brgyCenter = LatLng(14.1520, 121.2518);
  static final LatLngBounds _brgyBounds = LatLngBounds(
    const LatLng(14.1370, 121.2370), // SW Corner
    const LatLng(14.1670, 121.2670), // NE Corner
  );

  // Precise polygon boundary approximation for Brgy. Putho Tuntungin, Los Baños, Laguna
  static final List<LatLng> _brgyPolygonCoords = [
    const LatLng(14.1630, 121.2420),
    const LatLng(14.1650, 121.2550),
    const LatLng(14.1580, 121.2640),
    const LatLng(14.1420, 121.2620),
    const LatLng(14.1390, 121.2450),
    const LatLng(14.1480, 121.2390),
  ];

  bool _isWithinBarangay(LatLng point) {
    return _brgyBounds.contains(point);
  }

  void _handleOutOfBoundsAttempt(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚠️ Action restricted: Navigation or coordinates are outside Barangay Putho Tuntungin, Los Baños, Laguna.'),
        backgroundColor: PortalColors.danger,
        duration: Duration(seconds: 3),
      ),
    );
  }

  LatLng getReportCoordinates(Report r, int index) {
    if (r.latitude != null && r.longitude != null) {
      final point = LatLng(r.latitude!, r.longitude!);
      if (_isWithinBarangay(point)) return point;
    }
    // Deterministic fallback inside Barangay Putho Tuntungin bounds
    final lat = 14.1420 + ((index * 0.0035) % 0.0200);
    final lng = 121.2420 + ((index * 0.0042) % 0.0200);
    return LatLng(lat, lng);
  }

  Color _getMarkerColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Colors.red; // 🔴 New/Pending
      case ReportStatus.underReview:
        return Colors.amber.shade700; // 🟡 Acknowledged
      case ReportStatus.inProgress:
      case ReportStatus.assigned:
        return Colors.blue; // 🔵 Responding
      case ReportStatus.resolved:
        return Colors.green; // 🟢 Resolved
      default:
        return Colors.grey; // ⚪ Cancelled / Closed
    }
  }

  void _centerOnEmergency(Report report, List<Report> allReports) {
    final index = allReports.indexOf(report);
    final point = getReportCoordinates(report, index >= 0 ? index : 0);
    _mapController.move(point, 16.5);
    setState(() {
      _selectedEmergency = report;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final allReports = appState.reports;
    final emergencies = allReports.where((r) => r.isSOS || r.category.toLowerCase().contains('emergency')).toList();

    return Scaffold(
      backgroundColor: PortalColors.background,
      body: Row(
        children: [
          // Left Sidebar: Active Emergencies List
          SizedBox(
            width: 380,
            child: Container(
              decoration: const BoxDecoration(
                color: PortalColors.surface,
                border: Border(right: BorderSide(color: PortalColors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: PortalColors.border)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Active Emergencies',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PortalColors.textDark),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${emergencies.length} Active',
                            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: emergencies.isEmpty
                        ? const Center(
                            child: Text(
                              'No active emergency reports.',
                              style: TextStyle(color: PortalColors.textMuted, fontSize: 13),
                            ),
                          )
                        : ListView.separated(
                            itemCount: emergencies.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: PortalColors.border),
                            itemBuilder: (context, index) {
                              final report = emergencies[index];
                              final isSelected = _selectedEmergency?.id == report.id;
                              final markerColor = _getMarkerColor(report.status);

                              return ListTile(
                                selected: isSelected,
                                selectedTileColor: PortalColors.primary.withOpacity(0.05),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                leading: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: markerColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                title: Text(
                                  report.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('Purok: ${report.purok.isNotEmpty ? report.purok : 'Purok 1'}', style: const TextStyle(fontSize: 12)),
                                    const SizedBox(height: 2),
                                    Text('Status: ${report.status.label}', style: TextStyle(fontSize: 11, color: markerColor, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                trailing: const Icon(Icons.location_on_rounded, size: 20, color: PortalColors.primary),
                                onTap: () => _centerOnEmergency(report, allReports),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          // Right: Interactive Map & Details Panel
          Expanded(
            child: Column(
              children: [
                // Header Bar
                Container(
                  padding: const EdgeInsets.all(20),
                  color: PortalColors.surface,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Emergency Map — Brgy. Putho Tuntungin, Los Baños',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PortalColors.textDark),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Live GPS coordinates tracking • Hard-locked to barangay boundaries',
                            style: TextStyle(fontSize: 12, color: PortalColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: PortalColors.border),
                // Map & Bottom Details Split
                Expanded(
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _brgyCenter,
                          initialZoom: 16.0,
                          minZoom: 14.0,
                          maxZoom: 19.0,
                          cameraConstraint: CameraConstraint.contain(bounds: _brgyBounds),
                          onPositionChanged: (position, hasGesture) {
                            if (hasGesture && position.center != null) {
                              if (!_isWithinBarangay(position.center!)) {
                                _handleOutOfBoundsAttempt(context);
                              }
                            }
                          },
                        ),
                        children: [
                          // OpenStreetMap Tile Layer
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.barangaytest',
                          ),
                          // Barangay Boundary Polygon
                          PolygonLayer(
                            polygons: [
                              Polygon(
                                points: _brgyPolygonCoords,
                                color: PortalColors.primary.withValues(alpha: 0.12),
                                borderStrokeWidth: 3.0,
                                borderColor: PortalColors.primary,
                                isFilled: true,
                              ),
                            ],
                          ),
                          // Live Emergency Markers
                          MarkerLayer(
                            markers: emergencies.map((report) {
                              final index = allReports.indexOf(report);
                              final point = getReportCoordinates(report, index >= 0 ? index : 0);
                              final color = _getMarkerColor(report.status);
                              final isSelected = _selectedEmergency?.id == report.id;

                              return Marker(
                                point: point,
                                width: 50,
                                height: 50,
                                child: GestureDetector(
                                  onTap: () => _centerOnEmergency(report, allReports),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: isSelected ? 3 : 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      // Selected Emergency Details Overlay Panel
                      if (_selectedEmergency != null)
                        Positioned(
                          top: 20,
                          right: 20,
                          width: 380,
                          child: Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _selectedEmergency!.title,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 18),
                                        onPressed: () => setState(() => _selectedEmergency = null),
                                      ),
                                    ],
                                  ),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  _infoRow('Resident / Complainant:', _selectedEmergency!.complainantName.isNotEmpty ? _selectedEmergency!.complainantName : 'Anonymous / Guest'),
                                  _infoRow('Contact Number:', _selectedEmergency!.complainantPhone.isNotEmpty ? _selectedEmergency!.complainantPhone : 'N/A'),
                                  _infoRow('Purok / Location:', '${_selectedEmergency!.purok} (${_selectedEmergency!.incidentLocation.isNotEmpty ? _selectedEmergency!.incidentLocation : 'Live GPS'})'),
                                  _infoRow('Description:', _selectedEmergency!.description),
                                  _infoRow('Date & Time:', _selectedEmergency!.timestamp.toString()),
                                  _infoRow('Coordinates:', '${_selectedEmergency!.latitude?.toStringAsFixed(5) ?? 'N/A'}, ${_selectedEmergency!.longitude?.toStringAsFixed(5) ?? 'N/A'}'),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: DropdownButtonFormField<ReportStatus>(
                                          value: _selectedEmergency!.status,
                                          isExpanded: true,
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            border: OutlineInputBorder(),
                                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          ),
                                          items: ReportStatus.values.map((s) {
                                            return DropdownMenuItem(
                                              value: s,
                                              child: Text(s.label, style: const TextStyle(fontSize: 12)),
                                            );
                                          }).toList(),
                                          onChanged: (newStatus) {
                                            if (newStatus != null) {
                                              appState.updateReportStatus(_selectedEmergency!.id, newStatus);
                                              setState(() {
                                                _selectedEmergency!.status = newStatus;
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: PortalColors.textMuted)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 12, color: PortalColors.textDark)),
          ),
        ],
      ),
    );
  }
}
