import '../../domain/entities/community_report.dart';

class CommunityReportModel extends CommunityReport {
  const CommunityReportModel({
    super.id,
    required super.title,
    required super.description,
    required super.latitude,
    required super.longitude,
    super.imageBytes,
    super.imagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
