import '../entities/report_entity.dart';

abstract class ReportsRepository {
  Future<List<ReportEntity>> getReports();
  Future<ReportEntity> updateReportStatus(String id, String newStatus);
}