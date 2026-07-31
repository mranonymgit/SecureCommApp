import '../../../../../core/network/api_client.dart';
import '../../domain/entities/news_post.dart';
import '../../domain/repositories/home_repository.dart';
import '../models/news_post_model.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<List<NewsPost>> getNewsPosts() async {
    final items = await _apiClient.getList('/api/admin/announcements');
    return items
        .cast<Map<String, dynamic>>()
        .map(NewsPostModel.fromJson)
        .toList(growable: false);
  }

  @override
  Future<NewsReactionResult> reactToNews(
    String postId,
    String? reaction,
  ) async {
    final data = await _apiClient.postJson(
      '/api/admin/announcements/$postId/reaction',
      {'reaction': reaction},
    );
    return NewsReactionResult(
      likes: (data['likes'] as num?)?.toInt() ?? 0,
      dislikes: (data['dislikes'] as num?)?.toInt() ?? 0,
      userReaction: data['user_reaction']?.toString(),
    );
  }
}
