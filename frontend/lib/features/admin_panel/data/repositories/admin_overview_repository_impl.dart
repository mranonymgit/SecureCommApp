import '../../domain/entities/admin_dashboard_stats_entity.dart';
import '../../domain/repositories/admin_overview_repository.dart';
import '../models/admin_dashboard_stats_model.dart';
import '../services/admin_dashboard_service.dart';

class AdminOverviewRepositoryImpl implements AdminOverviewRepository {
  final AdminDashboardService service;

  AdminOverviewRepositoryImpl({AdminDashboardService? service})
    : service = service ?? AdminDashboardServiceImpl();

  @override
  Future<AdminDashboardStatsEntity> getDashboardStats() async {
    final stats = await service.fetchDashboardStats();
    return AdminDashboardStatsModel(
      totalResidents: stats.totalResidents,
      activeVisitsToday: stats.activeVisitsToday,
      pendingReports: stats.pendingReports,
      activeAlerts: stats.activeAlerts,
    );
  }
}
