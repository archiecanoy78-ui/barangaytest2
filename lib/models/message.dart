class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String recipientPosition; // e.g., 'Barangay Captain'
  final String content;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.recipientPosition,
    required this.content,
    required this.timestamp,
  });
}
