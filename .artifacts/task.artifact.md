# Task List - Announcements Firestore Stream, Resident Notifications, FCM Triggers, and Real-Time Directory

- [/] Add `firebase_messaging` and `url_launcher` to `pubspec.yaml`
- [/] Connect `HomeScreen` (`lib/resident/screens/home_screen.dart`) to real-time `/announcements` stream with category filtering, loading/empty/error states, and header search icon removal
- [/] Implement `NotificationService` (`lib/services/notification_service.dart`) for FCM token handling, foreground/background message routing, and topic subscription
- [ ] Implement `NotificationsScreen` (`lib/resident/screens/notifications_screen.dart`) for real-time in-app notification list, unread badge, and "Mark all as read"
- [ ] Add `onAnnouncementCreated` and `onReportStatusUpdated` Cloud Functions in `functions/index.js` for automated push and in-app notifications
- [ ] Update `DirectoryScreen` (`lib/resident/screens/directory_screen.dart`) to stream active staff/admin accounts from Firestore with **Message** (Messages feature) and **Call** (`url_launcher`) buttons, and remove search bar
- [ ] Update `firestore.rules` for notifications, announcements, and official profile reads
- [ ] Verify build and tests (`flutter analyze` and `flutter test`)
