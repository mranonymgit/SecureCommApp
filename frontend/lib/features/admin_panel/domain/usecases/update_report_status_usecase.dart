import '../entities/report_entity.dart';
import '../repositories/reports_repository.dart';

class UpdateReportStatusUseCase {
  final ReportsRepository repository;

  UpdateReportStatusUseCase(this.repository);

  Future<ReportEntity> call(String id, String newStatus) async {
    return await repository.updateReportStatus(id, newStatus);
  }
}