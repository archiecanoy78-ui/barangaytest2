# Implementation Plan - Firestore Integration

The user reported that Firestore data is not reflecting in the application. Research revealed that while Firebase is initialized, the `cloud_firestore` dependency is missing from `pubspec.yaml`, and `AppState.dart` uses local memory lists instead of Firestore for data persistence.

## User Review Required

> [!IMPORTANT]
> This change will shift the app from local memory storage to Firebase Firestore. Existing local data (hardcoded in `AppState`) will be used to populate Firestore initially if needed, but going forward, all CRUD operations will hit the live database.

## Proposed Changes

### Dependencies

#### [MODIFY] [pubspec.yaml](file:///C:/Users/Archie%20J.%20Canoy/Downloads/barangaytest/pubspec.yaml)
- Add `cloud_firestore: ^5.4.4` to the dependencies section.

### Data Models

#### [MODIFY] [user.dart](file:///C:/Users/Archie%20J.%20Canoy/Downloads/barangaytest/lib/models/user.dart)
- Add `toMap()` and `fromMap()` methods.

#### [MODIFY] [report.dart](file:///C:/Users/Archie%20J.%20Canoy/Downloads/barangaytest/lib/models/report.dart)
- Add `toMap()` and `fromMap()` methods.

#### [MODIFY] [message.dart](file:///C:/Users/Archie%20J.%20Canoy/Downloads/barangaytest/lib/models/message.dart)
- Add `toMap()` and `fromMap()` methods.

#### [MODIFY] [announcement.dart](file:///C:/Users/Archie%20J.%20Canoy/Downloads/barangaytest/lib/models/announcement.dart)
- Add `toMap()` and `fromMap()` methods.

### State Management

#### [MODIFY] [app_state.dart](file:///C:/Users/Archie%20J.%20Canoy/Downloads/barangaytest/lib/app_state.dart)
- Import `cloud_firestore`.
- Initialize `FirebaseFirestore` instance.
- Update constructor to fetch initial data from Firestore or set up real-time listeners.
- Update methods to perform Firestore operations:
    - `registerResident`: Add to `users` collection.
    - `addReport`: Add to `reports` collection.
    - `updateReportStatus`, `assignReport`, `addRemarks`: Update document in `reports` collection.
    - `addAnnouncement`: Add to `announcements` collection.
    - `sendMessage`: Add to `messages` collection.
    - `verifyResident`, `updateUser`, `archiveUser`, `restoreUser`: Update document in `users` collection.

## Verification Plan

### Automated Tests
- I will verify the code compiles successfully after adding the dependency.
- I will check for any syntax errors in the new Firestore logic.

### Manual Verification
- The user should run the app and verify that:
    1. Registering a resident creates a document in Firestore.
    2. Filing a report appears in Firestore.
    3. Changes to report status are reflected in Firestore.
    4. Announcements and messages are persisted.
