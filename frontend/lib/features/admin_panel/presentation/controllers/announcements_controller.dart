import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/community_realtime_service.dart';
import '../../../../core/network/api_error_message.dart';
import '../../domain/entities/announcement_entity.dart';
import '../../domain/usecases/create_announcement_usecase.dart';
import '../../domain/usecases/get_announcements_usecase.dart';

class AnnouncementsController extends ChangeNotifier {
  final GetAnnouncementsUseCase getAnnouncementsUseCase;
  final CreateAnnouncementUseCase createAnnouncementUseCase;

  AnnouncementsController({
    required this.getAnnouncementsUseCase,
    required this.createAnnouncementUseCase,
  });

  List<AnnouncementEntity> _announcements = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _actionErrorMessage;
  StreamSubscription<CommunityChange>? _realtimeSubscription;

  List<AnnouncementEntity> get announcements => _announcements;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  String? get actionErrorMessage => _actionErrorMessage;

  Future<void> fetchAnnouncements() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _announcements = await getAnnouncementsUseCase();
    } catch (e) {
      _announcements = [];
      _errorMessage = 'No fue posible cargar los comunicados.';
      debugPrint('Error al cargar comunicados: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void connectRealtime() {
    _realtimeSubscription ??= CommunityRealtimeService.instance
        .watchTables(const {'announcements', 'announcement_reactions'})
        .listen((_) => unawaited(refreshAnnouncementsSilently()));
  }

  Future<void> refreshAnnouncementsSilently() async {
    try {
      _announcements = await getAnnouncementsUseCase();
      _errorMessage = null;
      notifyListeners();
    } catch (_) {
      // Do not replace a valid list with a full-screen error.
    }
  }

  Future<bool> addAnnouncement({
    required String title,
    required String category,
    required String content,
    String? imageUrl,
    String? linkUrl,
    required bool isImportant,
  }) async {
    final newAnnouncement = AnnouncementEntity(
      id: '',
      title: title,
      category: category,
      date: '',
      author: '',
      content: content,
      imageUrl: imageUrl,
      linkUrl: linkUrl,
      isImportant: isImportant,
    );

    try {
      final created = await createAnnouncementUseCase(newAnnouncement);
      _announcements = [
        created,
        ..._announcements.where((item) => item.id != created.id),
      ];
      _actionErrorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      try {
        final canonical = await getAnnouncementsUseCase();
        final saved = canonical.any(
          (item) => item.title == title && item.content == content,
        );
        if (saved) {
          _announcements = canonical;
          _actionErrorMessage = null;
          notifyListeners();
          return true;
        }
      } catch (_) {}
      _actionErrorMessage = ApiErrorMessage.from(
        error,
        fallback: 'No fue posible publicar el comunicado.',
      );
      debugPrint('Error al crear comunicado: $error');
      notifyListeners();
      return false;
    }
  }

  Future<String?> uploadImage(Uint8List bytes, String filename) async {
    try {
      final lower = filename.toLowerCase();
      final contentType = lower.endsWith('.png')
          ? 'image/png'
          : lower.endsWith('.webp')
          ? 'image/webp'
          : 'image/jpeg';
      final data = await ApiClient().uploadBytes(
        '/api/storage/announcement-image',
        bytes: bytes,
        filename: filename,
        contentType: contentType,
      );
      return (data['object_path'] ?? '').toString();
    } catch (error) {
      _actionErrorMessage = ApiErrorMessage.from(
        error,
        fallback: 'No fue posible adjuntar la imagen.',
      );
      notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }
}
