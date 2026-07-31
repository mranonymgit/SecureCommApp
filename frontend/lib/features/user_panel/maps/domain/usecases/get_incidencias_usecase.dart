import '../entities/incidencia.dart';
import '../repositories/maps_repository.dart';

class GetIncidenciasUseCase {
  final MapsRepository repository;
  GetIncidenciasUseCase(this.repository);

  Future<List<Incidencia>> call() async => await repository.getIncidencias();
}