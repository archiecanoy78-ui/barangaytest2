# Announcements Stream, Resident Notifications, FCM Triggers, and Real-Time Officials Directory - Implementation Plan

Implement:
1. Real-time Firestore synchronization between Admin and Resident Announcements with category filtering, loading/empty/error states, and removal of the search bar.
2. Complete Resident Notification System: FCM topic subscription, Cloud Function notification triggers for new announcements and case status updates (`onUpdate`), and an in-app Notifications Screen with unread badges.
3. Real-Time Officials Directory: Dynamic listing of active staff/admin accounts from Firestore with direct **Message** (Messages feature) and **Call** (`url_launcher`) buttons.

---

## User Review Required

> [!IMPORTANT]
> - **Shared Announcements Collection**: Both Admin and Resident apps will consume `/announcements` in Firestore with fields: `title`, `body`, `category`, `imageUrl`, `authorId`, `authorName`, `authorRole`, `createdAt`, `status: 'published'|'archived'`, `isPinned`.
> - **Cloud Function Triggers**:
>   - `onAnnouncementCreated`: Triggered when an announcement is published -> pushes FCM notification to the `residents` topic and writes in-app notifications to `/users/{uid}/notifications/{id}`.
>   - `onReportStatusUpdated`: Triggered when a report's status changes -> notifies only the reporter resident.
> - **FCM Token Management**: Saves `fcmToken` under `/users/{uid}`, subscribes to `residents` FCM topic on resident login, and unsubscribes on logout.
> - **Real-Time Directory Chat & Call**: The Directory screen fetches active staff/admin accounts, and tapping **Message** opens a conversation in the Messages system with a 200-character limit. Tapping **Call** opens the device phone dialer.

---

## Proposed Changes

### 1. Dependencies & Announcement Firestore Sync
#### [MODIFY] [pubspec.yaml](file:///C:/Users/Archie%20J.%20Canoy/Desktop/barangaytest/pubspec.yaml)
- Add `firebase_messaging: ^15.1.3` and `url_launcher: ^6.3.0`.

#### [MODIFY] [home_screen.dart](file:///C:/Users/Archie%20J.%20Canoy/Desktop/barangaytest/lib/resident/screens/home_screen.dart)
- Consume `/announcements` collection via `snapshots()` filtered to `status == 'published'`, ordered by `createdAt` descending.
- Remove search icon from top bar. Keep notification bell icon with red unread badge and count.
- Update filter chips to filter dynamically by Firestore `category`.
- Add loading, empty ("No announcements yet"), and error states with a retry button.

### 2. Resident Notification System & FCM Triggers
#### [NEW] [notifications_screen.dart](file:///C:/Users/Archie%20J.%20Canoy/Desktop/barangaytest/lib/resident/screens/notifications_screen.dart)
- Real-time list of `/users/{uid}/notifications` ordered by `createdAt` descending.
- Highlights unread items, provides "Mark all as read", swipe-to-delete, and navigates to the announcement or report detail view on tap.

#### [NEW] [notification_service.dart](file:///C:/Users/Archie%20J.%20Canoy/Desktop/barangaytest/lib/services/notification_service.dart)
- Handles FCM permission request, saves token to `/users/{uid}`, handles foreground/background message handlers, and subscribes/unsubscribes to the `residents` FCM topic.

#### [MODIFY] [functions/index.js](file:///C:/Users/Archie%20J.%20Canoy/Desktop/barangaytest/functions/index.js)
- `onAnnouncementCreated`: Fires on `onCreate` in `announcements` collection, sends FCM message to topic `residents`, and batch writes notification records into `/users/{uid}/notifications`.
- `onReportStatusUpdated`: Fires on `onUpdate` in `reports` collection when `status` changes, sending targeted FCM and in-app notification to the report author.

### 3. Real-Time Officials Directory
#### [MODIFY] [directory_screen.dart](file:///C:/Users/Archie%20J.%20Canoy/Desktop/barangaytest/lib/resident/screens/directory_screen.dart)
- Stream `/users` where `role` in `['staff', 'admin']` and `status == 'active'`.
- Render official cards with photo, name, role, and phone number.
- **Message** button: Opens/creates conversation in `/conversations/{residentUid}` with target official and opens `ResidentChatScreen`.
- **Call** button: Uses `url_launcher` to launch `tel:{phoneNumber}`.
- Remove search bar from Directory screen.

#### [MODIFY] [firestore.rules](file:///C:/Users/Archie%20J.%20Canoy/Desktop/barangaytest/firestore.rules)
- Update rules for `/announcements`, `/users/{uid}/notifications`, and public official fields.

---

## Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure 0 static analysis errors.
- Run `flutter test` to verify unit and widget tests pass.

### Manual Verification
- **Announcements Stream**: Create/edit an announcement in Admin console. Confirm it instantly updates in the Resident app, and filter chips accurately filter by category.
- **Header Cleanup**: Verify the search icon is removed from the Announcements header and Directory header.
- **Notifications**: Create a new announcement or update a case status to Solved in the Admin console. Verify the resident's bell icon shows an unread badge, and tapping it opens the Notification screen.
- **Directory**: Open Directory in Resident app. Verify real staff/admin profiles are displayed. Tap **Message** to open the real-time chat with 200-char limit, and tap **Call** to verify phone dialer trigger.
