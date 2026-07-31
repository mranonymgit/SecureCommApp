import '../../../../../core/network/api_client.dart';
import '../../domain/entities/community_report.dart';
import '../../domain/entities/emergency_profile.dart';
import '../../domain/repositories/reports_repository.dart';
import '../models/community_report_model.dart';
import '../models/emergency_profile_model.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final ApiClient _apiClient;

  ReportsRepositoryImpl({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  @override
  Future<EmergencyProfile> getEmergencyProfile() async {
    final data = await _apiClient.getJson('/api/me/emergency-profile');
    return EmergencyProfileModel.fromJson(data);
  }

  @override
  Future<void> sendSosAlert({required bool active}) async {
    await _apiClient.postJson('/api/me/sos', {'active': active});
  }

  @override
  Future<void> createReport(CommunityReport report) async {
    final payload = CommunityReportModel(
      id: report.id,
      title: report.title,
      description: report.description,
      latitude: report.latitude,
      longitude: report.longitude,
      imageBytes: report.imageBytes,
      imagePath: report.imagePath,
    ).toJson();

    final evidenceUri = report.imagePath == null
        ? null
        : Uri.tryParse(report.imagePath!);
    if (evidenceUri != null &&
        evidenceUri.hasScheme &&
        (evidenceUri.scheme == 'https' || evidenceUri.scheme == 'http')) {
      payload['evidence_url'] = report.imagePath;
    }

    await _apiClient.postJson('/api/admin/reports', payload);
  }
}
