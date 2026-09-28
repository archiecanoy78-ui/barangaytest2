import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/report.dart';
import 'models/user.dart';
import 'models/announcement.dart';
import 'models/activity_log.dart';
import 'models/message.dart';
import 'dart:math';

class AppState extends ChangeNotifier {
  late final FirebaseFirestore _firestore;

  User? _currentUser;
  List<Report> _reports = [];
  List<Announcement> _announcements = [];
  List<User> _staffList = [];
  List<User> _allUsers = [];
  List<User> _archivedUsers = [];
  List<ActivityLog> _activityLogs = [];
  List<Message> _messages = [];
  
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
  List<String> _categories = [
    'Noise / Disturbance',
    'Garbage / Waste',
    'Road / Infrastructure',
    'Drainage',
    'Street Lighting',
    'Public Safety',
    'Animal Concern',
    'Neighborhood Dispute',
    'Other'
  ];

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
    } catch (e) {
      debugPrint("AppState Firestore init skipped or failed: $e");
    }
  }

  void _initializeData() async {
    if (_firestore == null) return;
    final residentSnapshot = await _firestore!.collection('users').doc('resident_001').get();
    final adminSnapshot = await _firestore!.collection('users').doc('admin_001').get();
    final staffSnapshot = await _firestore!.collection('users').doc('staff_001').get();

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
        await _firestore!.collection('users').doc(user.id).set(user.toMap());
      }
      debugPrint('Seeded ${pendingUsers.length} default users.');
    }
  }

  void _listenToReports() {
    _firestore?.collection('reports').orderBy('timestamp', descending: true).snapshots().listen((snapshot) {
      _reports = snapshot.docs.map((doc) => Report.fromMap(doc.data())).toList();
      notifyListeners();
    });
  }

  void _listenToAnnouncements() {
    _firestore?.collection('announcements').orderBy('date', descending: true).snapshots().listen((snapshot) {
      _announcements = snapshot.docs.map((doc) => Announcement.fromMap(doc.data(), doc.id)).toList();
      notifyListeners();
    });
  }


  void _listenToStaff() {
    _firestore?.collection('users')
      .where('role', whereIn: ['staff', 'admin'])
      .snapshots().listen((snapshot) {
      _staffList = snapshot.docs.map((doc) => User.fromMap(doc.data())).toList();
      notifyListeners();
    });
  }

  void _listenToUsers() {
    _firestore?.collection('users').snapshots().listen((snapshot) {
      _allUsers = snapshot.docs.map((doc) => User.fromMap(doc.data())).toList();
      _archivedUsers = _allUsers.where((user) => user.isArchived).toList();
      notifyListeners();
    });
  }

  void _listenToMessages() {
    _firestore?.collection('messages').orderBy('timestamp', descending: true).snapshots().listen((snapshot) {
      _messages = snapshot.docs.map((doc) => Message.fromMap(doc.data())).toList();
      notifyListeners();
    });
  }

  void _listenToActivityLogs() {
    _firestore?.collection('activity_logs').orderBy('timestamp', descending: true).limit(100).snapshots().listen((snapshot) async {
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

  User? get currentUser => _currentUser;
  List<Report> get reports => _reports;
  List<Announcement> get announcements => _announcements;
  List<User> get staffList => _staffList;
  List<User> get allUsers => _allUsers;
  List<User> get archivedUsers => _archivedUsers;
  List<ActivityLog> get activityLogs => _activityLogs;
  List<Message> get messages => _messages;
  List<String> get categories => _categories;
  List<Report> get activeSOS => _reports.where((report) => report.isSOS).toList();

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
      _currentUser = User.fromMap(userData);

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

  void logout() {
    logActivity(
      action: "Logout",
      complaintId: "N/A",
      description: "Admin/Staff logged out: ${_currentUser?.name}"
    );
    _currentUser = null;
    notifyListeners();
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
      purok: purok,
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
      purok: purok,
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
      purok: purok,
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
    final number = random.nextInt(900000) + 100000; // 6 digits
    return "BR-$year-$number";
  }

  Future<String> submitComplaint(Report report) async {
    try {
      await _firestore.collection('reports').doc(report.id).set(report.toMap());
      
      logActivity(
        action: "Filed Complaint",
        complaintId: report.id,
        description: "${report.category}: ${report.title}"
      );
      
      return report.id;
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
    await _firestore.collection('reports').doc(report.id).set(report.toMap());
    final existingIndex = _reports.indexWhere((item) => item.id == report.id);
    if (existingIndex >= 0) {
      _reports[existingIndex] = report;
    } else {
      _reports.insert(0, report);
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
    );

    _reports[reportIndex] = updated;
    _firestore.collection('reports').doc(reportId).update({'remarks': combinedRemarks});
    notifyListeners();
  }

  void updateReportStatus(String reportId, ReportStatus newStatus, {String? notes, String? actionTaken, String? priority}) {
    final Map<String, dynamic> updates = {'status': newStatus.name};
    if (notes != null) updates['investigationNotes'] = notes;
    if (actionTaken != null) updates['actionTaken'] = actionTaken;
    if (priority != null) updates['priority'] = priority;

    _firestore.collection('reports').doc(reportId).update(updates);

    final reportIndex = _reports.indexWhere((report) => report.id == reportId);
    if (reportIndex != -1) {
      final report = _reports[reportIndex];
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
        status: newStatus,
        timestamp: report.timestamp,
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
        remarks: report.remarks,
        isSOS: report.isSOS,
      );
    }

    logActivity(
      action: "Updated Complaint",
      complaintId: reportId,
      description: "Status changed to ${newStatus.name}"
    );
    notifyListeners();
  }

  void assignStaff(String reportId, String staffId) {
    final staff = _staffList.firstWhere((s) => s.id == staffId);
    _firestore.collection('reports').doc(reportId).update({
      'assignedToId': staffId,
      'status': ReportStatus.underInvestigation.name,
    });

    logActivity(
      action: "Assigned Staff",
      complaintId: reportId,
      description: "Assigned to ${staff.name}"
    );
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

  // Category Management
  void addCategory(String category) {
    if (!_categories.contains(category)) {
      _categories.add(category);
      notifyListeners();
    }
  }

  void removeCategory(String category) {
    _categories.remove(category);
    notifyListeners();
  }

  // Announcement Management
  Future<void> addAnnouncement(Announcement announcement) async {
    await _firestore.collection('announcements').add(announcement.toMap());
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
