class AdminDashboardStatsEntity {
  final int totalResidents;
  final int activeVisitsToday;
  final int pendingReports;
  final int activeAlerts;

  const AdminDashboardStatsEntity({
    required this.totalResidents,
    required this.activeVisitsToday,
    required this.pendingReports,
    required this.activeAlerts,
  });
}
