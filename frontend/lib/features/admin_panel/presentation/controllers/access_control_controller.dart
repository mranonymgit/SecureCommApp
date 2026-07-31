import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/services/community_realtime_service.dart';
import '../../domain/entities/access_log_entity.dart';
import '../../domain/usecases/get_access_logs_usecase.dart';

class AccessControlController extends ChangeNotifier {
  final GetAccessLogsUseCase getAccessLogsUseCase;

  AccessControlController({required this.getAccessLogsUseCase});

  List<AccessLogEntity> _logs = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<CommunityChange>? _realtimeSubscription;
  bool _isRefreshing = false;

  List<AccessLogEntity> get logs => _logs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  Future<void> fetchLogs({bool showLoading = true}) async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      _logs = await getAccessLogsUseCase();
      _errorMessage = null;
    } catch (e) {
      if (showLoading) {
        _logs = [];
        _errorMessage = 'No fue posible cargar los registros de acceso.';
      }
      debugPrint('Error al obtener registros de acceso: $e');
    } finally {
      _isRefreshing = false;
      if (showLoading) _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> connectRealtime() async {
    if (_realtimeSubscription != null) return;
    _realtimeSubscription = CommunityRealtimeService.instance
        .watchTables(const {'visits', 'access_logs'})
        .listen((_) => unawaited(fetchLogs(showLoading: false)));
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }
}
