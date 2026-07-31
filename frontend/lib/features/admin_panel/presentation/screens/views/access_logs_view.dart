import 'package:flutter/material.dart';
import '../../../data/repositories/access_control_repository_impl.dart';
import '../../../domain/entities/access_log_entity.dart';
import '../../../domain/usecases/get_access_logs_usecase.dart';
import '../../controllers/access_control_controller.dart';
import '../../widgets/admin_state_feedback.dart';

class AccessLogsView extends StatefulWidget {
  final AccessControlController? controller;

  const AccessLogsView({super.key, this.controller});

  @override
  State<AccessLogsView> createState() => _AccessLogsViewState();
}

class _AccessLogsViewState extends State<AccessLogsView> {
  late final AccessControlController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ??
        AccessControlController(
          getAccessLogsUseCase: GetAccessLogsUseCase(
            AccessControlRepositoryImpl(),
          ),
        );

    _controller.fetchLogs();
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _showLogDetail(BuildContext context, AccessLogEntity log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Row(
          children: [
            const Icon(Icons.badge, color: Colors.greenAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                log.visitor,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(color: Colors.white24),
            _detailRow('Residente / Unidad:', log.resident),
            _detailRow('Hora de Registro:', log.time),
            _detailRow('Tipo de Ingreso:', log.type),
            _detailRow('Estado Actual:', log.status),
            _detailRow('Matrícula / Vehículo:', log.plate),
            _detailRow('Código Validado:', log.qrCode),
            _detailRow('Registrado Por:', log.entryGuard),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A2A2A),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: const TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Control de Accesos y Visitas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              if (_controller.isLoading) {
                return const AdminLoadingState(color: Colors.greenAccent);
              }

              if (_controller.hasError) {
                return AdminErrorState(
                  message:
                      _controller.errorMessage ??
                      'No se pudieron cargar los accesos.',
                  onRetry: _controller.fetchLogs,
                );
              }

              if (_controller.logs.isEmpty) {
                return AdminEmptyState(
                  icon: Icons.qr_code_scanner,
                  title: 'Sin registros',
                  message:
                      'Los accesos y visitas aparecerán aquí cuando la base de datos esté conectada.',
                  actionLabel: 'Reintentar',
                  onAction: _controller.fetchLogs,
                );
              }

              return Material(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF333333)),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _controller.logs.length,
                    separatorBuilder: (_, separatorIndex) =>
                        const Divider(color: Colors.white10, height: 1),
                    itemBuilder: (context, index) {
                      final log = _controller.logs[index];
                      return ListTile(
                        onTap: () => _showLogDetail(context, log),
                        leading: const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.greenAccent,
                        ),
                        title: Text(
                          log.visitor,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Destino: ${log.resident} • Tipo: ${log.type}',
                          style: const TextStyle(color: Colors.white54),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.white38,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
