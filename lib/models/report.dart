import 'package:flutter/material.dart';

enum ReportStatus {
  pending,
  underReview,
  underInvestigation,
  assigned,
  inProgress,
  actionRequired,
  resolved,
  rejected,
  closed
}

extension ReportStatusExtension on ReportStatus {
  String get label {
    switch (this) {
      case ReportStatus.pending:
        return 'Pending';
      case ReportStatus.underReview:
        return 'Under Review';
      case ReportStatus.underInvestigation:
        return 'Under Investigation';
      case ReportStatus.assigned:
        return 'Assigned';
      case ReportStatus.inProgress:
        return 'In Progress';
      case ReportStatus.actionRequired:
        return 'Action Required';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.rejected:
        return 'Rejected';
      case ReportStatus.closed:
        return 'Closed';
    }
  }

  Color get color {
    switch (this) {
      case ReportStatus.pending:
        return const Color(0xFFF59E0B); // Amber
      case ReportStatus.underReview:
      case ReportStatus.assigned:
        return const Color(0xFF1B365D); // Blue
      case ReportStatus.underInvestigation:
        return const Color(0xFF7C3AED); // Purple
      case ReportStatus.inProgress:
      case ReportStatus.actionRequired:
        return const Color(0xFFEA580C); // Orange
      case ReportStatus.resolved:
        return const Color(0xFF10B981); // Green
      case ReportStatus.rejected:
      case ReportStatus.closed:
        return const Color(0xFF64748B); // Gray
    }
  }
}

enum RiskLevel { low, medium, high }

class Report {
  final String id;
  final String title;
  final String category;
  final String description;
  final String incidentLocation;
  final DateTime incidentDateTime;
  final String purok;
  final String complainantName;
  final String complainantPhone;
  final String? complainantEmail;
  ReportStatus status;
  final DateTime timestamp;
  String? assignedToId;
  String? investigationNotes;
  String? actionTaken;
  String? resolutionProof;
  final String? reporterId;
  final List<String> attachmentUrls;
  String priority;
  final bool isAnonymous;
  final bool hasMedia;
  final bool metadataValid;
  final bool isPotentialDuplicate;
  final String? contactInfo;
  final List<String> confirmations;
  final RiskLevel riskScore;
  final String remarks;
  final bool isSOS;
  bool isRead;
  final double? latitude;
  final double? longitude;

  Report({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    this.incidentLocation = '',
    DateTime? incidentDateTime,
    this.purok = '',
    this.complainantName = '',
    this.complainantPhone = '',
    this.complainantEmail,
    this.status = ReportStatus.pending,
    DateTime? timestamp,
    this.assignedToId,
    this.investigationNotes,
    this.actionTaken,
    this.resolutionProof,
    this.reporterId,
    this.attachmentUrls = const [],
    this.priority = 'Medium',
    this.isAnonymous = false,
    this.hasMedia = false,
    this.metadataValid = true,
    this.isPotentialDuplicate = false,
    this.contactInfo,
    this.confirmations = const [],
    this.riskScore = RiskLevel.medium,
    this.remarks = '',
    this.isSOS = false,
    this.isRead = false,
    this.latitude,
    this.longitude,
  })  : incidentDateTime = incidentDateTime ?? DateTime.now(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'description': description,
      'incidentLocation': incidentLocation,
      'incidentDateTime': incidentDateTime.toIso8601String(),
      'purok': purok,
      'complainantName': complainantName,
      'complainantPhone': complainantPhone,
      'complainantEmail': complainantEmail,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'assignedToId': assignedToId,
      'investigationNotes': investigationNotes,
      'actionTaken': actionTaken,
      'resolutionProof': resolutionProof,
      'reporterId': reporterId,
      'attachmentUrls': attachmentUrls,
      'priority': priority,
      'isAnonymous': isAnonymous,
      'hasMedia': hasMedia,
      'metadataValid': metadataValid,
      'isPotentialDuplicate': isPotentialDuplicate,
      'contactInfo': contactInfo,
      'confirmations': confirmations,
      'riskScore': riskScore.name,
      'remarks': remarks,
      'isSOS': isSOS,
      'isRead': isRead,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      incidentLocation: map['incidentLocation'] ?? '',
      incidentDateTime: map['incidentDateTime'] != null ? DateTime.parse(map['incidentDateTime']) : DateTime.now(),
      purok: map['purok'] ?? '',
      complainantName: map['complainantName'] ?? '',
      complainantPhone: map['complainantPhone'] ?? '',
      complainantEmail: map['complainantEmail'],
      status: ReportStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ReportStatus.pending,
      ),
      timestamp: map['timestamp'] != null ? DateTime.parse(map['timestamp']) : DateTime.now(),
      assignedToId: map['assignedToId'],
      investigationNotes: map['investigationNotes'],
      actionTaken: map['actionTaken'],
      resolutionProof: map['resolutionProof'],
      reporterId: map['reporterId'],
      attachmentUrls: map['attachmentUrls'] != null ? List<String>.from(map['attachmentUrls']) : const [],
      priority: map['priority'] ?? 'Medium',
      isAnonymous: map['isAnonymous'] ?? false,
      hasMedia: map['hasMedia'] ?? false,
      metadataValid: map['metadataValid'] ?? true,
      isPotentialDuplicate: map['isPotentialDuplicate'] ?? false,
      contactInfo: map['contactInfo'],
      confirmations: map['confirmations'] != null ? List<String>.from(map['confirmations']) : const [],
      riskScore: RiskLevel.values.firstWhere(
        (e) => e.name == map['riskScore'],
        orElse: () => RiskLevel.medium,
      ),
      remarks: map['remarks'] ?? '',
      isSOS: map['isSOS'] ?? false,
      isRead: map['isRead'] ?? false,
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
    );
  }
}
