import '../entities/announcement_entity.dart';
import '../repositories/announcements_repository.dart';

class GetAnnouncementsUseCase {
  final AnnouncementsRepository repository;

  GetAnnouncementsUseCase(this.repository);

  Future<List<AnnouncementEntity>> call() async {
    return await repository.getAnnouncements();
  }
}
