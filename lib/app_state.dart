import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'constants/app_constants.dart';
import 'models/report.dart';
import 'models/user.dart';
export 'models/user.dart';
export 'models/report.dart';
import 'models/announcement.dart';
import 'models/activity_log.dart';
import 'models/message.dart';
import 'models/camera_consent.dart';
import 'dart:math';

class AppState extends ChangeNotifier {
  late final FirebaseFirestore _firestore;

  User? _currentUser;
  bool _isInitializing = true;
  List<Report> _reports = [];
  List<Announcement> _announcements = [];
  List<User> _staffList = [];
  List<User> _allUsers = [];
  List<User> _archivedUsers = [];
  List<ActivityLog> _activityLogs = [];
  List<Message> _messages = [];

  static const String _sessionUidKey = 'barangay_session_uid';
  static const String _sessionRoleKey = 'barangay_session_role';
  static const _secureStorage = FlutterSecureStorage();

  bool get isInitializing => _isInitializing;
  User? get currentUser => _currentUser;
  String? get _currentUserId => _currentUser?.id ?? FirebaseAuth.instance.currentUser?.uid;
  List<Report> get reports => _reports;
  List<Announcement> get announcements => _announcements;
  List<User> get staffList => _staffList;
  List<User> get allUsers => _allUsers;
  List<User> get archivedUsers => _archivedUsers;
  List<ActivityLog> get activityLogs => _activityLogs;
  List<Message> get messages => _messages;
  List<String> get categories => AppConstants.categories;
  List<Report> get activeSOS => _reports.where((report) => report.isSOS).toList();

  List<Map<String, dynamic>> get staffNotifications {
    return _reports.map((report) => {
      'id': report.id,
      'type': 'issue_reported',
      'title': report.isSOS ? '🚨 EMERGENCY SOS: ${report.title}' : 'New Complaint: ${report.title}',
      'subtitle': '${report.category} • ${report.purok.isNotEmpty ? report.purok : 'Purok 1'}',
      'timestamp': report.timestamp,
      'isEmergency': report.isSOS,
      'status': report.isRead ? 'read' : 'unread',
      'report': report,
    }).toList();
  }

  int get unreadStaffNotificationsCount {
    return staffNotifications.where((n) => n['type'] == 'issue_reported' && n['status'] == 'unread').length;
  }

  Future<void> markReportAsRead(String reportId) async {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index >= 0) {
      _reports[index].isRead = true;
      try {
        await _firestore.collection('reports').doc(reportId).update({'isRead': true});
      } catch (_) {}
      notifyListeners();
    }
  }

  void markNotificationsAsRead() {
    for (var r in _reports) {
      r.isRead = true;
    }
    notifyListeners();
  }

  AppState() {
    try {
      _firestore = FirebaseFirestore.instance;
      _initializeData();
      _listenToReports();
      _listenToAnnouncements();
      _listenToStaff();
      _listenToUsers();
      _listenToActivityLogs();
      _listenToMessages();
      _restoreSession();
    } catch (e) {
      debugPrint("AppState Firestore init error: $e");
      _isInitializing = false;
      notifyListeners();
    }
  }

  /// Restores saved session from secure storage / SharedPreferences on startup
  Future<void> _restoreSession() async {
    try {
      String? savedUid;
      try {
        savedUid = await _secureStorage.read(key: _sessionUidKey);
      } catch (_) {}

      if (savedUid == null || savedUid.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        savedUid = prefs.getString(_sessionUidKey);
      }

      if (savedUid == null || savedUid.isEmpty) {
        final fbUser = FirebaseAuth.instance.currentUser;
        if (fbUser != null) {
          savedUid = fbUser.uid;
        }
      }

      if (savedUid != null && savedUid.isNotEmpty) {
        final userDoc = await _firestore.collection('users').doc(savedUid).get();
        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data()!;
          final isArchived = (data['isArchived'] as bool?) ?? false;
          final status = (data['status'] as String?)?.toLowerCase() ?? '';

          if (!isArchived && status != 'deleted' && status != 'archived' && status != 'disabled') {
            _currentUser = User.fromMap(data);
            debugPrint("Session restored successfully for user: ${_currentUser?.username} [${_currentUser?.id}]");
          } else {
            await _clearSavedSession();
          }
        } else if (savedUid == 'guest_session') {
          continueAsGuest();
        } else {
          await _clearSavedSession();
        }
      }

      await _migrateLegacyCategoriesAndPuroks();
    } catch (e) {
      debugPrint("Error restoring session: $e");
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  /// Migrates legacy records in Firestore to canonical category display names and purok keys
  Future<void> _migrateLegacyCategoriesAndPuroks() async {
    try {
      final snapshot = await _firestore.collection('reports').get();
      final batch = _firestore.batch();
      bool needsMigration = false;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final rawCat = (data['category'] as String?) ?? '';
        final rawPurok = (data['purok'] as String?) ?? '';

        final normCat = AppConstants.normalizeCategory(rawCat);
        final normPurok = AppConstants.normalizePurok(rawPurok);

        if (normCat != rawCat || normPurok != rawPurok) {
          needsMigration = true;
          batch.update(doc.reference, {
            'category': normCat,
            'purok': normPurok,
          });
        }
      }

      if (needsMigration) {
        await batch.commit();
        debugPrint('Legacy categories & puroks migrated to canonical values.');
      }
    } catch (e) {
      debugPrint('Legacy category migration check notice: $e');
    }
  }

  Future<void> _saveSession(User user) async {
    try {
      await _secureStorage.write(key: _sessionUidKey, value: user.id);
      await _secureStorage.write(key: _sessionRoleKey, value: user.role.name);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionUidKey, user.id);
      await prefs.setString(_sessionRoleKey, user.role.name);
    } catch (e) {
      debugPrint("Error saving session: $e");
    }
  }

  Future<void> _clearSavedSession() async {
    try {
      await _secureStorage.delete(key: _sessionUidKey);
      await _secureStorage.delete(key: _sessionRoleKey);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionUidKey);
      await prefs.remove(_sessionRoleKey);
    } catch (e) {
      debugPrint("Error clearing saved session: $e");
    }
  }

  void _initializeData() async {
    final residentSnapshot = await _firestore.collection('users').doc('resident_001').get();
    final adminSnapshot = await _firestore.collection('users').doc('admin_001').get();
    final staffSnapshot = await _firestore.collection('users').doc('staff_001').get();

    final defaultUsers = [
      User(
        id: 'resident_001',
        name: 'Resident User',
        username: 'resident',
        role: UserRole.resident,
        purok: 'Purok 1',
        phoneNumber: '09170000002',
        password: 'password',
      ),
      User(
        id: 'admin_001',
        name: 'Administrator',
        username: 'admin',
        role: UserRole.admin,
        staffRole: StaffRole.captain,
        purok: 'Main',
        phoneNumber: '09170000000',
        password: 'password',
      ),
      User(
        id: 'staff_001',
        name: 'Barangay Staff',
        username: 'staff',
        role: UserRole.staff,
        staffRole: StaffRole.tanod,
        purok: 'Zone 1',
        phoneNumber: '09170000001',
        password: 'password',
      ),
    ];

    final pendingUsers = defaultUsers.where((user) => ![
      residentSnapshot.exists ? 'resident_001' : null,
      adminSnapshot.exists ? 'admin_001' : null,
      staffSnapshot.exists ? 'staff_001' : null,
    ].contains(user.id)).toList();

    if (pendingUsers.isNotEmpty) {
      for (var user in pendingUsers) {
        await _firestore.collection('users').doc(user.id).set(user.toMap());
      }
      debugPrint('Seeded ${pendingUsers.length} default users.');
    }
  }

  void _listenToReports() {
    _firestore.collection('reports').orderBy('timestamp', descending: true).snapshots().listen((snapshot) {
      _reports = snapshot.docs.map((doc) => Report.fromMap(doc.data())).toList();
      notifyListeners();
    });
  }

  void _listenToAnnouncements() {
    _firestore.collection('announcements').orderBy('date', descending: true).snapshots().listen((snapshot) {
      _announcements = snapshot.docs.map((doc) => Announcement.fromMap(doc.data(), doc.id)).toList();
      notifyListeners();
    });
  }

  void _listenToStaff() {
    _firestore.collection('users')
      .where('role', whereIn: ['staff', 'admin'])
      .snapshots().listen((snapshot) {
      _staffList = snapshot.docs.map((doc) => User.fromMap(doc.data())).toList();
      notifyListeners();
    });
  }

  void _listenToUsers() {
    _firestore.collection('users').snapshots().listen((snapshot) {
      _allUsers = snapshot.docs.map((doc) => User.fromMap(doc.data())).toList();
      _archivedUsers = _allUsers.where((user) => user.isArchived).toList();
      notifyListeners();
    });
  }

  void _listenToMessages() {
    _firestore.collection('messages').orderBy('timestamp', descending: true).snapshots().listen((snapshot) {
      _messages = snapshot.docs.map((doc) => Message.fromMap(doc.data())).toList();
      notifyListeners();
    });
  }

  void _listenToActivityLogs() {
    _firestore.collection('activity_logs').orderBy('timestamp', descending: true).limit(100).snapshots().listen((snapshot) async {
      final now = DateTime.now();
      final cutoff = now.subtract(const Duration(hours: 23));

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['timestamp'] != null) {
          final timestamp = (data['timestamp'] is Timestamp)
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.tryParse(data['timestamp'].toString()) ?? now;
          if (timestamp.isBefore(cutoff)) {
            await doc.reference.delete();
          }
        }
      }

      _activityLogs = snapshot.docs
          .map((doc) => ActivityLog.fromMap(doc.data()))
          .where((log) => log.timestamp.isAfter(cutoff))
          .toList();
      notifyListeners();
    });
  }

  // Auth Methods
  Future<String?> loginWithCredentials(String username, String password) async {
    final cleanUsername = username.trim().toLowerCase();
    final cleanPassword = password.trim();

    try {
      final snapshot = await _firestore.collection('users')
          .where('username', isEqualTo: cleanUsername)
          .where('password', isEqualTo: cleanPassword)
          .get();

      if (snapshot.docs.isEmpty) {
        return "Invalid username or password.";
      }

      final userData = snapshot.docs.first.data();
      final user = User.fromMap(userData);

      if (user.isArchived) {
        return "Account is deactivated. Please contact administrator.";
      }

      _currentUser = user;
      await _saveSession(user);

      try {
        final email = '$cleanUsername@barangay.local';
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: cleanPassword);
      } catch (_) {}

      logActivity(
        action: "Login",
        complaintId: "N/A",
        description: "${_currentUser?.role.name.toUpperCase()} logged in: ${_currentUser?.name}"
      );

      notifyListeners();
      return null;
    } catch (e) {
      return "Login error: ${e.toString()}";
    }
  }

  void continueAsGuest() {
    _currentUser = User(
      id: 'guest_session',
      name: 'Guest User',
      username: 'guest',
      role: UserRole.guest,
      purok: 'Guest',
      phoneNumber: 'N/A',
      password: 'guest',
    );
    _saveSession(_currentUser!);
    notifyListeners();
  }

  Future<void> sendMessage(Message message) async {
    await _firestore.collection('messages').doc(message.id).set(message.toMap());
    _messages.add(message);
    notifyListeners();
  }

  List<Message> getMessagesForRole(String recipientPosition) {
    return _messages.where((message) => message.recipientPosition == recipientPosition).toList();
  }

  void logout() async {
    logActivity(
      action: "Logout",
      complaintId: "N/A",
      description: "User logged out: ${_currentUser?.name}"
    );
    _currentUser = null;
    await _clearSavedSession();
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    notifyListeners();
  }

  // Helper to write in-app notifications directly to Firestore for resident recipients
  Future<void> _createInAppNotification({
    required String recipientUid,
    required String type,
    required String title,
    required String message,
    required String referenceId,
  }) async {
    if (recipientUid.isEmpty || recipientUid == 'guest_session') return;
    try {
      final notifRef = _firestore
          .collection('users')
          .doc(recipientUid)
          .collection('notifications')
          .doc();

      await notifRef.set({
        'id': notifRef.id,
        'user_id': recipientUid,
        'type': type,
        'title': title,
        'message': message,
        'body': message,
        'reference_id': referenceId,
        'referenceId': referenceId,
        'is_read': false,
        'isRead': false,
        'created_at': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error creating in-app notification: $e');
    }
  }

  // Activity Logging
  void logActivity({required String action, required String complaintId, required String description}) {
    final log = ActivityLog(
      id: 'log_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      user: _currentUser?.name ?? "Guest",
      action: action,
      complaintId: complaintId,
      description: description,
    );
    _firestore.collection('activity_logs').doc(log.id).set(log.toMap());
  }

  // Upvote Logic with Growable List Instances & Firestore Transaction
  Future<void> toggleUpvote(String reportId) async {
    if (_currentUser == null || _currentUser!.role == UserRole.guest) {
      throw Exception('Guest/Logged-out users must sign in to upvote.');
    }

    final userId = _currentUser!.id;
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index == -1) return;

    final report = _reports[index];
    if (report.reporterId == userId) {
      throw Exception('You cannot upvote your own report.');
    }

    final hasUpvoted = report.upvotedUserIds.contains(userId);

    final updatedUpvotedIds = List<String>.from(report.upvotedUserIds);
    if (hasUpvoted) {
      updatedUpvotedIds.remove(userId);
      report.upvoteCount = max(0, report.upvoteCount - 1);
    } else {
      updatedUpvotedIds.add(userId);
      report.upvoteCount += 1;
    }
    report.upvotedUserIds = updatedUpvotedIds;
    notifyListeners();

    try {
      final reportRef = _firestore.collection('reports').doc(reportId);
      final upvoteRef = reportRef.collection('upvotes').doc(userId);

      await _firestore.runTransaction((tx) async {
        final upvoteDoc = await tx.get(upvoteRef);
        if (upvoteDoc.exists) {
          tx.delete(upvoteRef);
          tx.update(reportRef, {
            'upvoteCount': FieldValue.increment(-1),
            'upvotedUserIds': FieldValue.arrayRemove([userId]),
          });
        } else {
          tx.set(upvoteRef, {
            'userId': userId,
            'timestamp': FieldValue.serverTimestamp(),
          });
          tx.update(reportRef, {
            'upvoteCount': FieldValue.increment(1),
            'upvotedUserIds': FieldValue.arrayUnion([userId]),
          });
        }
      });
    } catch (e) {
      final rollbackUpvotedIds = List<String>.from(report.upvotedUserIds);
      if (hasUpvoted) {
        rollbackUpvotedIds.add(userId);
        report.upvoteCount += 1;
      } else {
        rollbackUpvotedIds.remove(userId);
        report.upvoteCount = max(0, report.upvoteCount - 1);
      }
      report.upvotedUserIds = rollbackUpvotedIds;
      notifyListeners();
      debugPrint("Upvote transaction failed: $e");
      throw Exception("Couldn't update your vote. Please try again.");
    }
  }

  // Flag/Report Inappropriate Content Moderation
  Future<void> flagReport(String reportId, String reason) async {
    final flagId = 'flag_${DateTime.now().millisecondsSinceEpoch}';
    final userId = _currentUser?.id ?? 'guest';

    await _firestore.collection('reports').doc(reportId).collection('flags').doc(flagId).set({
      'flagId': flagId,
      'reportId': reportId,
      'userId': userId,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
    });

    logActivity(
      action: "Flagged Report",
      complaintId: reportId,
      description: "User $userId flagged report $reportId for: $reason",
    );
  }

  // Camera Consent Persistence
  Future<void> recordCameraConsent(CameraConsent consent) async {
    try {
      await _firestore
          .collection('users')
          .doc(consent.userId)
          .collection('camera_consents')
          .doc(consent.id)
          .set(consent.toMap());

      await _firestore.collection('camera_consents').doc(consent.id).set(consent.toMap());
    } catch (e) {
      debugPrint("Error storing camera consent record: $e");
    }
  }

  Future<void> updateUser(User user) async {
    await _firestore.collection('users').doc(user.id).set(user.toMap());
    if (_currentUser?.id == user.id) {
      _currentUser = user;
    }
    notifyListeners();
  }

  Future<void> archiveUser(String userId) async {
    final user = _allUsers.firstWhere((candidate) => candidate.id == userId, orElse: () => _currentUser!);
    final archivedUser = User(
      id: user.id,
      name: user.name,
      username: user.username,
      role: user.role,
      staffRole: user.staffRole,
      purok: user.purok,
      phoneNumber: user.phoneNumber,
      isVerified: user.isVerified,
      idImagePath: user.idImagePath,
      faceData: user.faceData,
      isArchived: true,
      password: user.password,
    );
    await updateUser(archivedUser);
  }

  Future<void> restoreUser(String userId) async {
    final user = _allUsers.firstWhere((candidate) => candidate.id == userId, orElse: () => _currentUser!);
    final restoredUser = User(
      id: user.id,
      name: user.name,
      username: user.username,
      role: user.role,
      staffRole: user.staffRole,
      purok: user.purok,
      phoneNumber: user.phoneNumber,
      isVerified: user.isVerified,
      idImagePath: user.idImagePath,
      faceData: user.faceData,
      isArchived: false,
      password: user.password,
    );
    await updateUser(restoredUser);
  }

  Future<void> verifyResident(String userId) async {
    final user = _allUsers.firstWhere((candidate) => candidate.id == userId, orElse: () => _currentUser!);
    await updateUser(
      User(
        id: user.id,
        name: user.name,
        username: user.username,
        role: user.role,
        staffRole: user.staffRole,
        purok: user.purok,
        phoneNumber: user.phoneNumber,
        isVerified: true,
        idImagePath: user.idImagePath,
        faceData: user.faceData,
        isArchived: user.isArchived,
        password: user.password,
      ),
    );
  }

  Future<void> registerResident({
    required String name,
    required String username,
    required String purok,
    required String phoneNumber,
    required String idPath,
    required String faceData,
    required String password,
  }) async {
    final user = User(
      id: 'resident_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      username: username,
      role: UserRole.resident,
      purok: AppConstants.normalizePurok(purok),
      phoneNumber: phoneNumber,
      isVerified: false,
      idImagePath: idPath,
      faceData: faceData,
      password: password,
    );

    await _firestore.collection('users').doc(user.id).set(user.toMap());
    _allUsers.add(user);
    notifyListeners();
  }

  Future<void> registerUser(User user) async {
    await _firestore.collection('users').doc(user.id).set(user.toMap());
    _allUsers.add(user);
    _currentUser = user;
    notifyListeners();
  }

  Future<String?> registerUserWithoutSigningOutAdmin(User user) async {
    final cleanUsername = (user.username ?? '').trim().toLowerCase();

    try {
      final existingQuery = await _firestore.collection('users')
          .where('username', isEqualTo: cleanUsername)
          .get();

      if (existingQuery.docs.isNotEmpty) {
        return "This number/username is already registered.";
      }
    } catch (_) {}

    try {
      FirebaseApp secondaryApp;
      try {
        secondaryApp = Firebase.app('SecondaryAccountApp');
      } catch (_) {
        secondaryApp = await Firebase.initializeApp(
          name: 'SecondaryAccountApp',
          options: Firebase.app().options,
        );
      }

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final internalEmail = '$cleanUsername@barangay.local';
      final pass = (user.password != null && user.password!.length >= 6) ? user.password! : 'password123';

      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: internalEmail,
        password: pass,
      );

      final finalUser = User(
        id: credential.user?.uid ?? user.id,
        name: user.name,
        username: user.username,
        role: user.role,
        staffRole: user.staffRole,
        purok: AppConstants.normalizePurok(user.purok),
        phoneNumber: user.phoneNumber,
        isVerified: user.isVerified,
        idImagePath: user.idImagePath,
        faceData: user.faceData,
        isArchived: user.isArchived,
        password: user.password,
      );

      await _firestore.collection('users').doc(finalUser.id).set(finalUser.toMap());
      _allUsers.add(finalUser);
      if (finalUser.role == UserRole.staff || finalUser.role == UserRole.admin) {
        _staffList.add(finalUser);
      }

      await secondaryAuth.signOut();

      logActivity(
        action: "Register User",
        complaintId: "N/A",
        description: "Registered ${finalUser.role.name.toUpperCase()}: ${finalUser.name} (${finalUser.username})"
      );

      notifyListeners();
      return null;
    } catch (e) {
      await _firestore.collection('users').doc(user.id).set(user.toMap());
      _allUsers.add(user);
      if (user.role == UserRole.staff || user.role == UserRole.admin) {
        _staffList.add(user);
      }
      notifyListeners();
      return null;
    }
  }

  Future<void> addStaff({
    required String name,
    required String username,
    required StaffRole staffRole,
    required String purok,
    required String phoneNumber,
    required String password,
    String? idPhotoUrl,
    UserRole role = UserRole.staff,
  }) async {
    final newId = 'staff_${DateTime.now().millisecondsSinceEpoch}';
    final user = User(
      id: newId,
      name: name,
      username: username,
      role: role,
      staffRole: staffRole,
      purok: AppConstants.normalizePurok(purok),
      phoneNumber: phoneNumber,
      isVerified: idPhotoUrl != null,
      idImagePath: idPhotoUrl,
      idPhotoUrl: idPhotoUrl,
      verificationStatus: idPhotoUrl != null ? 'Verified' : 'Pending Verification',
      password: password,
    );

    await _firestore.collection('users').doc(newId).set(user.toMap());
    logActivity(
      action: "Add Staff",
      complaintId: "N/A",
      description: "Added new staff member: $name ($username) [Pending ID Verification]"
    );
    notifyListeners();
  }

  Future<void> addResident({
    required String name,
    required String username,
    required String purok,
    required String phoneNumber,
    required String password,
    bool isVerified = true,
  }) async {
    final newId = 'resident_${DateTime.now().millisecondsSinceEpoch}';
    final user = User(
      id: newId,
      name: name,
      username: username,
      role: UserRole.resident,
      purok: AppConstants.normalizePurok(purok),
      phoneNumber: phoneNumber,
      isVerified: isVerified,
      password: password,
    );

    await _firestore.collection('users').doc(newId).set(user.toMap());
    logActivity(
      action: "Add Resident",
      complaintId: "N/A",
      description: "Added new resident: $name ($username)"
    );
    notifyListeners();
  }

  Future<String?> deleteUser(String userId) async {
    final userList = _allUsers.where((u) => u.id == userId).toList();
    if (userList.isNotEmpty) {
      final targetUser = userList.first;
      if (targetUser.role == UserRole.resident && !targetUser.isArchived) {
        return "Cannot delete active resident. Resident must be archived first.";
      }
    }

    await _firestore.collection('users').doc(userId).delete();
    _allUsers.removeWhere((u) => u.id == userId);
    _staffList.removeWhere((u) => u.id == userId);
    _archivedUsers.removeWhere((u) => u.id == userId);
    logActivity(
      action: "Delete User",
      complaintId: "N/A",
      description: "Deleted user ID: $userId"
    );
    notifyListeners();
    return null;
  }

  // Complaint Management
  String generateComplaintId() {
    final year = DateTime.now().year;
    final random = Random();
    final number = random.nextInt(900000) + 100000;
    return "BR-$year-$number";
  }

  Future<String> submitComplaint(Report report) async {
    try {
      final normalizedReport = Report(
        id: report.id,
        title: report.title,
        category: AppConstants.normalizeCategory(report.category),
        description: report.description,
        incidentLocation: report.incidentLocation,
        incidentDateTime: report.incidentDateTime,
        purok: AppConstants.normalizePurok(report.purok),
        complainantName: report.complainantName,
        complainantPhone: report.complainantPhone,
        complainantEmail: report.complainantEmail,
        status: report.status,
        timestamp: report.timestamp,
        assignedToId: report.assignedToId,
        investigationNotes: report.investigationNotes,
        actionTaken: report.actionTaken,
        resolutionProof: report.resolutionProof,
        reporterId: report.reporterId,
        attachmentUrls: report.attachmentUrls,
        priority: report.priority,
        isAnonymous: report.isAnonymous,
        hasMedia: report.hasMedia,
        metadataValid: report.metadataValid,
        isPotentialDuplicate: report.isPotentialDuplicate,
        contactInfo: report.contactInfo,
        confirmations: report.confirmations,
        riskScore: report.riskScore,
        remarks: report.remarks,
        isSOS: report.isSOS,
        upvoteCount: report.upvoteCount,
        upvotedUserIds: report.upvotedUserIds,
      );

      await _firestore.collection('reports').doc(normalizedReport.id).set(normalizedReport.toMap());
      
      logActivity(
        action: "Filed Complaint",
        complaintId: normalizedReport.id,
        description: "${normalizedReport.category}: ${normalizedReport.title}"
      );
      
      return normalizedReport.id;
    } catch (e) {
      throw Exception("Failed to submit complaint: $e");
    }
  }

  Report? getReportById(String id) {
    try {
      return _reports.firstWhere((r) => r.id.toUpperCase() == id.toUpperCase());
    } catch (e) {
      return null;
    }
  }

  List<Report> getReportsForUser(String userId) {
    return _reports.where((report) => report.reporterId == userId).toList();
  }

  List<Report> getAssignedReports(String staffId) {
    return _reports.where((report) => report.assignedToId == staffId).toList();
  }

  Future<void> addReport(Report report) async {
    final normReport = Report(
      id: report.id,
      title: report.title,
      category: AppConstants.normalizeCategory(report.category),
      description: report.description,
      incidentLocation: report.incidentLocation,
      incidentDateTime: report.incidentDateTime,
      purok: AppConstants.normalizePurok(report.purok),
      complainantName: report.complainantName,
      complainantPhone: report.complainantPhone,
      complainantEmail: report.complainantEmail,
      status: report.status,
      timestamp: report.timestamp,
      assignedToId: report.assignedToId,
      investigationNotes: report.investigationNotes,
      actionTaken: report.actionTaken,
      resolutionProof: report.resolutionProof,
      reporterId: report.reporterId,
      attachmentUrls: report.attachmentUrls,
      priority: report.priority,
      isAnonymous: report.isAnonymous,
      hasMedia: report.hasMedia,
      metadataValid: report.metadataValid,
      isPotentialDuplicate: report.isPotentialDuplicate,
      contactInfo: report.contactInfo,
      confirmations: report.confirmations,
      riskScore: report.riskScore,
      remarks: report.remarks,
      isSOS: report.isSOS,
      upvoteCount: report.upvoteCount,
      upvotedUserIds: report.upvotedUserIds,
    );

    await _firestore.collection('reports').doc(normReport.id).set(normReport.toMap());
    final existingIndex = _reports.indexWhere((item) => item.id == normReport.id);
    if (existingIndex >= 0) {
      _reports[existingIndex] = normReport;
    } else {
      _reports.insert(0, normReport);
    }
    notifyListeners();
  }

  Future<void> deleteAllComplaints() async {
    try {
      final snapshot = await _firestore.collection('reports').get();
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      _reports.clear();
      logActivity(
        action: "Delete All Complaints",
        complaintId: "ALL",
        description: "Deleted all resident complaints from the database."
      );
      notifyListeners();
    } catch (e) {
      debugPrint("Failed to delete all complaints: $e");
      throw Exception("Failed to delete all complaints: $e");
    }
  }

  void confirmReport(String reportId, String userId) {
    final index = _reports.indexWhere((report) => report.id == reportId);
    if (index == -1) return;

    final report = _reports[index];
    final confirmations = List<String>.from(report.confirmations);
    if (!confirmations.contains(userId)) {
      confirmations.add(userId);
    }

    final updated = Report(
      id: report.id,
      title: report.title,
      category: report.category,
      description: report.description,
      incidentLocation: report.incidentLocation,
      incidentDateTime: report.incidentDateTime,
      purok: report.purok,
      complainantName: report.complainantName,
      complainantPhone: report.complainantPhone,
      complainantEmail: report.complainantEmail,
      status: report.status,
      timestamp: report.timestamp,
      assignedToId: report.assignedToId,
      investigationNotes: report.investigationNotes,
      actionTaken: report.actionTaken,
      resolutionProof: report.resolutionProof,
      reporterId: report.reporterId,
      attachmentUrls: report.attachmentUrls,
      priority: report.priority,
      isAnonymous: report.isAnonymous,
      hasMedia: report.hasMedia,
      metadataValid: report.metadataValid,
      isPotentialDuplicate: report.isPotentialDuplicate,
      contactInfo: report.contactInfo,
      confirmations: confirmations,
      riskScore: report.riskScore,
      remarks: report.remarks,
      isSOS: report.isSOS,
      upvoteCount: report.upvoteCount,
      upvotedUserIds: report.upvotedUserIds,
    );

    _reports[index] = updated;
    _firestore.collection('reports').doc(reportId).update({'confirmations': confirmations});
    notifyListeners();
  }

  RiskLevel calculateRisk(Report report) {
    final text = '${report.title} ${report.description} ${report.category}'.toLowerCase();
    if (text.contains('fire') || text.contains('medical') || text.contains('security') || text.contains('emergency')) {
      return RiskLevel.high;
    }
    if (text.contains('noise') || text.contains('waste') || text.contains('street') || text.contains('drainage')) {
      return RiskLevel.medium;
    }
    return RiskLevel.low;
  }

  void addRemarks(String reportId, String remark) {
    if (remark.trim().isEmpty) return;
    final reportIndex = _reports.indexWhere((report) => report.id == reportId);
    if (reportIndex == -1) return;

    final report = _reports[reportIndex];
    final combinedRemarks = [report.remarks, remark].where((entry) => entry.trim().isNotEmpty).join('\n');
    final updated = Report(
      id: report.id,
      title: report.title,
      category: report.category,
      description: report.description,
      incidentLocation: report.incidentLocation,
      incidentDateTime: report.incidentDateTime,
      purok: report.purok,
      complainantName: report.complainantName,
      complainantPhone: report.complainantPhone,
      complainantEmail: report.complainantEmail,
      status: report.status,
      timestamp: report.timestamp,
      assignedToId: report.assignedToId,
      investigationNotes: report.investigationNotes,
      actionTaken: report.actionTaken,
      resolutionProof: report.resolutionProof,
      reporterId: report.reporterId,
      attachmentUrls: report.attachmentUrls,
      priority: report.priority,
      isAnonymous: report.isAnonymous,
      hasMedia: report.hasMedia,
      metadataValid: report.metadataValid,
      isPotentialDuplicate: report.isPotentialDuplicate,
      contactInfo: report.contactInfo,
      confirmations: report.confirmations,
      riskScore: report.riskScore,
      remarks: combinedRemarks,
      isSOS: report.isSOS,
      upvoteCount: report.upvoteCount,
      upvotedUserIds: report.upvotedUserIds,
    );

    _reports[reportIndex] = updated;
    _firestore.collection('reports').doc(reportId).update({'remarks': combinedRemarks});

    if (report.reporterId != null && report.reporterId!.isNotEmpty) {
      _createInAppNotification(
        recipientUid: report.reporterId!,
        type: 'complaint_update',
        title: 'New Official Remark Added',
        message: 'Remark on "${report.title}": $remark',
        referenceId: reportId,
      );
    }

    notifyListeners();
  }

  Future<void> updateReportStatus(String reportId, ReportStatus newStatus, {String? notes, String? actionTaken, String? priority, String? rejectionReason}) async {
    final reportIndex = _reports.indexWhere((report) => report.id == reportId);
    final previous = reportIndex != -1 ? _reports[reportIndex] : null;
    final normalizedStatus = ReportStatusExtension.parse(newStatus);

    final Map<String, dynamic> updates = {'status': normalizedStatus.key};
    updates['updated_at'] = FieldValue.serverTimestamp();
    updates['updated_by'] = _currentUserId ?? 'system';
    if (notes != null) updates['investigationNotes'] = notes;
    if (actionTaken != null) updates['actionTaken'] = actionTaken;
    if (priority != null) updates['priority'] = priority;
    if (rejectionReason != null && rejectionReason.trim().isNotEmpty) updates['remarks'] = rejectionReason.trim();

    if (previous != null && previous.status == normalizedStatus) {
      return;
    }

    await _firestore.collection('reports').doc(reportId).update(updates);

    if (reportIndex != -1) {
      final report = _reports[reportIndex];
      final nextHistory = List<Map<String, dynamic>>.from(report.statusHistory ?? const <Map<String, dynamic>>[]);
      nextHistory.add({
        'status': normalizedStatus.key,
        'changed_by': _currentUserId ?? 'system',
        'timestamp': DateTime.now().toIso8601String(),
      });

      _reports[reportIndex] = Report(
        id: report.id,
        title: report.title,
        category: report.category,
        description: report.description,
        incidentLocation: report.incidentLocation,
        incidentDateTime: report.incidentDateTime,
        purok: report.purok,
        complainantName: report.complainantName,
        complainantPhone: report.complainantPhone,
        complainantEmail: report.complainantEmail,
        status: normalizedStatus,
        timestamp: report.timestamp,
        updatedAt: DateTime.now(),
        updatedBy: _currentUserId ?? 'system',
        statusHistory: nextHistory,
        assignedToId: report.assignedToId,
        investigationNotes: notes ?? report.investigationNotes,
        actionTaken: actionTaken ?? report.actionTaken,
        resolutionProof: report.resolutionProof,
        reporterId: report.reporterId,
        attachmentUrls: report.attachmentUrls,
        priority: priority ?? report.priority,
        isAnonymous: report.isAnonymous,
        hasMedia: report.hasMedia,
        metadataValid: report.metadataValid,
        isPotentialDuplicate: report.isPotentialDuplicate,
        contactInfo: report.contactInfo,
        confirmations: report.confirmations,
        riskScore: report.riskScore,
        remarks: rejectionReason ?? report.remarks,
        isSOS: report.isSOS,
        upvoteCount: report.upvoteCount,
        upvotedUserIds: report.upvotedUserIds,
      );

      final shouldNotify = previous != null && previous.status != normalizedStatus && (normalizedStatus == ReportStatus.resolved || normalizedStatus == ReportStatus.rejected);
      if (shouldNotify && report.reporterId != null && report.reporterId!.isNotEmpty) {
        final message = normalizedStatus == ReportStatus.resolved
            ? 'Good news! Your complaint "${report.title}" has been resolved.'
            : 'Your complaint "${report.title}" was rejected. ${rejectionReason != null && rejectionReason.trim().isNotEmpty ? rejectionReason.trim() : 'Please review the administrative note.'}';
        _createInAppNotification(
          recipientUid: report.reporterId!,
          type: 'complaint_update',
          title: normalizedStatus == ReportStatus.resolved ? 'Complaint Resolved' : 'Complaint Rejected',
          message: message,
          referenceId: reportId,
        );
      }
    }

    logActivity(
      action: "Updated Complaint",
      complaintId: reportId,
      description: "Status changed to ${normalizedStatus.label}"
    );
    notifyListeners();
  }

  Future<void> assignStaff(String reportId, String staffId) async {
    final staff = _staffList.firstWhere((s) => s.id == staffId);
    final reportIndex = _reports.indexWhere((r) => r.id == reportId);
    final existing = reportIndex != -1 ? _reports[reportIndex] : null;

    await _firestore.collection('reports').doc(reportId).update({
      'assignedToId': staffId,
      'updated_at': FieldValue.serverTimestamp(),
      'updated_by': _currentUserId ?? 'system',
    });

    if (reportIndex != -1 && existing != null) {
      _reports[reportIndex] = Report(
        id: existing.id,
        title: existing.title,
        category: existing.category,
        description: existing.description,
        incidentLocation: existing.incidentLocation,
        incidentDateTime: existing.incidentDateTime,
        purok: existing.purok,
        complainantName: existing.complainantName,
        complainantPhone: existing.complainantPhone,
        complainantEmail: existing.complainantEmail,
        status: existing.status,
        timestamp: existing.timestamp,
        updatedAt: DateTime.now(),
        updatedBy: _currentUserId ?? 'system',
        statusHistory: existing.statusHistory,
        assignedToId: staffId,
        investigationNotes: existing.investigationNotes,
        actionTaken: existing.actionTaken,
        resolutionProof: existing.resolutionProof,
        reporterId: existing.reporterId,
        attachmentUrls: existing.attachmentUrls,
        priority: existing.priority,
        isAnonymous: existing.isAnonymous,
        hasMedia: existing.hasMedia,
        metadataValid: existing.metadataValid,
        isPotentialDuplicate: existing.isPotentialDuplicate,
        contactInfo: existing.contactInfo,
        confirmations: existing.confirmations,
        riskScore: existing.riskScore,
        remarks: existing.remarks,
        isSOS: existing.isSOS,
        upvoteCount: existing.upvoteCount,
        upvotedUserIds: existing.upvotedUserIds,
      );
    }

    logActivity(
      action: "Assigned Staff",
      complaintId: reportId,
      description: "Assigned to ${staff.name}"
    );
    notifyListeners();
  }

  // Analytics
  Map<String, int> getReportCountsByStatus() {
    final Map<String, int> counts = {};
    for (var r in _reports) {
      counts[r.status.name] = (counts[r.status.name] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> getReportsByCategory() {
    final Map<String, int> counts = {};
    for (var r in _reports) {
      counts[r.category] = (counts[r.category] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> getReportsByPurok() {
    final Map<String, int> counts = {};
    for (var r in _reports) {
      counts[r.purok] = (counts[r.purok] ?? 0) + 1;
    }
    return counts;
  }

  // Announcement Management
  Future<void> addAnnouncement(Announcement announcement) async {
    final docRef = await _firestore.collection('announcements').add(announcement.toMap());
    
    // Broadcast in-app notifications to active residents
    try {
      final residentDocs = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'resident')
          .get();

      final batch = _firestore.batch();
      for (var userDoc in residentDocs.docs) {
        final notifRef = userDoc.reference.collection('notifications').doc();
        batch.set(notifRef, {
          'id': notifRef.id,
          'user_id': userDoc.id,
          'type': 'announcement',
          'title': 'New Announcement: ${announcement.title}',
          'message': announcement.content,
          'body': announcement.content,
          'reference_id': docRef.id,
          'referenceId': docRef.id,
          'is_read': false,
          'isRead': false,
          'created_at': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint("Error creating announcement in-app notifications: $e");
    }

    logActivity(
      action: "Added Announcement",
      complaintId: "N/A",
      description: "Title: ${announcement.title}"
    );
  }

  Future<void> updateAnnouncement(Announcement announcement) async {
    if (announcement.id != null && announcement.id!.isNotEmpty) {
      await _firestore.collection('announcements').doc(announcement.id).update(announcement.toMap());
    } else {
      final snapshot = await _firestore.collection('announcements')
          .where('title', isEqualTo: announcement.title)
          .get();
      for (var doc in snapshot.docs) {
        await doc.reference.update(announcement.toMap());
      }
    }
    logActivity(
      action: "Updated Announcement",
      complaintId: "N/A",
      description: "Title: ${announcement.title}"
    );
  }

  Future<void> deleteAnnouncement(String idOrTitle) async {
    if (idOrTitle.isEmpty) return;
    try {
      final docSnapshot = await _firestore.collection('announcements').doc(idOrTitle).get();
      if (docSnapshot.exists) {
        await docSnapshot.reference.delete();
      } else {
        final querySnapshot = await _firestore.collection('announcements')
            .where('title', isEqualTo: idOrTitle)
            .get();
        for (var doc in querySnapshot.docs) {
          await doc.reference.delete();
        }
      }
    } catch (e) {
      final querySnapshot = await _firestore.collection('announcements')
          .where('title', isEqualTo: idOrTitle)
          .get();
      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    }
    logActivity(
      action: "Deleted Announcement",
      complaintId: "N/A",
      description: "Target: $idOrTitle"
    );
  }
}
