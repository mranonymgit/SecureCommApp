import '../../../../core/network/api_client.dart';
import '../models/access_log_model.dart';

abstract class VisitService {
  Future<List<AccessLogModel>> fetchAccessLogs();
}

class VisitServiceImpl implements VisitService {
  final ApiClient _apiClient;

  VisitServiceImpl({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  @override
  Future<List<AccessLogModel>> fetchAccessLogs() async {
    final items = await _apiClient.getList('/api/admin/access-logs');
    return items.cast<Map<String, dynamic>>().map(AccessLogModel.fromJson).toList(growable: false);
  }
}
