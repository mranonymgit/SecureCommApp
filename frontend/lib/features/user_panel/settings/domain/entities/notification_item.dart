class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    String? time,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      time: time ?? this.time,
      isRead: isRead ?? this.isRead,
    );
  }
}