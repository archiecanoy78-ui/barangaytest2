import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../app_state.dart';
import '../../models/report.dart';
import '../widgets/portal_theme.dart';
import '../widgets/status_badge.dart';
import 'complaint_details_page.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  Report? _selectedReport;
  String _selectedPurokFilter = 'All';

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

  // Helper validation for marker coordinates / user actions against barangay bounds
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

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final reports = appState.reports;

    final filteredReports = reports.where((r) {
      if (_selectedPurokFilter == 'All') return true;
      return r.purok.toLowerCase().contains(_selectedPurokFilter.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: PortalColors.background,
      body: Row(
        children: [
          // Left Side: Exclusive Bounded OpenStreetMap via flutter_map
          Expanded(
            flex: 3,
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
                            'Operations Map — Brgy. Putho Tuntungin, Los Baños',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PortalColors.textDark),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Exclusive restricted map view • Hard-locked to barangay boundaries',
                            style: TextStyle(fontSize: 12, color: PortalColors.textMuted),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text('Filter Purok: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: PortalColors.textSecondary)),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: _selectedPurokFilter,
                            items: ['All', 'Purok 1', 'Purok 2', 'Purok 3', 'Purok 4', 'Purok 5', 'Purok 6']
                                .map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 12))))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedPurokFilter = v ?? 'All'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: PortalColors.border),
                // Map View Container
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
                          cameraConstraint: CameraConstraint.contain(
                            bounds: _brgyBounds,
                          ),
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
                          // Incident Markers Layer
                          MarkerLayer(
                            markers: filteredReports.map((r) {
                              final index = reports.indexOf(r);
                              final point = getReportCoordinates(r, index);

                              return Marker(
                                point: point,
                                width: 40,
                                height: 40,
                                child: GestureDetector(
                                  onTap: () {
                                    _mapController.move(point, 16.5);
                                    setState(() => _selectedReport = r);
                                  },
                                  child: Tooltip(
                                    message: '${r.title} (${r.purok})',
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: r.isSOS ? PortalColors.danger : PortalColors.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 3))],
                                      ),
                                      child: Icon(
                                        r.isSOS ? Icons.warning_amber_rounded : Icons.location_on_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      // Overlay Selected Incident Card
                      if (_selectedReport != null)
                        Positioned(
                          bottom: 24,
                          left: 24,
                          right: 24,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 4))],
                              border: Border.all(color: PortalColors.border),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _selectedReport!.isSOS ? Icons.warning_amber_rounded : Icons.location_on_rounded,
                                  color: _selectedReport!.isSOS ? PortalColors.danger : PortalColors.primary,
                                  size: 28,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_selectedReport!.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_selectedReport!.category} • ${_selectedReport!.purok.isNotEmpty ? _selectedReport!.purok : 'Purok 1'} • Location: ${_selectedReport!.incidentLocation.isNotEmpty ? _selectedReport!.incidentLocation : 'Putho Tuntungin'}',
                                        style: const TextStyle(fontSize: 12, color: PortalColors.textMuted),
                                      ),
                                    ],
                                  ),
                                ),
                                StatusBadge(status: _selectedReport!.status),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => ComplaintDetailsPage(report: _selectedReport!)),
                                  ),
                                  style: ElevatedButton.styleFrom(backgroundColor: PortalColors.primary, foregroundColor: Colors.white),
                                  child: const Text('View Details'),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                  onPressed: () => setState(() => _selectedReport = null),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1, color: PortalColors.border),
          // Right Side: Tracked Incidents Sidebar
          Expanded(
            flex: 1,
            child: Container(
              color: PortalColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tracked Incidents', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: PortalColors.textDark)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: PortalColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('${filteredReports.length}', style: const TextStyle(color: PortalColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: PortalColors.border),
                  Expanded(
                    child: filteredReports.isEmpty
                        ? const Center(child: Text('No incidents found in this barangay zone.', style: TextStyle(color: PortalColors.textMuted)))
                        : ListView.separated(
                            itemCount: filteredReports.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: PortalColors.border),
                            itemBuilder: (context, index) {
                              final r = filteredReports[index];
                              final isSelected = _selectedReport?.id == r.id;
                              final point = getReportCoordinates(r, reports.indexOf(r));
                              return ListTile(
                                selected: isSelected,
                                selectedTileColor: PortalColors.primary.withValues(alpha: 0.06),
                                onTap: () {
                                  _mapController.move(point, 16.5);
                                  setState(() => _selectedReport = r);
                                },
                                leading: Icon(
                                  r.isSOS ? Icons.warning_amber_rounded : Icons.fiber_manual_record_rounded,
                                  size: 16,
                                  color: r.isSOS ? PortalColors.danger : PortalColors.primary,
                                ),
                                title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: Text('${r.category} • ${r.purok.isNotEmpty ? r.purok : 'Purok 1'}', style: const TextStyle(fontSize: 11, color: PortalColors.textMuted)),
                                trailing: StatusBadge(status: r.status),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
