import '../../../../../core/network/api_client.dart';
import '../../domain/entities/incidencia.dart';
import '../../domain/repositories/maps_repository.dart';
import '../models/incidencia_model.dart';

class MapsRepositoryImpl implements MapsRepository {
  MapsRepositoryImpl({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  @override
  Future<List<Incidencia>> getIncidencias() async {
    final items = await _apiClient.getList('/api/admin/reports');
    return items
        .cast<Map<String, dynamic>>()
        .where((item) => item['latitude'] != null && item['longitude'] != null)
        .map(IncidenciaModel.fromJson)
        .toList(growable: false);
  }

  @override
  Future<Incidencia> updateIncidenciaStatus(
    String id,
    EstadoIncidencia estado,
  ) async {
    final data = await _apiClient.patchJson('/api/admin/reports/$id/status', {
      'status': estado.apiValue,
    });
    return IncidenciaModel.fromJson(data);
  }
}
