import 'package:flutter/material.dart';

enum ReportStatus {
  pending,
  under_investigation,
  resolved,
  rejected,
}

extension ReportStatusExtension on ReportStatus {
  static final Map<String, ReportStatus> _legacyStatusMap = {
    'pending': ReportStatus.pending,
    'under_investigation': ReportStatus.under_investigation,
    'underinvestigation': ReportStatus.under_investigation,
    'under_investigation': ReportStatus.under_investigation,
    'under_review': ReportStatus.under_investigation,
    'underreview': ReportStatus.under_investigation,
    'assigned': ReportStatus.under_investigation,
    'in_progress': ReportStatus.under_investigation,
    'inprogress': ReportStatus.under_investigation,
    'action_required': ReportStatus.under_investigation,
    'actionrequired': ReportStatus.under_investigation,
    'resolved': ReportStatus.resolved,
    'rejected': ReportStatus.rejected,
    'closed': ReportStatus.resolved,
  };

  static List<ReportStatus> get canonicalValues => [
    ReportStatus.pending,
    ReportStatus.under_investigation,
    ReportStatus.resolved,
    ReportStatus.rejected,
  ];

  static ReportStatus parse(dynamic value) {
    if (value == null) return ReportStatus.pending;
    final normalized = value.toString().trim();
    if (normalized.isEmpty) return ReportStatus.pending;
    final key = normalized.toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    return _legacyStatusMap[key] ?? ReportStatus.pending;
  }

  String get key {
    switch (this) {
      case ReportStatus.pending:
        return 'pending';
      case ReportStatus.under_investigation:
        return 'under_investigation';
      case ReportStatus.resolved:
        return 'resolved';
      case ReportStatus.rejected:
        return 'rejected';
    }
  }

  String get label {
    switch (this) {
      case ReportStatus.pending:
        return 'Pending';
      case ReportStatus.under_investigation:
        return 'Under Investigation';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.rejected:
        return 'Rejected';
    }
  }

  bool get isTerminal => this == ReportStatus.resolved || this == ReportStatus.rejected;

  Color get color {
    switch (this) {
      case ReportStatus.pending:
        return const Color(0xFFF59E0B);
      case ReportStatus.under_investigation:
        return const Color(0xFF7C3AED);
      case ReportStatus.resolved:
        return const Color(0xFF10B981);
      case ReportStatus.rejected:
        return const Color(0xFF64748B);
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
  final DateTime? updatedAt;
  final String? updatedBy;
  final List<Map<String, dynamic>> statusHistory;
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
  int upvoteCount;
  List<String> upvotedUserIds;

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
    ReportStatus? status,
    DateTime? timestamp,
    this.updatedAt,
    this.updatedBy,
    List<Map<String, dynamic>>? statusHistory,
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
    this.upvoteCount = 0,
    List<String>? upvotedUserIds,
  })  : incidentDateTime = incidentDateTime ?? DateTime.now(),
        timestamp = timestamp ?? DateTime.now(),
        status = status ?? ReportStatus.pending,
        statusHistory = statusHistory ?? const [],
        upvotedUserIds = upvotedUserIds ?? [];

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
      'status': status.key,
      'timestamp': timestamp.toIso8601String(),
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
      'updated_by': updatedBy,
      'status_history': statusHistory,
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
      'upvoteCount': upvoteCount,
      'upvotedUserIds': upvotedUserIds,
    };
  }

  factory Report.fromMap(Map<String, dynamic> map) {
    final parsedStatus = ReportStatusExtension.parse(map['status'] ?? map['statusValue'] ?? 'pending');
    final rawHistory = map['status_history'] is List ? List<Map<String, dynamic>>.from(
      (map['status_history'] as List).map((entry) {
        if (entry is Map) return Map<String, dynamic>.from(entry as Map);
        return <String, dynamic>{};
      }),
    ) : const <Map<String, dynamic>>[];

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
      status: parsedStatus,
      timestamp: map['timestamp'] != null ? DateTime.parse(map['timestamp']) : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) : null,
      updatedBy: map['updated_by'],
      statusHistory: rawHistory,
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
      upvoteCount: map['upvoteCount'] is int ? map['upvoteCount'] : 0,
      upvotedUserIds: map['upvotedUserIds'] != null ? List<String>.from(map['upvotedUserIds']) : const [],
    );
  }
}
