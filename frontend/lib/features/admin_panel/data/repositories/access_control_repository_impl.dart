import '../../domain/entities/access_log_entity.dart';
import '../../domain/repositories/access_control_repository.dart';
import '../models/access_log_model.dart';
import '../services/visit_service.dart';

class AccessControlRepositoryImpl implements AccessControlRepository {
  final VisitService service;

  AccessControlRepositoryImpl({VisitService? service})
      : service = service ?? VisitServiceImpl();

  @override
  Future<List<AccessLogEntity>> getAccessLogs() async {
    final logs = await service.fetchAccessLogs();
    return logs
        .map(
          (log) => AccessLogModel(
            id: log.id,
            visitor: log.visitor,
            resident: log.resident,
            time: log.time,
            type: log.type,
            status: log.status,
            plate: log.plate,
            qrCode: log.qrCode,
            entryGuard: log.entryGuard,
          ),
        )
        .toList(growable: false);
  }
}
