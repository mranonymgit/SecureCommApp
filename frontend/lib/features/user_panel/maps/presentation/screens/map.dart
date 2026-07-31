import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../data/repositories/maps_repository_impl.dart';
import '../../domain/entities/incidencia.dart';
import '../../domain/usecases/get_incidencias_usecase.dart';
import '../controllers/maps_controller.dart';
import '../widgets/item_leyenda.dart';

class MapaIncidenciasScreen extends StatefulWidget {
  final MapsController? controller;
  final bool allowStatusChange;

  const MapaIncidenciasScreen({
    super.key,
    this.controller,
    this.allowStatusChange = false,
  });

  @override
  State<MapaIncidenciasScreen> createState() => _MapaIncidenciasScreenState();
}

class _MapaIncidenciasScreenState extends State<MapaIncidenciasScreen> {
  late final MapsController _controller;
  bool _mapReady = false;
  bool _centeredOnLatestReport = false;

  @override
  void initState() {
    super.initState();
    final repository = MapsRepositoryImpl();
    _controller =
        widget.controller ??
        MapsController(
          getIncidenciasUseCase: GetIncidenciasUseCase(repository),
          mapsRepository: widget.allowStatusChange ? repository : null,
        );

    _controller.loadIncidencias();
    _controller.connectRealtime();
    _controller.addListener(_centerOnLatestReport);
  }

  @override
  void dispose() {
    _controller.removeListener(_centerOnLatestReport);
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _centerOnLatestReport() {
    if (!_mapReady ||
        _centeredOnLatestReport ||
        _controller.incidencias.isEmpty) {
      return;
    }
    _centeredOnLatestReport = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.mapController.move(
          _controller.incidencias.first.ubicacion,
          15.5,
        );
      }
    });
  }

  Color _obtenerColorEstado(EstadoIncidencia estado) {
    switch (estado) {
      case EstadoIncidencia.pendiente:
        return Colors.blueGrey;
      case EstadoIncidencia.resuelto:
        return const Color(0xFF4CAF50);
      case EstadoIncidencia.enProceso:
        return const Color(0xFFFF9800);
      case EstadoIncidencia.critico:
        return Theme.of(context).colorScheme.error;
      case EstadoIncidencia.cancelado:
        return Colors.grey;
    }
  }

  String _obtenerTextoEstado(EstadoIncidencia estado) =>
      estado.label.toUpperCase();

  String _errorLabel(String? message) {
    if (message == null || message.isEmpty) {
      return 'No pudimos cargar las incidencias.';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 700;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final incidenciaSel = _controller.incidenciaSeleccionada;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Stack(
            children: [
              RepaintBoundary(
                child: FlutterMap(
                  mapController: _controller.mapController,
                  options: MapOptions(
                    initialCenter: MapsController.posicionInicial,
                    initialZoom: 14.5,
                    onMapReady: () {
                      _mapReady = true;
                      _centerOnLatestReport();
                    },
                    onTap: (_, _) {
                      if (incidenciaSel != null) {
                        _controller.deseleccionarIncidencia();
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.sca.maps',
                      keepBuffer: 0,
                      panBuffer: 0,
                      tileDisplay: const TileDisplay.instantaneous(),
                    ),
                    MarkerLayer(
                      markers: _controller.incidencias
                          .where(
                            (incidencia) =>
                                incidencia.ubicacion.latitude != 0 ||
                                incidencia.ubicacion.longitude != 0,
                          )
                          .map((incidencia) {
                            final colorPin = _obtenerColorEstado(
                              incidencia.estado,
                            );
                            final esSeleccionada =
                                incidenciaSel?.id == incidencia.id;

                            return Marker(
                              point: incidencia.ubicacion,
                              width: esSeleccionada ? 54 : 44,
                              height: esSeleccionada ? 54 : 44,
                              child: GestureDetector(
                                onTap: () => _controller.seleccionarIncidencia(
                                  incidencia,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colorPin,
                                      width: esSeleccionada ? 3 : 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorPin.withValues(alpha: 0.35),
                                        blurRadius: esSeleccionada ? 12 : 6,
                                        spreadRadius: esSeleccionada ? 2 : 0,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.warning_amber_rounded,
                                      size: esSeleccionada ? 26 : 20,
                                      color: colorPin,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          })
                          .toList(),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 540),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).cardColor.withValues(alpha: 0.86),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            ItemLeyenda(
                              color: _obtenerColorEstado(
                                EstadoIncidencia.pendiente,
                              ),
                              texto: 'Pendiente',
                            ),
                            ItemLeyenda(
                              color: _obtenerColorEstado(
                                EstadoIncidencia.resuelto,
                              ),
                              texto: 'Resuelto',
                            ),
                            ItemLeyenda(
                              color: _obtenerColorEstado(
                                EstadoIncidencia.enProceso,
                              ),
                              texto: 'En Proceso',
                            ),
                            ItemLeyenda(
                              color: _obtenerColorEstado(
                                EstadoIncidencia.critico,
                              ),
                              texto: 'Crítico',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_controller.isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.25),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              if (_controller.errorMessage != null &&
                  _controller.incidencias.isEmpty)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).cardColor.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _errorLabel(_controller.errorMessage),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _controller.loadIncidencias,
                                child: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                bottom: incidenciaSel != null ? 16 : -420,
                left: 16,
                right: 16,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 620 : double.infinity,
                      maxHeight: MediaQuery.sizeOf(context).height * 0.68,
                    ),
                    child: incidenciaSel == null
                        ? const SizedBox.shrink()
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).cardColor.withValues(alpha: 0.94),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.45),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _obtenerColorEstado(
                                        incidenciaSel.estado,
                                      ).withValues(alpha: 0.12),
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.report_problem,
                                          color: _obtenerColorEstado(
                                            incidenciaSel.estado,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            incidenciaSel.titulo,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: _controller
                                              .deseleccionarIncidencia,
                                          child: CircleAvatar(
                                            backgroundColor: Colors.black
                                                .withValues(alpha: 0.35),
                                            radius: 15,
                                            child: Icon(
                                              Icons.close,
                                              size: 16,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Flexible(
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              _statusChip(
                                                context,
                                                incidenciaSel.estado,
                                              ),
                                              _infoChip(
                                                context,
                                                icon: Icons.access_time,
                                                label: incidenciaSel.fecha,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            incidenciaSel.descripcion,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.75),
                                              height: 1.45,
                                            ),
                                          ),
                                          if (incidenciaSel
                                                  .evidenciaUrl
                                                  ?.isNotEmpty ??
                                              false) ...[
                                            const SizedBox(height: 12),
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Image.network(
                                                incidenciaSel.evidenciaUrl!,
                                                height: 150,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, _, _) =>
                                                    const SizedBox(
                                                      height: 56,
                                                      child: Center(
                                                        child: Text(
                                                          'No fue posible cargar la evidencia.',
                                                        ),
                                                      ),
                                                    ),
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 12),
                                          Text(
                                            'Reportado por: ${incidenciaSel.reporter.isEmpty ? 'Sin dato' : incidenciaSel.reporter}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.6),
                                            ),
                                          ),
                                          if (widget.allowStatusChange) ...[
                                            const SizedBox(height: 16),
                                            Text(
                                              'Cambiar estado',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                _buildStatusAction(
                                                  context,
                                                  label: 'Pendiente',
                                                  estado: EstadoIncidencia
                                                      .pendiente,
                                                  selected:
                                                      incidenciaSel.estado ==
                                                      EstadoIncidencia
                                                          .pendiente,
                                                ),
                                                _buildStatusAction(
                                                  context,
                                                  label: 'Crítico',
                                                  estado:
                                                      EstadoIncidencia.critico,
                                                  selected:
                                                      incidenciaSel.estado ==
                                                      EstadoIncidencia.critico,
                                                ),
                                                _buildStatusAction(
                                                  context,
                                                  label: 'En Proceso',
                                                  estado: EstadoIncidencia
                                                      .enProceso,
                                                  selected:
                                                      incidenciaSel.estado ==
                                                      EstadoIncidencia
                                                          .enProceso,
                                                ),
                                                _buildStatusAction(
                                                  context,
                                                  label: 'Resuelto',
                                                  estado:
                                                      EstadoIncidencia.resuelto,
                                                  selected:
                                                      incidenciaSel.estado ==
                                                      EstadoIncidencia.resuelto,
                                                ),
                                              ],
                                            ),
                                            if (_controller
                                                .isUpdatingStatus) ...[
                                              const SizedBox(height: 12),
                                              const LinearProgressIndicator(
                                                minHeight: 2,
                                              ),
                                            ],
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusChip(BuildContext context, EstadoIncidencia estado) {
    final color = _obtenerColorEstado(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        _obtenerTextoEstado(estado),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _infoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.72),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusAction(
    BuildContext context, {
    required String label,
    required EstadoIncidencia estado,
    required bool selected,
  }) {
    final color = _obtenerColorEstado(estado);
    return OutlinedButton(
      onPressed: _controller.isUpdatingStatus
          ? null
          : () => _controller.cambiarEstado(
              _controller.incidenciaSeleccionada!,
              estado,
            ),
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? Colors.white : color,
        backgroundColor: selected ? color : Colors.transparent,
        side: BorderSide(color: color.withValues(alpha: 0.7)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      child: Text(label),
    );
  }
}
