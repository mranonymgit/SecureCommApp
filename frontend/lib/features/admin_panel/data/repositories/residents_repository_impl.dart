import '../../domain/entities/resident_entity.dart';
import '../../domain/repositories/residents_repository.dart';
import '../models/resident_model.dart';
import '../services/resident_service.dart';

class ResidentsRepositoryImpl implements ResidentsRepository {
  final ResidentService service;

  ResidentsRepositoryImpl({ResidentService? service})
      : service = service ?? ResidentServiceImpl();

  @override
  Future<List<ResidentEntity>> getResidents() async {
    final residents = await service.fetchResidents();
    return residents
        .map(
          (resident) => ResidentModel(
            id: resident.id,
            tempPassword: resident.tempPassword,
            name: resident.name,
            unit: resident.unit,
            bloodType: resident.bloodType,
            illnesses: resident.illnesses,
            allergies: resident.allergies,
            emergencyContact: resident.emergencyContact,
            email: resident.email,
            phone: resident.phone,
            avatarUrl: resident.avatarUrl,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<ResidentEntity> addResident(ResidentEntity resident) async {
    final created = await service.createResident(resident);
    return ResidentModel(
      id: created.id,
      tempPassword: created.tempPassword,
      name: created.name,
      unit: created.unit,
      bloodType: created.bloodType,
      illnesses: created.illnesses,
      allergies: created.allergies,
      emergencyContact: created.emergencyContact,
      email: created.email,
      phone: created.phone,
      avatarUrl: created.avatarUrl,
    );
  }
}
