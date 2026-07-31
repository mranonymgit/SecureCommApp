import '../entities/chat_message_entity.dart';
import '../repositories/chat_repository.dart';

class GetChatMessagesUseCase {
  final ChatRepository repository;

  GetChatMessagesUseCase(this.repository);

  Future<List<ChatMessageEntity>> call() async {
    return await repository.getMessages();
  }
}