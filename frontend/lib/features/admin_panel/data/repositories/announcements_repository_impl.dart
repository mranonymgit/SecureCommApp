import '../../domain/entities/announcement_entity.dart';
import '../../domain/repositories/announcements_repository.dart';
import '../models/announcement_model.dart';
import '../services/announcement_service.dart';

class AnnouncementsRepositoryImpl implements AnnouncementsRepository {
  final AnnouncementService service;

  AnnouncementsRepositoryImpl({AnnouncementService? service})
      : service = service ?? AnnouncementServiceImpl();

  @override
  Future<List<AnnouncementEntity>> getAnnouncements() async {
    final announcements = await service.fetchAnnouncements();
    return announcements
        .map(
          (announcement) => AnnouncementModel(
            id: announcement.id,
            title: announcement.title,
            category: announcement.category,
            date: announcement.date,
            author: announcement.author,
            content: announcement.content,
            imageUrl: announcement.imageUrl,
            isImportant: announcement.isImportant,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<AnnouncementEntity> createAnnouncement(AnnouncementEntity announcement) async {
    final created = await service.createAnnouncement(announcement);
    return AnnouncementModel(
      id: created.id,
      title: created.title,
      category: created.category,
      date: created.date,
      author: created.author,
      content: created.content,
      imageUrl: created.imageUrl,
      isImportant: created.isImportant,
    );
  }
}
