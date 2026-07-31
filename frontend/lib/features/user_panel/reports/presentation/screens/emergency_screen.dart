import 'package:flutter/material.dart';
import '../../data/repositories/reports_repository_impl.dart';
import '../../domain/usecases/get_emergency_profile_usecase.dart';
import '../../domain/usecases/trigger_sos_alert_usecase.dart';
import '../controllers/emergency_controller.dart';
import '../widgets/emergency_widgets.dart';

class EmergencyScreen extends StatefulWidget {
  final EmergencyController? controller;

  const EmergencyScreen({super.key, this.controller});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with SingleTickerProviderStateMixin {
  late final EmergencyController _controller;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    final repository = ReportsRepositoryImpl();
    _controller =
        widget.controller ??
        EmergencyController(
          getProfileUseCase: GetEmergencyProfileUseCase(repository),
          triggerSosAlertUseCase: TriggerSosAlertUseCase(repository),
        );

    _controller.loadProfile();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onEmergencyTap() async {
    await _controller.toggleEmergency();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _controller.errorMessage ??
              (_controller.emergencyActive
                  ? 'Alerta SOS registrada para la administración.'
                  : 'Alerta SOS desactivada.'),
        ),
        backgroundColor: _controller.errorMessage != null
            ? Theme.of(context).colorScheme.error
            : (_controller.emergencyActive
                  ? Theme.of(context).colorScheme.error
                  : Colors.green),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Centro de Emergencias SOS',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Presiona el botón para notificar inmediatamente a los vecinos y seguridad',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 🔴 Botón SOS Animado
                  GestureDetector(
                    onTap: _onEmergencyTap,
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Container(
                          padding: EdgeInsets.all(
                            _controller.emergencyActive
                                ? 15 * _animationController.value
                                : 10,
                          ),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.error
                                .withOpacity(
                                  _controller.emergencyActive
                                      ? 0.2 + (0.3 * _animationController.value)
                                      : 0.1,
                                ),
                          ),
                          child: Container(
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: _controller.emergencyActive
                                    ? [
                                        const Color(0xFFFF0000),
                                        const Color(
                                          0xFFB71C1C,
                                        ).withOpacity(0.8),
                                      ]
                                    : [
                                        const Color(0xFFFF0000),
                                        const Color(0xFFB71C1C),
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.error.withOpacity(0.6),
                                  blurRadius: _controller.emergencyActive
                                      ? 25
                                      : 12,
                                  spreadRadius: _controller.emergencyActive
                                      ? 5
                                      : 2,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _controller.emergencyActive
                                      ? Icons.warning_amber_rounded
                                      : Icons.campaign,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.onError,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _controller.emergencyActive
                                      ? 'CANCELAR'
                                      : '¡AYUDA!',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onError,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 📞 Accesos directos a llamadas
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Llamadas Rápidas de Emergencia',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: EmergencyCallButton(
                          title: '911',
                          subtitle: 'General',
                          icon: Icons.phone_in_talk,
                          color: Theme.of(context).colorScheme.error,
                          onTap: () => _controller.makePhoneCall('911'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: EmergencyCallButton(
                          title: 'Policía',
                          subtitle: 'Seguridad',
                          icon: Icons.local_police,
                          color: Theme.of(context).colorScheme.secondary,
                          onTap: () => _controller.makePhoneCall('911'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: EmergencyCallButton(
                          title: 'Bomberos',
                          subtitle: 'Cruz Roja',
                          icon: Icons.medical_services,
                          color: Theme.of(context).colorScheme.tertiary,
                          onTap: () => _controller.makePhoneCall('911'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // 🪪 Ficha Completa del Residente (Información vinculada al Admin)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Icon(
                          _controller.emergencyActive
                              ? Icons.health_and_safety
                              : Icons.badge_outlined,
                          color: _controller.emergencyActive
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _controller.emergencyActive
                              ? 'Información Emitida en Alerta SOS'
                              : 'Ficha del Residente y Datos Médicos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_controller.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _controller.errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _controller.emergencyActive
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).dividerColor,
                        width: _controller.emergencyActive ? 1.5 : 1.0,
                      ),
                    ),
                    child: _controller.profile == null
                        ? Column(
                            children: [
                              Icon(
                                Icons.badge_outlined,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.5),
                                size: 36,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Perfil pendiente de carga desde la base de datos.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              InfoRow(
                                icon: Icons.person_outline,
                                label: 'Residente:',
                                value: _controller.profile!.nombre,
                              ),
                              Divider(color: Theme.of(context).dividerColor),
                              InfoRow(
                                icon: Icons.home_work_outlined,
                                label: 'Ubicación:',
                                value: _controller.profile!.direccion,
                              ),
                              Divider(color: Theme.of(context).dividerColor),
                              InfoRow(
                                icon: Icons.phone_outlined,
                                label: 'Teléfono:',
                                value: _controller.profile!.contactoEmergencia,
                              ),
                              Divider(color: Theme.of(context).dividerColor),
                              InfoRow(
                                icon: Icons.verified_user_outlined,
                                label: 'Estado Cuenta:',
                                value: 'Al día',
                                valueColor: Colors.greenAccent,
                              ),
                              Divider(color: Theme.of(context).dividerColor),
                              InfoRow(
                                icon: Icons.bloodtype_outlined,
                                label: 'Tipo de Sangre:',
                                value: _controller.profile!.tipoSangre,
                                valueColor: Theme.of(context).colorScheme.error,
                              ),
                              Divider(color: Theme.of(context).dividerColor),
                              InfoRow(
                                icon: Icons.medical_information_outlined,
                                label: 'Padecimientos:',
                                value: _controller.profile!.padecimientos,
                              ),
                              Divider(color: Theme.of(context).dividerColor),
                              InfoRow(
                                icon: Icons.warning_amber_outlined,
                                label: 'Alergias:',
                                value: _controller.profile!.alergias,
                                valueColor: Colors.amberAccent,
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
