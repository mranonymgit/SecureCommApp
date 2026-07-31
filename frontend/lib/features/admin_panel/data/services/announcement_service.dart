import '../../../../core/network/api_client.dart';
import '../../domain/entities/announcement_entity.dart';
import '../models/announcement_model.dart';

abstract class AnnouncementService {
  Future<List<AnnouncementModel>> fetchAnnouncements();
  Future<AnnouncementModel> createAnnouncement(AnnouncementEntity announcement);
}

class AnnouncementServiceImpl implements AnnouncementService {
  final ApiClient _apiClient;

  AnnouncementServiceImpl({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  @override
  Future<List<AnnouncementModel>> fetchAnnouncements() async {
    final items = await _apiClient.getList('/api/admin/announcements');
    return items.cast<Map<String, dynamic>>().map(AnnouncementModel.fromJson).toList(growable: false);
  }

  @override
  Future<AnnouncementModel> createAnnouncement(AnnouncementEntity announcement) async {
    final payload = {
      'title': announcement.title,
      'category': announcement.category.toLowerCase(),
      'content': announcement.content,
      'image_url': announcement.imageUrl,
      'is_important': announcement.isImportant,
    };
    final data = await _apiClient.postJson('/api/admin/announcements', payload);
    return AnnouncementModel.fromJson(data);
  }
}
