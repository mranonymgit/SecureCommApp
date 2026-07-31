import '../entities/incidencia.dart';

abstract class MapsRepository {
  Future<List<Incidencia>> getIncidencias();
  Future<Incidencia> updateIncidenciaStatus(String id, EstadoIncidencia estado);
}
