class ChatMessageEntity {
  final String id;
  final String sender;
  final String? avatarUrl;
  final String text;
  final String? audioDuration;
  final String time;
  final DateTime date;
  final bool isAdmin;
  final bool isAudio;

  const ChatMessageEntity({
    required this.id,
    required this.sender,
    this.avatarUrl,
    required this.text,
    this.audioDuration,
    required this.time,
    required this.date,
    required this.isAdmin,
    required this.isAudio,
  });
}