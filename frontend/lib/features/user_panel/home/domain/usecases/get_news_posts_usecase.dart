import '../entities/news_post.dart';
import '../repositories/home_repository.dart';

class GetNewsPostsUseCase {
  final HomeRepository repository;
  GetNewsPostsUseCase(this.repository);

  Future<List<NewsPost>> call() async => await repository.getNewsPosts();
}
