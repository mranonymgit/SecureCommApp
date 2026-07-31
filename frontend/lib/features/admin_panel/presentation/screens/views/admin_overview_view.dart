import 'package:flutter/material.dart';
import '../../../data/repositories/admin_overview_repository_impl.dart';
import '../../../domain/usecases/get_admin_dashboard_stats_usecase.dart';
import '../../controllers/admin_dashboard_controller.dart';
import '../../widgets/quick_action_card.dart';
import '../../widgets/admin_state_feedback.dart';
import '../../widgets/stat_card.dart';

class AdminOverviewView extends StatefulWidget {
  final AdminDashboardController? controller;
  final bool isDesktop;
  final VoidCallback onOpenChat;

  const AdminOverviewView({
    super.key,
    this.controller,
    required this.isDesktop,
    required this.onOpenChat,
  });

  @override
  State<AdminOverviewView> createState() => _AdminOverviewViewState();
}

class _AdminOverviewViewState extends State<AdminOverviewView> {
  late final AdminDashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ??
        AdminDashboardController(
          getDashboardStatsUseCase: GetAdminDashboardStatsUseCase(
            AdminOverviewRepositoryImpl(),
          ),
        );
    if (widget.controller == null) {
      _controller.loadStats();
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final stats = _controller.stats;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenido, Administrador',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.0),
                      Text(
                        'Resumen general del condominio',
                        style: TextStyle(color: Colors.white54, fontSize: 14.0),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    onPressed: _controller.loadStats,
                  ),
                ],
              ),
              const SizedBox(height: 20.0),

              if (_controller.hasError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: AdminErrorState(
                    message:
                        _controller.errorMessage ??
                        'No se pudieron cargar las métricas.',
                    onRetry: _controller.loadStats,
                  ),
                ),

              // 💬 BOTÓN DESTACADO: CHAT GRUPAL DE VECINOS
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onOpenChat,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.forum_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 18),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chat Grupal Comunitario',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Acceso directo a la conversación general de todos los vecinos',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24.0),

              if (_controller.isLoading)
                const AdminLoadingState(color: Colors.greenAccent)
              else if (stats == null)
                AdminEmptyState(
                  icon: Icons.query_stats_outlined,
                  title: 'Métricas no disponibles',
                  message:
                      'Conecta la consulta real para mostrar los indicadores del panel.',
                  actionLabel: 'Reintentar',
                  onAction: _controller.loadStats,
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 1100
                        ? 4
                        : constraints.maxWidth > 650
                        ? 2
                        : 1;

                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                      childAspectRatio: 2.2,
                      children: [
                        StatCard(
                          title: 'Residentes Activos',
                          value: '${stats.totalResidents}',
                          icon: Icons.people_outline,
                          color: Colors.blueAccent,
                        ),
                        StatCard(
                          title: 'Visitas Hoy',
                          value: '${stats.activeVisitsToday}',
                          icon: Icons.door_sliding_outlined,
                          color: Colors.greenAccent,
                        ),
                        StatCard(
                          title: 'Reportes Pendientes',
                          value: '${stats.pendingReports}',
                          icon: Icons.report_problem_outlined,
                          color: Colors.orangeAccent,
                        ),
                        StatCard(
                          title: 'Alertas Activas',
                          value: '${stats.activeAlerts}',
                          icon: Icons.warning_amber_rounded,
                          color: Colors.redAccent,
                        ),
                      ],
                    );
                  },
                ),

              const SizedBox(height: 32.0),
              const Text(
                'Acciones Rápidas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16.0),
              QuickActionCard(
                title: 'Crear Comunicado General',
                subtitle: 'Enviar aviso o circular a todos los residentes',
                icon: Icons.campaign_outlined,
                onTap: () => _controller.setSelectedIndex(3),
              ),
              const SizedBox(height: 12.0),
              QuickActionCard(
                title: 'Registrar Nuevo Residente',
                subtitle: 'Dar de alta un nuevo usuario o familia',
                icon: Icons.person_add_alt_1_outlined,
                onTap: () => _controller.setSelectedIndex(1),
              ),
              const SizedBox(height: 12.0),
              QuickActionCard(
                title: 'Revisar Bitácora de Accesos',
                subtitle: 'Ver historial de entradas y salidas de hoy',
                icon: Icons.receipt_long_outlined,
                onTap: () => _controller.setSelectedIndex(2),
              ),
            ],
          ),
        );
      },
    );
  }
}
