import '../entities/resident_entity.dart';

abstract class ResidentsRepository {
  Future<List<ResidentEntity>> getResidents();
  Future<ResidentEntity> addResident(ResidentEntity resident);
}
