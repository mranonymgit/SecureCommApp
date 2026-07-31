import '../../domain/entities/chat_message_entity.dart';

class ChatMessageModel extends ChatMessageEntity {
  const ChatMessageModel({
    required super.id,
    required super.sender,
    super.avatarUrl,
    required super.text,
    super.audioDuration,
    required super.time,
    required super.date,
    required super.isAdmin,
    required super.isAudio,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final timestamp = json['date'] ?? json['created_at'];
    final parsedTimestamp = timestamp == null
        ? null
        : DateTime.tryParse(timestamp.toString());
    final audioUrl = json['audio_url'] ?? json['audioUrl'];
    if (parsedTimestamp == null) {
      throw FormatException('Chat message is missing a valid timestamp.');
    }
    return ChatMessageModel(
      id: (json['id'] ?? '').toString(),
      sender:
          (json['nombre_usuario'] ??
                  json['sender_name'] ??
                  json['sender'] ??
                  '')
              .toString(),
      avatarUrl: json['avatarUrl'] ?? json['avatar_url'],
      text: (json['text'] ?? json['body'] ?? '').toString(),
      audioDuration: json['audioDuration'] ?? json['audio_duration'],
      time:
          '${parsedTimestamp.toLocal().hour.toString().padLeft(2, '0')}:${parsedTimestamp.toLocal().minute.toString().padLeft(2, '0')}',
      date: parsedTimestamp.toLocal(),
      isAdmin: json['isAdmin'] ?? json['is_admin'] ?? false,
      isAudio: json['isAudio'] ?? json['is_audio'] ?? audioUrl != null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'avatarUrl': avatarUrl,
      'text': text,
      'audioDuration': audioDuration,
      'time': time,
      'date': date.toIso8601String(),
      'isAdmin': isAdmin,
      'isAudio': isAudio,
    };
  }
}
