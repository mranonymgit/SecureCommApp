import '../entities/access_log_entity.dart';
import '../repositories/access_control_repository.dart';

class GetAccessLogsUseCase {
  final AccessControlRepository repository;

  GetAccessLogsUseCase(this.repository);

  Future<List<AccessLogEntity>> call() async {
    return await repository.getAccessLogs();
  }
}