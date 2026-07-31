import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../../core/services/community_realtime_service.dart';
import '../../../../../core/network/api_error_message.dart';
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
  StreamSubscription<CommunityChange>? _realtimeSubscription;
  final Set<String> _pendingReactions = <String>{};

  bool isReactionPending(String postId) => _pendingReactions.contains(postId);

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
      errorMessage = 'No fue posible cargar los avisos.';
      debugPrint('Error al cargar avisos: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void connectRealtime() {
    _realtimeSubscription ??= CommunityRealtimeService.instance
        .watchTables(const {'announcements', 'announcement_reactions'})
        .listen((_) => unawaited(refreshNewsSilently()));
  }

  Future<void> refreshNewsSilently() async {
    try {
      newsPosts = await getNewsPostsUseCase();
      errorMessage = null;
      notifyListeners();
    } catch (_) {
      // Preserve the last valid feed during transient network failures.
    }
  }

  Future<String?> toggleLike(String postId) async {
    if (!_pendingReactions.add(postId)) return null;
    final index = newsPosts.indexWhere((post) => post.id == postId);
    if (index == -1) {
      _pendingReactions.remove(postId);
      return 'El aviso ya no está disponible.';
    }

    final currentPost = newsPosts[index];
    NewsPost updatedPost;

    if (currentPost.userReaction == 'like') {
      updatedPost = currentPost.copyWith(
        likes: (currentPost.likes - 1).clamp(0, 1 << 31),
        forceNullReaction: true,
      );
    } else {
      final dislikeOffset = currentPost.userReaction == 'dislike' ? 1 : 0;
      updatedPost = currentPost.copyWith(
        likes: currentPost.likes + 1,
        dislikes: (currentPost.dislikes - dislikeOffset).clamp(0, 1 << 31),
        userReaction: 'like',
      );
    }

    newsPosts[index] = updatedPost;
    notifyListeners();

    try {
      final result = await reactToNewsUseCase(postId, updatedPost.userReaction);
      final currentIndex = newsPosts.indexWhere((post) => post.id == postId);
      if (currentIndex != -1) {
        newsPosts[currentIndex] = newsPosts[currentIndex].copyWith(
          likes: result.likes,
          dislikes: result.dislikes,
          userReaction: result.userReaction,
          forceNullReaction: result.userReaction == null,
        );
      }
      notifyListeners();
      return null;
    } catch (error) {
      final currentIndex = newsPosts.indexWhere((post) => post.id == postId);
      if (currentIndex != -1) newsPosts[currentIndex] = currentPost;
      notifyListeners();
      return ApiErrorMessage.from(
        error,
        fallback: 'No fue posible registrar tu reacción.',
      );
    } finally {
      _pendingReactions.remove(postId);
      notifyListeners();
    }
  }

  Future<String?> toggleDislike(String postId) async {
    if (!_pendingReactions.add(postId)) return null;
    final index = newsPosts.indexWhere((post) => post.id == postId);
    if (index == -1) {
      _pendingReactions.remove(postId);
      return 'El aviso ya no está disponible.';
    }

    final currentPost = newsPosts[index];
    NewsPost updatedPost;

    if (currentPost.userReaction == 'dislike') {
      updatedPost = currentPost.copyWith(
        dislikes: (currentPost.dislikes - 1).clamp(0, 1 << 31),
        forceNullReaction: true,
      );
    } else {
      final likeOffset = currentPost.userReaction == 'like' ? 1 : 0;
      updatedPost = currentPost.copyWith(
        dislikes: currentPost.dislikes + 1,
        likes: (currentPost.likes - likeOffset).clamp(0, 1 << 31),
        userReaction: 'dislike',
      );
    }

    newsPosts[index] = updatedPost;
    notifyListeners();

    try {
      final result = await reactToNewsUseCase(postId, updatedPost.userReaction);
      final currentIndex = newsPosts.indexWhere((post) => post.id == postId);
      if (currentIndex != -1) {
        newsPosts[currentIndex] = newsPosts[currentIndex].copyWith(
          likes: result.likes,
          dislikes: result.dislikes,
          userReaction: result.userReaction,
          forceNullReaction: result.userReaction == null,
        );
      }
      notifyListeners();
      return null;
    } catch (error) {
      final currentIndex = newsPosts.indexWhere((post) => post.id == postId);
      if (currentIndex != -1) newsPosts[currentIndex] = currentPost;
      notifyListeners();
      return ApiErrorMessage.from(
        error,
        fallback: 'No fue posible registrar tu reacción.',
      );
    } finally {
      _pendingReactions.remove(postId);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }
}
