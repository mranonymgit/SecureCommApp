import '../repositories/home_repository.dart';

class ReactToNewsUseCase {
  final HomeRepository repository;
  ReactToNewsUseCase(this.repository);

  Future<void> call(String postId, String? reaction) async {
    await repository.reactToNews(postId, reaction);
  }
}