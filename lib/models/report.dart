enum ReportStatus { pending, assigned, inProgress, resolved, closed }

enum RiskLevel { low, medium, high }

class Report {
  final String id;
  final String title;
  final String category;
  final String description;
  final String purok;
  ReportStatus status;
  final DateTime timestamp;
  final String reporterId;
  String? assignedToId;
  String? remarks;
  String? resolutionProof;
  final bool isSOS;
  
  // Triage & Verification Fields
  final bool isAnonymous;
  final bool hasMedia;
  final bool metadataValid;
  final bool isPotentialDuplicate;
  final RiskLevel riskScore;
  final List<String> confirmations; // User IDs of residents who confirmed
  final String? contactInfo; // Optional for anonymous reporters

  Report({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.purok,
    this.status = ReportStatus.pending,
    required this.timestamp,
    required this.reporterId,
    this.assignedToId,
    this.remarks,
    this.resolutionProof,
    this.isSOS = false,
    this.isAnonymous = false,
    this.hasMedia = false,
    this.metadataValid = true,
    this.isPotentialDuplicate = false,
    this.riskScore = RiskLevel.low,
    List<String>? confirmations,
    this.contactInfo,
  }) : confirmations = confirmations ?? [];
}
