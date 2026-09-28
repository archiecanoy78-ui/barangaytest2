class Announcement {
  final String? id;
  final String title;
  final String content;
  final DateTime date;
  final String type;
  final String priority;
  final String zone;
  final String status;
  final String? imageUrl;

  Announcement({
    this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.type,
    this.priority = 'Normal',
    this.zone = 'All Zones',
    this.status = 'Active',
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'type': type,
      'priority': priority,
      'zone': zone,
      'status': status,
      'imageUrl': imageUrl,
    };
  }

  factory Announcement.fromMap(Map<String, dynamic> map, [String? docId]) {
    return Announcement(
      id: docId ?? map['id'],
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      date: map['date'] != null ? DateTime.tryParse(map['date']) ?? DateTime.now() : DateTime.now(),
      type: map['type'] ?? 'Announcement',
      priority: map['priority'] ?? 'Normal',
      zone: map['zone'] ?? 'All Zones',
      status: map['status'] ?? 'Active',
      imageUrl: map['imageUrl'],
    );
  }
}

