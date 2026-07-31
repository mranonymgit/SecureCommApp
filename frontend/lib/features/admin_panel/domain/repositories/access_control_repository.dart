import '../entities/access_log_entity.dart';

abstract class AccessControlRepository {
  Future<List<AccessLogEntity>> getAccessLogs();
}