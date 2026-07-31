import '../entities/community_report.dart';
import '../entities/emergency_profile.dart';

abstract class ReportsRepository {
  Future<EmergencyProfile> getEmergencyProfile();
  Future<void> sendSosAlert({required bool active});
  Future<void> createReport(CommunityReport report);
}
