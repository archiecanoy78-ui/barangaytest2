# Walkthrough - Resident Announcements, Notifications, FCM, and Real-Time Officials Directory

We have successfully implemented all requested features for connecting resident announcements, setting up the notification system with FCM and Cloud Functions, removing the search bar, and providing a real-time active staff/admin directory with direct messaging and calls.

---

## Changes Made

### 1. Announcements Real-Time Sync & Search Removal
- **[announcement.dart](file:///C:/Users/PC/AndroidStudioProjects/barangaytest2/lib/models/announcement.dart)**: Updated model to support unified field names (`title`, `body`/`content`, `category`/`type`, `createdAt`/`date`, `status`, `imageUrl`, `authorId`, `authorName`, `authorRole`, `isPinned`).
- **[home_screen.dart](file:///C:/Users/PC/AndroidStudioProjects/barangaytest2/lib/resident/screens/home_screen.dart)**:
  - Connected resident announcements to Firestore `announcements` collection via real-time `snapshots()` stream ordered by `createdAt` descending (limit 20), filtered to published/active status.
  - Removed the search icon from the header and cleaned up unused search modal code.
  - Added filter chips matching admin categories ("All Updates", "Urgent Advisories", "Water Service", "Public Health", "Community Clean-up", "Road Advisory", "General Notice").
  - Added loading, empty, and error states with retry functionality.

### 2. Resident Notifications & FCM Integration
- **[notification_service.dart](file:///C:/Users/PC/AndroidStudioProjects/barangaytest2/lib/services/notification_service.dart)**:
  - Configures FCM permissions, saves device tokens under `/users/{uid}/fcmToken`, handles token refreshes, handles foreground banner messages, and manages topic subscription/unsubscription (`residents`).
- **[notifications_screen.dart](file:///C:/Users/PC/AndroidStudioProjects/barangaytest2/lib/resident/screens/notifications_screen.dart)**:
  - Real-time list of `/users/{uid}/notifications` ordered by `createdAt` descending with unread item highlighting, "Mark all as read", swipe-to-delete, and empty state.
- **[home_screen.dart](file:///C:/Users/PC/AndroidStudioProjects/barangaytest2/lib/resident/screens/home_screen.dart)**:
  - Header bell icon features a real-time red badge showing unread notification count.
- **[functions/index.js](file:///C:/Users/PC/AndroidStudioProjects/barangaytest2/functions/index.js)**:
  - `onAnnouncementCreated`: Pushes FCM notifications to topic `residents` and batch writes in-app notifications to active residents.
  - `onReportStatusUpdated`: Notifies only the specific reporter (`reporterId`) when report status changes.

### 3. Real-Time Officials Directory & Contact Channels
- **[directory_screen.dart](file:///C:/Users/PC/AndroidStudioProjects/barangaytest2/lib/resident/screens/directory_screen.dart)**:
  - Replaced hardcoded list with real-time stream of active staff/admin accounts (`users` where `role` in `['staff', 'admin']`, `status == 'active'`, `isArchived != true`).
  - Automatically hides archived/deleted accounts.
  - **Message** button: Opens conversation in the existing Messages feature (`ResidentChatScreen`), respecting the 200-character message limit.
  - **Call** button: Launches device phone dialer using `url_launcher` (`tel:{phoneNumber}`).
  - Added loading, empty, and error states.

### 4. Firestore Security Rules
- **[firestore.rules](file:///C:/Users/PC/AndroidStudioProjects/barangaytest2/firestore.rules)**:
  - Secured `announcements` read access for active published notices, `users/{uid}/notifications` for notification owners, and restricted public staff/admin profile reads to residents.

---

## Verification Results

### Automated Tests
- Ran `flutter analyze`: **0 errors or warnings found**.

### Test Steps for Verification
1. **Announcements**: Post an announcement from the Admin Portal and confirm it appears instantly in the Resident App, and check that filter chips filter correctly.
2. **Search Bar Removal**: Verify the search icon is absent from the Announcements header and Directory screen.
3. **Notifications**: Create a new announcement or update a case status to Solved in the Admin console. Verify the resident bell icon displays an unread count badge, and tapping it opens the Notifications screen.
4. **Directory**: Open Directory in Resident app. Verify real staff/admin accounts are listed, archived accounts disappear, and tapping **Message** or **Call** initiates communication correctly.
