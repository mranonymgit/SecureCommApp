import '../entities/resident_entity.dart';
import '../repositories/residents_repository.dart';

class GetResidentsUseCase {
  final ResidentsRepository repository;

  GetResidentsUseCase(this.repository);

  Future<List<ResidentEntity>> call() async {
    return await repository.getResidents();
  }
}
