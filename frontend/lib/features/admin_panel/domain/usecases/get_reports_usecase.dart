import '../entities/report_entity.dart';
import '../repositories/reports_repository.dart';

class GetReportsUseCase {
  final ReportsRepository repository;

  GetReportsUseCase(this.repository);

  Future<List<ReportEntity>> call() async {
    return await repository.getReports();
  }
}