import '../../domain/entities/admin_dashboard_stats_entity.dart';

class AdminDashboardStatsModel extends AdminDashboardStatsEntity {
  const AdminDashboardStatsModel({
    required super.totalResidents,
    required super.activeVisitsToday,
    required super.pendingReports,
    required super.activeAlerts,
  });

  factory AdminDashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardStatsModel(
      totalResidents: json['totalResidents'] ?? json['total_residents'] ?? 0,
      activeVisitsToday:
          json['activeVisitsToday'] ?? json['active_visits_today'] ?? 0,
      pendingReports: json['pendingReports'] ?? json['pending_reports'] ?? 0,
      activeAlerts: json['activeAlerts'] ?? json['active_alerts'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalResidents': totalResidents,
      'activeVisitsToday': activeVisitsToday,
      'pendingReports': pendingReports,
      'activeAlerts': activeAlerts,
    };
  }
}
