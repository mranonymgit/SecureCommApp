import '../entities/admin_dashboard_stats_entity.dart';

abstract class AdminOverviewRepository {
  Future<AdminDashboardStatsEntity> getDashboardStats();
}