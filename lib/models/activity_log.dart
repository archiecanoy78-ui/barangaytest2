class ActivityLog {
  final String id;
  final DateTime timestamp;
  final String user;
  final String action;
  final String complaintId;
  final String description;

  ActivityLog({
    required this.id,
    required this.timestamp,
    required this.user,
    required this.action,
    required this.complaintId,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'user': user,
      'action': action,
      'complaintId': complaintId,
      'description': description,
    };
  }

  factory ActivityLog.fromMap(Map<String, dynamic> map) {
    return ActivityLog(
      id: map['id'] ?? '',
      timestamp: map['timestamp'] != null ? DateTime.parse(map['timestamp']) : DateTime.now(),
      user: map['user'] ?? 'Unknown',
      action: map['action'] ?? '',
      complaintId: map['complaintId'] ?? '',
      description: map['description'] ?? '',
    );
  }
}
