import '../../domain/entities/report_entity.dart';
import '../../domain/repositories/reports_repository.dart';
import '../services/report_service.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final ReportService service;

  ReportsRepositoryImpl({ReportService? service})
    : service = service ?? ReportServiceImpl();

  @override
  Future<List<ReportEntity>> getReports() async {
    return await service.fetchReports();
  }

  @override
  Future<ReportEntity> updateReportStatus(String id, String newStatus) async {
    return await service.updateReportStatus(id, newStatus);
  }
}
