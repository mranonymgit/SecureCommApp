import '../repositories/chat_repository.dart';

class GetChatAISummaryUseCase {
  final ChatRepository repository;

  GetChatAISummaryUseCase(this.repository);

  Future<String> call() async {
    return await repository.getAISummary();
  }
}