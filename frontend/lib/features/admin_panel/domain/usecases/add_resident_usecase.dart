import '../entities/resident_entity.dart';
import '../repositories/residents_repository.dart';

class AddResidentUseCase {
  final ResidentsRepository repository;

  AddResidentUseCase(this.repository);

  Future<ResidentEntity> call(ResidentEntity resident) async {
    return await repository.addResident(resident);
  }
}