# Emergency Location Tracking & Admin Map Feature - Implementation Plan

Implement real-time GPS location tracking for emergency SOS reporting on the resident side, and an interactive Emergency Monitoring Map & Dashboard on the admin side with status management and marker color coding.

## User Review Required

> [!IMPORTANT]
> - **Real-Time GPS Location**: We will add `geolocator` dependency and implement permission requests & device/browser geolocation retrieval when an SOS emergency is reported.
> - **Fallback**: If location permission is denied, residents will be informed and can provide a fallback manual location / Purok coordinate.
> - **Admin Emergency Map**: A dedicated Emergency Map page with a live active emergency sidebar, interactive markers color-coded by status (🔴 Pending, 🟡 Acknowledged, 🔵 Responding, 🟢 Resolved, ⚪ Cancelled), and center-on-select functionality.

## Proposed Changes

### Dependencies
#### [MODIFY] [pubspec.yaml](file:///C:/Users/Archie J. Canoy/Desktop/barangaytest/pubspec.yaml)
- Add `geolocator: ^13.0.2` for cross-platform GPS location acquisition (web and mobile).

### Data Models
#### [MODIFY] [report.dart](file:///C:/Users/Archie J. Canoy/Desktop/barangaytest/lib/models/report.dart)
- Add `latitude` (double?) and `longitude` (double?) fields to `Report` model and update `toMap()` / `fromMap()`.

### Resident Side - Emergency SOS Reporting with GPS
#### [MODIFY] [sos_modal.dart](file:///C:/Users/Archie J. Canoy/Desktop/barangaytest/lib/widgets/sos_modal.dart)
- Update confirmation dialog to inform residents that their GPS location will be shared with emergency administrators.
- Implement permission check and actual GPS location fetching (`Geolocator.getCurrentPosition()`) upon confirmation.
- Handle permission denial gracefully with fallback coordinates / manual entry notification.
- Save `latitude`, `longitude`, and timestamp in the `Report` object sent to Firestore.

### Admin Side - Emergency Monitoring & Map Dashboard
#### [NEW] [emergency_map_page.dart](file:///C:/Users/Archie J. Canoy/Desktop/barangaytest/lib/staff/screens/emergency_map_page.dart)
- Dedicated Emergency Map dashboard featuring:
  - Interactive map (`flutter_map`) displaying live emergency markers.
  - Color-coded pins: 🔴 Pending, 🟡 Acknowledged, 🔵 Responding, 🟢 Resolved, ⚪ Cancelled.
  - Active emergency sidebar listing active emergencies.
  - Click-to-center and marker info popup (Resident name, type, description, date/time, status, coordinates).
  - Status update dropdown/actions (`Pending`, `Acknowledged`, `Responding`, `Resolved`, `Cancelled`).

#### [MODIFY] [app_scaffold.dart](file:///C:/Users/Archie J. Canoy/Desktop/barangaytest/lib/staff/widgets/app_scaffold.dart) or navigation routes
- Add "Emergency Map" / "Emergency Monitoring" to the staff portal navigation drawer / menu.

## Verification Plan

### Automated Tests
- Run `flutter analyze` to verify code compilation and static analysis.

### Manual Verification
- Test filing an SOS report as a resident, granting/denying location permission, and verifying actual coordinates are captured.
- Test Admin Emergency Map page: viewing markers, clicking items in the sidebar to center the map, inspecting emergency details, and updating emergency statuses.
