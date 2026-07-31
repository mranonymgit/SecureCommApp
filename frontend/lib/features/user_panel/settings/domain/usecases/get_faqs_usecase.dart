import '../entities/faq_item.dart';
import '../repositories/settings_repository.dart';

class GetFaqsUseCase {
  final SettingsRepository repository;

  GetFaqsUseCase(this.repository);

  Future<List<FaqItem>> call() async {
    return await repository.getFaqs();
  }

  Future<void> submitQuestion(String question) async {
    if (question.trim().isEmpty) {
      throw Exception('La pregunta no puede estar vacía.');
    }
    return await repository.submitFaqQuestion(question);
  }
}