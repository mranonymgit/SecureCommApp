import '../entities/announcement_entity.dart';
import '../repositories/announcements_repository.dart';

class CreateAnnouncementUseCase {
  final AnnouncementsRepository repository;

  CreateAnnouncementUseCase(this.repository);

  Future<AnnouncementEntity> call(AnnouncementEntity announcement) async {
    return await repository.createAnnouncement(announcement);
  }
}
