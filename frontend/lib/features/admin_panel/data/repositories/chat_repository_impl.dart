import '../../domain/entities/chat_message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/chat_message_model.dart';
import '../services/chat_service.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatService service;

  ChatRepositoryImpl({ChatService? service})
    : service = service ?? ChatServiceImpl();

  @override
  Future<List<ChatMessageEntity>> getMessages() async {
    final messages = await service.fetchMessages();
    return messages
        .map(
          (message) => ChatMessageModel(
            id: message.id,
            sender: message.sender,
            avatarUrl: message.avatarUrl,
            text: message.text,
            audioDuration: message.audioDuration,
            audioUrl: message.audioUrl,
            time: message.time,
            date: message.date,
            isAdmin: message.isAdmin,
            isAudio: message.isAudio,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<ChatMessageEntity> sendMessage(ChatMessageEntity message) async {
    final sent = await service.sendMessage(message);
    return ChatMessageModel(
      id: sent.id,
      sender: sent.sender,
      avatarUrl: sent.avatarUrl,
      text: sent.text,
      audioDuration: sent.audioDuration,
      audioUrl: sent.audioUrl,
      time: sent.time,
      date: sent.date,
      isAdmin: sent.isAdmin,
      isAudio: sent.isAudio,
    );
  }

  @override
  Future<String> getAISummary() async {
    return service.fetchAISummary();
  }
}
