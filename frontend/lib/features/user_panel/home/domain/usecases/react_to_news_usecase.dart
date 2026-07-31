import '../entities/news_post.dart';
import '../repositories/home_repository.dart';

class ReactToNewsUseCase {
  final HomeRepository repository;
  ReactToNewsUseCase(this.repository);

  Future<NewsReactionResult> call(String postId, String? reaction) async {
    return repository.reactToNews(postId, reaction);
  }
}
