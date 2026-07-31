import '../entities/chat_message_entity.dart';

abstract class ChatRepository {
  Future<List<ChatMessageEntity>> getMessages();
  Future<ChatMessageEntity> sendMessage(ChatMessageEntity message);
  Future<String> getAISummary();
}
