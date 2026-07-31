import 'package:flutter/material.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/admin_panel/domain/entities/admin_dashboard_stats_entity.dart';
import 'package:frontend/features/admin_panel/domain/entities/resident_entity.dart';
import 'package:frontend/features/admin_panel/domain/repositories/admin_overview_repository.dart';
import 'package:frontend/features/admin_panel/domain/usecases/get_admin_dashboard_stats_usecase.dart';
import 'package:frontend/features/admin_panel/presentation/controllers/admin_dashboard_controller.dart';
import 'package:frontend/features/auth/domain/entities/user_entity.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:frontend/features/auth/domain/usecases/login_usecase.dart';
import 'package:frontend/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:frontend/features/user_panel/home/domain/entities/news_post.dart';
import 'package:frontend/features/user_panel/home/domain/repositories/home_repository.dart';
import 'package:frontend/features/user_panel/home/domain/usecases/get_news_posts_usecase.dart';
import 'package:frontend/features/user_panel/home/domain/usecases/react_to_news_usecase.dart';
import 'package:frontend/features/user_panel/home/presentation/controllers/home_controller.dart';
import 'package:frontend/features/user_panel/maps/domain/entities/incidencia.dart';
import 'package:frontend/features/user_panel/maps/domain/repositories/maps_repository.dart';
import 'package:frontend/features/user_panel/maps/domain/usecases/get_incidencias_usecase.dart';
import 'package:frontend/features/user_panel/maps/presentation/controllers/maps_controller.dart';
import 'package:frontend/features/user_panel/reports/domain/entities/community_report.dart';
import 'package:frontend/features/user_panel/reports/domain/entities/emergency_profile.dart';
import 'package:frontend/features/user_panel/reports/domain/repositories/reports_repository.dart';
import 'package:frontend/features/user_panel/reports/domain/usecases/create_report_usecase.dart';
import 'package:frontend/features/user_panel/reports/presentation/controllers/create_report_controller.dart';
import 'package:frontend/features/user_panel/settings/domain/entities/notification_item.dart';
import 'package:frontend/features/user_panel/settings/domain/entities/faq_item.dart';
import 'package:frontend/features/user_panel/settings/domain/entities/rule_item.dart';
import 'package:frontend/features/user_panel/settings/domain/entities/user_preferences.dart';
import 'package:frontend/features/user_panel/settings/domain/entities/user_profile.dart';
import 'package:frontend/features/user_panel/settings/domain/repositories/settings_repository.dart';
import 'package:frontend/features/user_panel/settings/domain/usecases/get_notifications_usecase.dart';
import 'package:frontend/features/user_panel/settings/presentation/controllers/notification_controller.dart';
import 'package:latlong2/latlong.dart';
import 'package:frontend/features/user_panel/settings/data/repositories/settings_repository_impl.dart';

class FakeAuthRepository implements AuthRepository {
  UserEntity? user;
  bool resetResult = true;

  @override
  Future<UserEntity?> login(String username, String password) async => user;

  @override
  Future<bool> resetPassword(String username, String newPassword) async =>
      resetResult;
}

class FakeAdminOverviewRepository implements AdminOverviewRepository {
  @override
  Future<AdminDashboardStatsEntity> getDashboardStats() async {
    return const AdminDashboardStatsEntity(
      totalResidents: 42,
      activeVisitsToday: 7,
      pendingReports: 3,
      activeAlerts: 1,
    );
  }
}

class FakeHomeRepository implements HomeRepository {
  List<NewsPost> posts = const [];

  @override
  Future<List<NewsPost>> getNewsPosts() async => posts;

  @override
  Future<NewsReactionResult> reactToNews(String postId, String? reaction) async {
    return NewsReactionResult(
      likes: reaction == 'like' ? 5 : 4,
      dislikes: reaction == 'dislike' ? 2 : 1,
      userReaction: reaction,
    );
  }
}

class FakeMapsRepository implements MapsRepository {
  Incidencia? updated;

  @override
  Future<List<Incidencia>> getIncidencias() async {
    return [
      const Incidencia(
        id: '1',
        titulo: 'Bache',
        descripcion: 'Bache grande en la avenida',
        fecha: '31/07/2026',
        estado: EstadoIncidencia.pendiente,
        ubicacion: LatLng(19.4326, -99.1332),
        reporter: 'Residente 1',
      ),
    ];
  }

  @override
  Future<Incidencia> updateIncidenciaStatus(
    String id,
    EstadoIncidencia estado,
  ) async {
    updated = Incidencia(
      id: id,
      titulo: 'Bache',
      descripcion: 'Bache grande en la avenida',
      fecha: '31/07/2026',
      estado: estado,
      ubicacion: const LatLng(19.4326, -99.1332),
      reporter: 'Residente 1',
    );
    return updated!;
  }
}

class FakeReportsRepository implements ReportsRepository {
  @override
  Future<EmergencyProfile> getEmergencyProfile() async {
    return const EmergencyProfile(
      nombre: 'Juan Pérez',
      edad: 34,
      tipoSangre: 'O+',
      padecimientos: 'Ninguno',
      alergias: 'Ninguna',
      contactoEmergencia: '5551234567',
      direccion: 'Calle Principal 123',
    );
  }

  @override
  Future<void> sendSosAlert({required bool active}) async {}

  @override
  Future<void> createReport(CommunityReport report) async {}
}

class FakeSettingsRepository implements SettingsRepository {
  final List<NotificationItem> notifications = [
    const NotificationItem(
      id: 'n1',
      title: 'Nuevo aviso',
      message: 'Hay un comunicado importante',
      time: '31/07/2026 10:00',
      isRead: false,
      sourceType: 'announcement',
    ),
  ];

  @override
  Future<List<RuleItem>> getCommunityRules() async => [];

  @override
  Future<List<FaqItem>> getFaqs() async => [];

  @override
  Future<List<NotificationItem>> getNotifications() async => notifications;

  @override
  Future<void> submitFaqQuestion(String question) async {}

  @override
  Future<UserProfile> getProfile() async {
    return const UserProfile(
      id: 'u1',
      fullName: 'Residente',
      email: 'residente@example.com',
      phone: '5550000000',
      avatarUrl: null,
    );
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async => profile;

  @override
  Future<UserPreferences> getPreferences() async {
    return const UserPreferences(
      themeMode: 'dark',
      notificationsEnabled: true,
      language: 'es',
    );
  }

  @override
  Future<UserPreferences> updatePreferences(UserPreferences preferences) async =>
      preferences;

  @override
  Future<void> markNotificationRead(String id) async {}

  @override
  Future<void> deleteNotification(String id) async {}
}

class FakeLoginController extends AuthController {
  FakeLoginController(this.nextUser)
      : super(
          loginUseCase: LoginUseCase(FakeAuthRepository()),
          resetPasswordUseCase: ResetPasswordUseCase(FakeAuthRepository()),
        );

  final UserEntity? nextUser;

  @override
  Future<UserEntity?> login(String username, String password) async => nextUser;
}

class FakeAdminDashboardController extends AdminDashboardController {
  FakeAdminDashboardController()
      : super(
          getDashboardStatsUseCase: GetAdminDashboardStatsUseCase(
            FakeAdminOverviewRepository(),
          ),
        );

  @override
  Future<void> loadStats() async {}

  @override
  void connectRealtime() {}
}

class FakeHomeController extends HomeController {
  FakeHomeController(this.repo)
      : super(
          getNewsPostsUseCase: GetNewsPostsUseCase(repo),
          reactToNewsUseCase: ReactToNewsUseCase(repo),
        );

  final FakeHomeRepository repo;

  @override
  Future<void> loadNews() async {
    newsPosts = await getNewsPostsUseCase();
  }

  @override
  void connectRealtime() {}
}

class FakeMapsController extends MapsController {
  FakeMapsController(this.repo)
      : super(
          getIncidenciasUseCase: GetIncidenciasUseCase(repo),
          mapsRepository: repo,
        );

  final FakeMapsRepository repo;

  @override
  Future<void> loadIncidencias() async {
    incidencias = await getIncidenciasUseCase();
  }

  @override
  void connectRealtime() {}
}

class FakeNotificationController extends NotificationController {
  FakeNotificationController(this.repo)
      : super(
          GetNotificationsUseCase(repo),
          repository: repo,
        );

  final FakeSettingsRepositoryImpl repo;

  @override
  Future<void> loadNotifications() async {
    notifications = await getNotificationsUseCase();
    value = false;
  }
}

class FakeSettingsRepositoryImpl extends SettingsRepositoryImpl
    implements SettingsRepository {
  FakeSettingsRepositoryImpl() : super(apiClient: ApiClient());

  final List<NotificationItem> _notifications = [
    const NotificationItem(
      id: 'n1',
      title: 'Nuevo aviso',
      message: 'Hay un comunicado importante',
      time: '31/07/2026 10:00',
      isRead: false,
      sourceType: 'announcement',
    ),
  ];

  @override
  Future<List<RuleItem>> getCommunityRules() async => [];

  @override
  Future<List<FaqItem>> getFaqs() async => [];

  @override
  Future<List<NotificationItem>> getNotifications() async => _notifications;

  @override
  Future<void> submitFaqQuestion(String question) async {}

  @override
  Future<UserProfile> getProfile() async {
    return const UserProfile(
      id: 'u1',
      fullName: 'Residente',
      email: 'residente@example.com',
      phone: '5550000000',
    );
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async => profile;

  @override
  Future<UserPreferences> getPreferences() async {
    return const UserPreferences(
      themeMode: 'dark',
      notificationsEnabled: true,
      language: 'es',
    );
  }

  @override
  Future<UserPreferences> updatePreferences(UserPreferences preferences) async =>
      preferences;

  @override
  Future<void> markNotificationRead(String id) async {}

  @override
  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((item) => item.id == id);
  }
}
