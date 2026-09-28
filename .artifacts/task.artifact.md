# Task List - Emergency Location Tracking & Admin Map Feature

- [x] Add `geolocator` dependency to `pubspec.yaml`
- [x] Update `Report` model (`lib/models/report.dart`) with `latitude` and `longitude` fields
- [x] Update `sos_modal.dart` to request location permission, fetch actual GPS coordinates, and save with the emergency report
- [x] Create `EmergencyMapPage` (`lib/staff/screens/emergency_map_page.dart`) with active emergency sidebar, interactive map, color-coded markers, and status updates
- [x] Register Emergency Map in staff navigation (`app_scaffold.dart`)
- [x] Verify build and analysis (`dart analyze`)
