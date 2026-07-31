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

    if (report.imageBytes != null) {
      final filename = _filename(report.imagePath);
      final upload = await _apiClient.uploadBytes(
        '/api/storage/report-evidence',
        bytes: report.imageBytes!,
        filename: filename,
        contentType: _imageContentType(filename),
      );
      payload['evidence_url'] = upload['object_path'];
    }

    await _apiClient.postJson('/api/admin/reports', payload);
  }

  String _filename(String? path) {
    final candidate = path?.split('/').last.split('\\').last;
    return candidate == null || !candidate.contains('.')
        ? 'evidence.jpg'
        : candidate;
  }

  String _imageContentType(String filename) {
    final extension = filename.toLowerCase().split('.').last;
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }
}
