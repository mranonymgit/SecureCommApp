import '../entities/community_report.dart';
import '../repositories/reports_repository.dart';

class CreateReportUseCase {
  final ReportsRepository repository;
  CreateReportUseCase(this.repository);

  Future<void> call(CommunityReport report) async {
    if (report.title.trim().isEmpty) throw Exception('El título no puede estar vacío.');
    if (report.description.trim().isEmpty) throw Exception('La descripción no puede estar vacía.');
    if (report.imageBytes == null && (report.imagePath == null || report.imagePath!.isEmpty)) {
      throw Exception('Debes adjuntar una imagen de evidencia.');
    }
    await repository.createReport(report);
  }
}