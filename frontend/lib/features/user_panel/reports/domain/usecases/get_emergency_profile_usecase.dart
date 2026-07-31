import '../entities/emergency_profile.dart';
import '../repositories/reports_repository.dart';

class GetEmergencyProfileUseCase {
  final ReportsRepository repository;
  GetEmergencyProfileUseCase(this.repository);

  Future<EmergencyProfile> call() async => await repository.getEmergencyProfile();
}