import 'dart:async';

import 'package:flutter/material.dart';
import '../../domain/entities/admin_dashboard_stats_entity.dart';
import '../../domain/usecases/get_admin_dashboard_stats_usecase.dart';

class AdminDashboardController extends ChangeNotifier {
  final GetAdminDashboardStatsUseCase getDashboardStatsUseCase;

  AdminDashboardController({required this.getDashboardStatsUseCase});

  AdminDashboardStatsEntity? _stats;
  bool _isLoading = false;
  String? _errorMessage;
  int _selectedIndex = 0;
  Timer? _refreshTimer;

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

  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  void startRealtimeRefresh() {
    _refreshTimer ??= Timer.periodic(
      const Duration(seconds: 10),
      (_) => loadStats(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
