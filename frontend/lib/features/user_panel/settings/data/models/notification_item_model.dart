import '../../domain/entities/notification_item.dart';

class NotificationItemModel extends NotificationItem {
  const NotificationItemModel({
    required super.id,
    required super.title,
    required super.message,
    required super.time,
    super.isRead,
    super.sourceType,
  });

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    return NotificationItemModel(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      time: (json['time'] ?? json['created_at'] ?? '').toString(),
      isRead: json['is_read'] as bool? ?? json['isRead'] as bool? ?? false,
      sourceType: (json['source_type'] ?? json['sourceType'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'time': time,
      'isRead': isRead,
      'sourceType': sourceType,
    };
  }
}
