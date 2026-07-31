import 'package:flutter/material.dart';
import '../../domain/entities/access_log_entity.dart';
import '../../domain/usecases/get_access_logs_usecase.dart';

class AccessControlController extends ChangeNotifier {
  final GetAccessLogsUseCase getAccessLogsUseCase;

  AccessControlController({required this.getAccessLogsUseCase});

  List<AccessLogEntity> _logs = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AccessLogEntity> get logs => _logs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  Future<void> fetchLogs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _logs = await getAccessLogsUseCase();
    } catch (e) {
      _logs = [];
      _errorMessage = 'No fue posible cargar los registros de acceso.';
      debugPrint('Error al obtener registros de acceso: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
