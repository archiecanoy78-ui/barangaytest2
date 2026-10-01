import 'package:cloud_firestore/cloud_firestore.dart';

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
  final String? body;
  final String? category;
  final String? authorId;
  final String? authorName;
  final String? authorRole;
  final bool isPinned;

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
    this.body,
    this.category,
    this.authorId,
    this.authorName,
    this.authorRole,
    this.isPinned = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'content': body ?? content,
      'body': body ?? content,
      'date': date.toIso8601String(),
      'createdAt': Timestamp.fromDate(date),
      'type': category ?? type,
      'category': category ?? type,
      'priority': priority,
      'zone': zone,
      'status': status,
      'imageUrl': imageUrl,
      'authorId': authorId,
      'authorName': authorName,
      'authorRole': authorRole,
      'isPinned': isPinned,
    };
  }

  factory Announcement.fromMap(Map<String, dynamic> map, [String? docId]) {
    final title = map['title'] ?? '';
    final body = map['body'] ?? map['content'] ?? '';
    final category = map['category'] ?? map['type'] ?? 'General Notice';
    
    DateTime parsedDate = DateTime.now();
    final rawDate = map['createdAt'] ?? map['date'];
    if (rawDate != null) {
      if (rawDate is Timestamp) {
        parsedDate = rawDate.toDate();
      } else {
        parsedDate = DateTime.tryParse(rawDate.toString()) ?? DateTime.now();
      }
    }

    return Announcement(
      id: docId ?? map['id'],
      title: title,
      content: body,
      body: body,
      date: parsedDate,
      type: category,
      category: category,
      priority: map['priority'] ?? 'Normal',
      zone: map['zone'] ?? 'All Zones',
      status: map['status'] ?? 'Active',
      imageUrl: map['imageUrl'],
      authorId: map['authorId'],
      authorName: map['authorName'],
      authorRole: map['authorRole'],
      isPinned: map['isPinned'] ?? false,
    );
  }
}
