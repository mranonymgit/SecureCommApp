import '../entities/chat_message_entity.dart';
import '../repositories/chat_repository.dart';

class SendChatMessageUseCase {
  final ChatRepository repository;

  SendChatMessageUseCase(this.repository);

  Future<ChatMessageEntity> call(ChatMessageEntity message) async {
    return await repository.sendMessage(message);
  }
}