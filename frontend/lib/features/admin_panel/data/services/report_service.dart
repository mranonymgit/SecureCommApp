import '../../../../core/network/api_client.dart';
import '../models/report_model.dart';

abstract class ReportService {
  Future<List<ReportModel>> fetchReports();
  Future<ReportModel> updateReportStatus(String id, String newStatus);
}

class ReportServiceImpl implements ReportService {
  final ApiClient _apiClient;

  ReportServiceImpl({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  @override
  Future<List<ReportModel>> fetchReports() async {
    final items = await _apiClient.getList('/api/admin/reports');
    return items.cast<Map<String, dynamic>>().map(ReportModel.fromJson).toList(growable: false);
  }

  @override
  Future<ReportModel> updateReportStatus(String id, String newStatus) async {
    final data = await _apiClient.patchJson('/api/admin/reports/$id/status', {'status': newStatus.toLowerCase()});
    return ReportModel.fromJson(data);
  }
}
