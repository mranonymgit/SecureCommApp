import 'package:flutter/material.dart';
import '../../domain/entities/news_post.dart';
import '../../domain/usecases/get_news_posts_usecase.dart';
import '../../domain/usecases/react_to_news_usecase.dart';

class HomeController extends ChangeNotifier {
  final GetNewsPostsUseCase getNewsPostsUseCase;
  final ReactToNewsUseCase reactToNewsUseCase;

  HomeController({
    required this.getNewsPostsUseCase,
    required this.reactToNewsUseCase,
  });

  int currentIndex = 1;
  bool isLoading = false;
  List<NewsPost> newsPosts = [];
  String? errorMessage;

  void changeTab(int index) {
    currentIndex = index;
    notifyListeners();
  }

  Future<void> loadNews() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      newsPosts = await getNewsPostsUseCase();
    } catch (e) {
      errorMessage = 'Error al cargar las noticias: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleLike(String postId) async {
    final index = newsPosts.indexWhere((post) => post.id == postId);
    if (index == -1) return;

    final currentPost = newsPosts[index];
    NewsPost updatedPost;

    if (currentPost.userReaction == 'like') {
      updatedPost = currentPost.copyWith(
        likes: currentPost.likes - 1,
        forceNullReaction: true,
      );
    } else {
      final dislikeOffset = currentPost.userReaction == 'dislike' ? 1 : 0;
      updatedPost = currentPost.copyWith(
        likes: currentPost.likes + 1,
        dislikes: currentPost.dislikes - dislikeOffset,
        userReaction: 'like',
      );
    }

    newsPosts[index] = updatedPost;
    notifyListeners();

    try {
      await reactToNewsUseCase(postId, updatedPost.userReaction);
    } catch (e) {
      newsPosts[index] = currentPost;
      notifyListeners();
    }
  }

  Future<void> toggleDislike(String postId) async {
    final index = newsPosts.indexWhere((post) => post.id == postId);
    if (index == -1) return;

    final currentPost = newsPosts[index];
    NewsPost updatedPost;

    if (currentPost.userReaction == 'dislike') {
      updatedPost = currentPost.copyWith(
        dislikes: currentPost.dislikes - 1,
        forceNullReaction: true,
      );
    } else {
      final likeOffset = currentPost.userReaction == 'like' ? 1 : 0;
      updatedPost = currentPost.copyWith(
        dislikes: currentPost.dislikes + 1,
        likes: currentPost.likes - likeOffset,
        userReaction: 'dislike',
      );
    }

    newsPosts[index] = updatedPost;
    notifyListeners();

    try {
      await reactToNewsUseCase(postId, updatedPost.userReaction);
    } catch (e) {
      newsPosts[index] = currentPost;
      notifyListeners();
    }
  }
}