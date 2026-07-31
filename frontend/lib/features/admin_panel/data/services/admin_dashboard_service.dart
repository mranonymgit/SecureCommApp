import '../../../../core/network/api_client.dart';
import '../models/admin_dashboard_stats_model.dart';

abstract class AdminDashboardService {
  Future<AdminDashboardStatsModel> fetchDashboardStats();
}

class AdminDashboardServiceImpl implements AdminDashboardService {
  final ApiClient _apiClient;

  AdminDashboardServiceImpl({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  @override
  Future<AdminDashboardStatsModel> fetchDashboardStats() async {
    final data = await _apiClient.getJson('/api/admin/dashboard/stats');
    return AdminDashboardStatsModel.fromJson(data);
  }
}
