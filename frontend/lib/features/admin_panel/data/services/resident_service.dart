import '../../../../core/network/api_client.dart';
import '../../domain/entities/resident_entity.dart';
import '../models/resident_model.dart';

abstract class ResidentService {
  Future<List<ResidentModel>> fetchResidents();
  Future<ResidentModel> createResident(ResidentEntity resident);
}

class ResidentServiceImpl implements ResidentService {
  final ApiClient _apiClient;

  ResidentServiceImpl({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  @override
  Future<List<ResidentModel>> fetchResidents() async {
    final items = await _apiClient.getList('/api/admin/residents');
    return items.cast<Map<String, dynamic>>().map(ResidentModel.fromJson).toList(growable: false);
  }

  @override
  Future<ResidentModel> createResident(ResidentEntity resident) async {
    final payload = {
      'full_name': resident.name,
      'email': resident.email,
      'phone': resident.phone,
      'initial_password': resident.tempPassword,
      'unit_label': resident.unit,
      'blood_type': resident.bloodType,
      'conditions': resident.illnesses,
      'allergies': resident.allergies,
      'emergency_contact_name': resident.emergencyContact,
      'emergency_contact_phone': resident.phone,
    };
    final data = await _apiClient.postJson('/api/admin/residents', payload);
    return ResidentModel.fromJson(data);
  }
}
