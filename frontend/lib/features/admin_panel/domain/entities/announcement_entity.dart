class AnnouncementEntity {
  final String id;
  final String title;
  final String category;
  final String date;
  final String author;
  final String content;
  final String? imageUrl;
  final bool isImportant;

  const AnnouncementEntity({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.author,
    required this.content,
    this.imageUrl,
    required this.isImportant,
  });
}