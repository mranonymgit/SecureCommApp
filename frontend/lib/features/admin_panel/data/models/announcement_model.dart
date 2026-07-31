import '../../domain/entities/announcement_entity.dart';

class AnnouncementModel extends AnnouncementEntity {
  const AnnouncementModel({
    required super.id,
    required super.title,
    required super.category,
    required super.date,
    required super.author,
    required super.content,
    super.imageUrl,
    required super.isImportant,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      category: (json['category'] ?? 'general').toString(),
      date: (json['date'] ?? json['created_at'] ?? '').toString(),
      author: (json['author'] ?? json['author_name'] ?? 'Administración').toString(),
      content: (json['content'] ?? '').toString(),
      imageUrl: json['imageUrl'] ?? json['image_url'],
      isImportant: json['isImportant'] ?? json['is_important'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'date': date,
      'author': author,
      'content': content,
      'imageUrl': imageUrl,
      'isImportant': isImportant,
    };
  }
}
