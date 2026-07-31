import 'package:flutter_map/flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../../data/repositories/reports_repository_impl.dart';
import '../../../domain/usecases/get_reports_usecase.dart';
import '../../../domain/usecases/update_report_status_usecase.dart';
import '../../controllers/reports_controller.dart';
import '../../widgets/admin_state_feedback.dart';

class ReportsView extends StatefulWidget {
  final ReportsController? controller;

  const ReportsView({super.key, this.controller});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  late final ReportsController _controller;

  @override
  void initState() {
    super.initState();
    final repo = ReportsRepositoryImpl();
    _controller =
        widget.controller ??
        ReportsController(
          getReportsUseCase: GetReportsUseCase(repo),
          updateReportStatusUseCase: UpdateReportStatusUseCase(repo),
        );

    _controller.loadReports();
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _showReportDetail(String reportId) {
    showDialog(
      context: context,
      builder: (context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final reports = _controller.reports;
          final currentReportIndex = reports.indexWhere(
            (r) => r.id == reportId,
          );
          final currentReport = currentReportIndex == -1
              ? null
              : reports[currentReportIndex];

          if (currentReport == null) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text(
                'Reporte no disponible',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                'El reporte ya no está disponible o no pudo cargarse.',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A2A2A),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          }

          final statusColor = _controller.getStatusColor(currentReport.status);
          final hasCoordinates =
              currentReport.latitude != null && currentReport.longitude != null;
          final mapCenter = hasCoordinates
              ? LatLng(currentReport.latitude!, currentReport.longitude!)
              : const LatLng(19.432608, -99.133209);

          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: Text(
              currentReport.title,
              style: const TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Reportado por: ${currentReport.reporter}',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  Text(
                    'Ubicación: ${currentReport.location}',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  Text(
                    'Coordenadas GPS: ${currentReport.coords}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentReport.desc,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                      color: const Color(0xFF121212),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: hasCoordinates
                          ? FlutterMap(
                              options: MapOptions(
                                initialCenter: mapCenter,
                                initialZoom: 16,
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                                  subdomains: const ['a', 'b', 'c', 'd'],
                                  userAgentPackageName: 'com.sca.admin',
                                  keepBuffer: 0,
                                  panBuffer: 0,
                                  tileDisplay:
                                      const TileDisplay.instantaneous(),
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: mapCenter,
                                      width: 48,
                                      height: 48,
                                      child: Icon(
                                        Icons.location_on,
                                        color: statusColor,
                                        size: 42,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.location_off,
                                      color: statusColor,
                                      size: 40,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Sin coordenadas disponibles',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'El reporte existe en la base de datos, pero todavía no tiene latitud y longitud.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white38.withValues(
                                          alpha: 0.95,
                                        ),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Cambiar Estado (Admin):',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children:
                        const [
                          ('pending', 'Pendiente'),
                          ('in_progress', 'En Proceso'),
                          ('resolved', 'Resuelto'),
                          ('critical', 'Crítico'),
                        ].map((entry) {
                          final value = entry.$1;
                          final label = entry.$2;
                          final isSelected =
                              currentReport.status.toLowerCase() == value;
                          final stColor = _controller.getStatusColor(value);
                          return ChoiceChip(
                            label: Text(
                              label,
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: stColor,
                            backgroundColor: const Color(0xFF2A2A2A),
                            onSelected: (_) {
                              _controller.changeStatus(currentReport.id, value);
                            },
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A2A2A),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Guardar y Cerrar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
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
            'Reportes e Incidencias',
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
                return const AdminLoadingState(color: Colors.amber);
              }

              if (_controller.hasError) {
                return AdminErrorState(
                  message:
                      _controller.errorMessage ??
                      'No se pudieron cargar los reportes.',
                  onRetry: _controller.loadReports,
                );
              }

              if (_controller.reports.isEmpty) {
                return AdminEmptyState(
                  icon: Icons.report_outlined,
                  title: 'Sin reportes',
                  message:
                      'Las incidencias registradas desde la base de datos aparecerán aquí.',
                  actionLabel: 'Reintentar',
                  onAction: _controller.loadReports,
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _controller.reports.length,
                itemBuilder: (context, index) {
                  final report = _controller.reports[index];
                  final statusColor = _controller.getStatusColor(report.status);

                  return Card(
                    color: const Color(0xFF1E1E1E),
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      onTap: () => _showReportDetail(report.id),
                      leading: CircleAvatar(
                        backgroundColor: statusColor.withValues(alpha: 0.2),
                        child: Icon(Icons.report_problem, color: statusColor),
                      ),
                      title: Text(
                        report.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${report.location} • ${report.coords}',
                        style: const TextStyle(color: Colors.white54),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          _controller.getStatusLabel(report.status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
