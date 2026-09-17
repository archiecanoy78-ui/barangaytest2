import 'package:flutter/material.dart';
import 'models/report.dart';
import 'models/user.dart';
import 'models/announcement.dart';
import 'models/message.dart';

class AppState extends ChangeNotifier {
  User? _currentUser;
  final List<Report> _reports = [];
  final List<Message> _messages = [];
  final List<Announcement> _announcements = [
    Announcement(
      title: 'Community Clean-up',
      content: 'Join us this Saturday for a community clean-up drive.',
      date: DateTime.now(),
      type: 'Event',
    ),
    Announcement(
      title: 'Water Service Interruption',
      content: 'Scheduled maintenance from 8 AM to 5 PM.',
      date: DateTime.now().add(const Duration(days: 1)),
      type: 'Alert',
    ),
  ];

  final List<User> _allUsers = [
    User(id: 'staff_001', name: 'Capt. Pedro', role: UserRole.staff, staffRole: StaffRole.captain, purok: 'Purok 1', phoneNumber: '091', isVerified: true),
    User(id: 'staff_002', name: 'Tanod Juan', role: UserRole.staff, staffRole: StaffRole.tanod, purok: 'Purok 2', phoneNumber: '092', isVerified: true),
    User(id: 'staff_003', name: 'Kagawad Maria', role: UserRole.staff, staffRole: StaffRole.kagawad, purok: 'Purok 3', phoneNumber: '093', isVerified: true),
    User(id: 'res_001', name: 'John Resident', role: UserRole.resident, purok: 'Purok 1', phoneNumber: '094', isVerified: true),
  ];

  User? get currentUser => _currentUser;
  List<Report> get reports => _reports;
  List<Announcement> get announcements => _announcements;
  List<Message> get messages => _messages;
  List<User> get allUsers => _allUsers.where((u) => !u.isArchived).toList();
  List<User> get archivedUsers => _allUsers.where((u) => u.isArchived).toList();

  void login(UserRole role) {
    if (role == UserRole.resident) {
      _currentUser = _allUsers.firstWhere((u) => u.id == 'res_001');
    } else if (role == UserRole.staff) {
      _currentUser = _allUsers.firstWhere((u) => u.id == 'staff_001');
    } else if (role == UserRole.guest) {
      _currentUser = User(
        id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Guest User',
        role: UserRole.guest,
        purok: 'Unknown',
        phoneNumber: 'N/A',
        isVerified: false,
      );
    }
    notifyListeners();
  }

  void registerResident({
    required String name,
    required String purok,
    required String phoneNumber,
    required String idPath,
    required String faceData,
  }) {
    final newUser = User(
      id: 'res_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      role: UserRole.resident,
      purok: purok,
      phoneNumber: phoneNumber,
      isVerified: false,
      idImagePath: idPath,
      faceData: faceData,
    );
    _allUsers.add(newUser);
    _currentUser = newUser;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  void addReport(Report report) {
    _reports.add(report);
    notifyListeners();
  }

  void confirmReport(String reportId, String userId) {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      if (!_reports[index].confirmations.contains(userId)) {
        _reports[index].confirmations.add(userId);
        notifyListeners();
      }
    }
  }

  RiskLevel calculateRisk(Report report) {
    int score = 0;
    if (report.isAnonymous) score += 2;
    if (!report.hasMedia) score += 3;
    if (!report.metadataValid) score += 2;
    if (report.isPotentialDuplicate) score += 1;
    if (report.description.length < 20) score += 1;
    if (report.contactInfo != null && report.contactInfo!.isNotEmpty) score -= 1;
    
    // Lower risk based on crowd verification
    score -= report.confirmations.length;

    if (score >= 5) return RiskLevel.high;
    if (score >= 3) return RiskLevel.medium;
    return RiskLevel.low;
  }

  void updateReportStatus(String reportId, ReportStatus newStatus) {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      _reports[index].status = newStatus;
      notifyListeners();
    }
  }

  void assignReport(String reportId, String staffId) {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      _reports[index].assignedToId = staffId;
      _reports[index].status = ReportStatus.assigned;
      notifyListeners();
    }
  }

  void addRemarks(String reportId, String remarks) {
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index != -1) {
      _reports[index].remarks = remarks;
      notifyListeners();
    }
  }

  void addAnnouncement(Announcement announcement) {
    _announcements.insert(0, announcement);
    notifyListeners();
  }

  void sendMessage(Message message) {
    _messages.insert(0, message);
    notifyListeners();
  }

  List<Message> getMessagesForRole(String position) {
    return _messages.where((m) => m.recipientPosition == position).toList();
  }

  void verifyResident(String userId) {
    final index = _allUsers.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _allUsers[index].isVerified = true;
      notifyListeners();
    }
  }

  void updateUser(User updatedUser) {
    final index = _allUsers.indexWhere((u) => u.id == updatedUser.id);
    if (index != -1) {
      _allUsers[index] = updatedUser;
      notifyListeners();
    }
  }

  void archiveUser(String userId) {
    final index = _allUsers.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _allUsers[index].isArchived = true;
      notifyListeners();
    }
  }

  void restoreUser(String userId) {
    final index = _allUsers.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _allUsers[index].isArchived = false;
      notifyListeners();
    }
  }

  Map<String, int> getReportCountsByStatus() {
    final Map<String, int> counts = {};
    for (var r in _reports) {
      counts[r.status.name] = (counts[r.status.name] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> getReportCountsByCategory() {
    final Map<String, int> counts = {};
    for (var r in _reports) {
      counts[r.category] = (counts[r.category] ?? 0) + 1;
    }
    return counts;
  }

  List<Report> getReportsForUser(String userId) {
    return _reports.where((r) => r.reporterId == userId && !r.isSOS).toList();
  }

  List<Report> get activeSOS {
    return _reports.where((r) => r.isSOS && (r.status != ReportStatus.resolved && r.status != ReportStatus.closed)).toList();
  }

  List<Report> getAssignedReports(String staffId) {
    // If Captain, see all. If specific personnel, see theirs.
    if (_currentUser?.staffRole == StaffRole.captain) {
      return _reports;
    }
    return _reports.where((r) => (r.assignedToId == staffId || r.status == ReportStatus.pending) && !r.isSOS).toList();
  }
}
