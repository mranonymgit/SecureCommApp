import '../entities/admin_dashboard_stats_entity.dart';
import '../repositories/admin_overview_repository.dart';

class GetAdminDashboardStatsUseCase {
  final AdminOverviewRepository repository;

  GetAdminDashboardStatsUseCase(this.repository);

  Future<AdminDashboardStatsEntity> call() async {
    return await repository.getDashboardStats();
  }
}
