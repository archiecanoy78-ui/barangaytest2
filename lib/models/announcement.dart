class Announcement {
  final String title;
  final String content;
  final DateTime date;
  final String type;
  final String? imageUrl;

  Announcement({
    required this.title,
    required this.content,
    required this.date,
    required this.type,
    this.imageUrl,
  });
}
