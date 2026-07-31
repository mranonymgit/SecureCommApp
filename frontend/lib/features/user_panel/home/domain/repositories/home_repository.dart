import '../entities/news_post.dart';

abstract class HomeRepository {
  Future<List<NewsPost>> getNewsPosts();
  Future<void> reactToNews(String postId, String? reaction);
}