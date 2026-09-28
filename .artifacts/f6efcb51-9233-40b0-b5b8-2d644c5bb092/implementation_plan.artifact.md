# Implementation Plan - Exclusive Bounded Map for Barangay Putho Tuntungin, Los Baños, Laguna

## Proposed Changes

### 1. Dependencies Setup (`pubspec.yaml`)
- Add `flutter_map: ^6.1.0` and `latlong2: ^6.1.0` for interactive OpenStreetMap rendering and camera constraint handling.

### 2. Bounded Exclusive Map Screen (`map_screen.dart`)
- #### [MODIFY] [pubspec.yaml](file:///C:/Users/Archie J. Canoy/Desktop/barangaytest/pubspec.yaml)
  - Add `flutter_map` and `latlong2`.
- #### [MODIFY] [map_screen.dart](file:///C:/Users/Archie J. Canoy/Desktop/barangaytest/lib/staff/screens/map_screen.dart)
  - Replace iframe mock map with `flutter_map`:
    - **Center**: `14.1520, 121.2518`, Initial Zoom: `16`.
    - **Camera Constraint**: `CameraConstraint.contain` with `LatLngBounds(LatLng(14.1370, 121.2370), LatLng(14.1670, 121.2670))` to hard-lock panning to Brgy Putho Tuntungin, Los Baños, Laguna.
    - **Zoom Bounds**: `minZoom: 14`, `maxZoom: 19`.
    - **PolygonLayer**: Draw the precise boundary polygon of Brgy Putho Tuntungin, Los Baños, Laguna.
    - **MarkerLayer**: Display resident-reported incidents (`appState.reports`), validating coordinates against the barangay bounding box.
    - **Boundary Validation & Feedback**: Show a `SnackBar` if any attempt is made to pan/search outside the restricted barangay bounds.

## Verification Plan

### Automated Tests
- Run `flutter pub get` and `flutter analyze` to ensure successful dependency resolution and zero compilation errors.

### Manual Verification
- Deploy/run the web portal and open **Operations Map**.
- Test panning and zooming to verify that the map is exclusively constrained to Barangay Putho Tuntungin, Los Baños, Laguna, with boundary polygon and incident markers.
