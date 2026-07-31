import '../entities/announcement_entity.dart';

abstract class AnnouncementsRepository {
  Future<List<AnnouncementEntity>> getAnnouncements();
  Future<AnnouncementEntity> createAnnouncement(
    AnnouncementEntity announcement,
  );
}
