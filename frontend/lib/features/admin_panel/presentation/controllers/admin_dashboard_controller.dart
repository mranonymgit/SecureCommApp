import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/services/community_realtime_service.dart';
import '../../domain/entities/admin_dashboard_stats_entity.dart';
import '../../domain/usecases/get_admin_dashboard_stats_usecase.dart';

class AdminDashboardController extends ChangeNotifier {
  final GetAdminDashboardStatsUseCase getDashboardStatsUseCase;

  AdminDashboardController({required this.getDashboardStatsUseCase});

  AdminDashboardStatsEntity? _stats;
  bool _isLoading = false;
  String? _errorMessage;
  int _selectedIndex = 0;
  StreamSubscription<CommunityChange>? _realtimeSubscription;

  AdminDashboardStatsEntity? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  int get selectedIndex => _selectedIndex;

  Future<void> loadStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _stats = await getDashboardStatsUseCase();
    } catch (e) {
      _stats = null;
      _errorMessage = 'No fue posible cargar las métricas del panel.';
      debugPrint(
        'Error al cargar estadísticas del panel de administración: $e',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void connectRealtime() {
    _realtimeSubscription ??= CommunityRealtimeService.instance
        .watchTables(const {'users', 'visits', 'reports', 'panic_alerts'})
        .listen((_) => unawaited(refreshStatsSilently()));
  }

  Future<void> refreshStatsSilently() async {
    try {
      _stats = await getDashboardStatsUseCase();
      _errorMessage = null;
      notifyListeners();
    } catch (_) {
      // Keep the last valid metrics visible while the API reconnects.
    }
  }

  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }
}
