import 'package:flutter/material.dart';
import '../../domain/entities/report_entity.dart';
import '../../domain/usecases/get_reports_usecase.dart';
import '../../domain/usecases/update_report_status_usecase.dart';

class ReportsController extends ChangeNotifier {
  final GetReportsUseCase getReportsUseCase;
  final UpdateReportStatusUseCase updateReportStatusUseCase;

  ReportsController({
    required this.getReportsUseCase,
    required this.updateReportStatusUseCase,
  });

  List<ReportEntity> _reports = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ReportEntity> get reports => _reports;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  Future<void> loadReports() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reports = await getReportsUseCase();
    } catch (e) {
      _reports = [];
      _errorMessage = 'No fue posible cargar los reportes.';
      debugPrint('Error al obtener reportes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changeStatus(String id, String newStatus) async {
    try {
      final updated = await updateReportStatusUseCase(id, newStatus);
      final index = _reports.indexWhere((r) => r.id == id);
      if (index != -1) {
        _reports[index] = updated;
        _errorMessage = null;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'No fue posible actualizar el estado del reporte.';
      debugPrint('Error al actualizar el estado: $e');
      notifyListeners();
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
      case 'pending':
        return Colors.grey;
      case 'en_proceso':
      case 'in_progress':
        return Colors.amber;
      case 'resuelto':
      case 'resolved':
        return Colors.green;
      case 'crítico':
      case 'critico':
      case 'critical':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  String getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'pendiente':
        return 'Pendiente';
      case 'in_progress':
      case 'en_proceso':
        return 'En Proceso';
      case 'resolved':
      case 'resuelto':
        return 'Resuelto';
      case 'critical':
      case 'critico':
      case 'crítico':
        return 'Crítico';
      case 'cancelled':
      case 'cancelado':
        return 'Cancelado';
      default:
        return status;
    }
  }
}
