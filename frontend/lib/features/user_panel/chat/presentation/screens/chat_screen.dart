import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/usecases/get_mensajes_usecase.dart';
import '../../domain/usecases/enviar_mensaje_usecase.dart';
import '../../domain/usecases/obtener_resumen_ia_usecase.dart';
import '../controllers/chat_controller.dart';
import '../widgets/burbuja_chat.dart';
import '../widgets/mensaje_animado.dart';

class Chatscreen extends StatefulWidget {
  final ChatController? controller;

  const Chatscreen({super.key, this.controller});

  @override
  State<Chatscreen> createState() => _ChatscreenState();
}

class _ChatscreenState extends State<Chatscreen> {
  late final ChatController _controller;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    final repository = ChatRepositoryImpl();
    _controller =
        widget.controller ??
        ChatController(
          getMensajesUseCase: GetMensajesUseCase(repository),
          enviarMensajeUseCase: EnviarMensajeUseCase(repository),
          obtenerResumenIAUseCase: ObtenerResumenIAUseCase(repository),
        );

    _controller.cargarMensajes();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _controller.cargarMensajes(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _mostrarDialogoResumenIA(ThemeData theme) async {
    String resumen;
    try {
      resumen = await _controller.obtenerResumen();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No fue posible generar el resumen del chat.'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
      return;
    }
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.dialogTheme.backgroundColor ?? theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.dividerColor),
          ),
          title: Row(
            children: [
              Icon(Icons.auto_awesome, color: theme.colorScheme.secondary),
              const SizedBox(width: 8),
              Text(
                'Resumen IA (Groq)',
                style: TextStyle(
                  fontSize: 18,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumen de mensajes del canal:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  resumen,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cerrar',
                style: TextStyle(color: theme.colorScheme.secondary),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _seleccionarFechaBusqueda(ThemeData theme) async {
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(surface: theme.cardColor),
          ),
          child: child!,
        );
      },
    );

    if (fecha != null) {
      _controller.setFiltroFecha(fecha);
    }
  }

  Future<void> _adjuntarAudio() async {
    final selected = await FilePicker.pickFiles(
      type: FileType.audio,
      withData: true,
    );
    final file = selected?.files.single;
    if (file == null || file.bytes == null) return;
    final ok = await _controller.enviarAudio(file.bytes!, file.name);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _controller.errorMessage ?? 'No se pudo enviar el audio.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final mensajes = _controller.mensajesFiltrados;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: Stack(
            children: [
              Column(
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: _controller.estaBuscando
                        ? Container(
                            color: theme.cardColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    onChanged: _controller.setFiltroTexto,
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Buscar mensaje o usuario...',
                                      hintStyle: TextStyle(
                                        color: colorScheme.onSurface
                                            .withOpacity(0.4),
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search,
                                        size: 20,
                                        color: colorScheme.onSurface
                                            .withOpacity(0.6),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 12,
                                          ),
                                      fillColor: theme.scaffoldBackgroundColor,
                                      filled: true,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.calendar_today,
                                    size: 20,
                                    color: colorScheme.secondary,
                                  ),
                                  tooltip: 'Filtrar por fecha',
                                  onPressed: () =>
                                      _seleccionarFechaBusqueda(theme),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    size: 20,
                                    color: colorScheme.onSurface.withOpacity(
                                      0.6,
                                    ),
                                  ),
                                  onPressed: () =>
                                      _controller.toggleBusqueda(false),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: _controller.filtroFecha != null
                        ? Container(
                            width: double.infinity,
                            color: colorScheme.primary.withOpacity(0.15),
                            padding: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 16,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Filtrando fecha: ${_controller.filtroFecha!.day}/${_controller.filtroFecha!.month}/${_controller.filtroFecha!.year}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurface.withOpacity(
                                      0.8,
                                    ),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _controller.setFiltroFecha(null),
                                  child: Icon(
                                    Icons.cancel,
                                    size: 16,
                                    color: colorScheme.onSurface.withOpacity(
                                      0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Expanded(
                    child: _controller.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _controller.errorMessage != null && mensajes.isEmpty
                        ? Center(
                            child: FilledButton.icon(
                              onPressed: _controller.cargarMensajes,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar carga del chat'),
                            ),
                          )
                        : mensajes.isEmpty
                        ? Center(
                            child: Text(
                              'Aún no hay mensajes en el chat comunitario.',
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.65),
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _controller.scrollController,
                            padding: const EdgeInsets.all(16.0),
                            itemCount: mensajes.length,
                            itemBuilder: (context, index) {
                              final mensaje = mensajes[index];
                              final mostrarFecha =
                                  index == 0 ||
                                  !_mismoDia(
                                    mensajes[index - 1].fechaHora,
                                    mensaje.fechaHora,
                                  );
                              return Column(
                                children: [
                                  if (mostrarFecha)
                                    _SeparadorFecha(fecha: mensaje.fechaHora),
                                  MensajeAnimado(
                                    key: ValueKey(mensaje.id),
                                    child: BurbujaChat(mensaje: mensaje),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                  if (_controller.errorMessage != null && mensajes.isNotEmpty)
                    Container(
                      width: double.infinity,
                      color: colorScheme.errorContainer,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        _controller.errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.onErrorContainer),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      border: Border(
                        top: BorderSide(color: theme.dividerColor),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller.textController,
                            onChanged: (_) => setState(() {}),
                            style: TextStyle(color: colorScheme.onSurface),
                            decoration: InputDecoration(
                              hintText: 'Escribe un mensaje...',
                              hintStyle: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.4),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              fillColor: theme.scaffoldBackgroundColor,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(
                                  color: theme.dividerColor,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(
                                  color: theme.dividerColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(
                                  color: colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_controller.textController.text.trim().isEmpty)
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: colorScheme.primary,
                            child: IconButton(
                              tooltip: 'Adjuntar audio',
                              onPressed: _adjuntarAudio,
                              icon: Icon(
                                Icons.audio_file,
                                color: colorScheme.onPrimary,
                                size: 21,
                              ),
                            ),
                          )
                        else
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: colorScheme.primary,
                            child: IconButton(
                              icon: Icon(
                                Icons.send,
                                color: colorScheme.onPrimary,
                                size: 18,
                              ),
                              onPressed: _controller.enviarTexto,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 16,
                bottom: 80,
                child: PopupMenuButton<String>(
                  elevation: 6,
                  color: theme.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: theme.dividerColor),
                  ),
                  icon: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.tune,
                      color: colorScheme.onPrimary,
                      size: 22,
                    ),
                  ),
                  onSelected: (val) {
                    if (val == 'buscar') {
                      _controller.toggleBusqueda(true);
                    } else if (val == 'resumen_ia') {
                      _mostrarDialogoResumenIA(theme);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'buscar',
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Buscar mensajes',
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'resumen_ia',
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: colorScheme.secondary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Resumir con IA',
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _mismoDia(DateTime primera, DateTime segunda) {
    return primera.year == segunda.year &&
        primera.month == segunda.month &&
        primera.day == segunda.day;
  }
}

class _SeparadorFecha extends StatelessWidget {
  const _SeparadorFecha({required this.fecha});

  final DateTime fecha;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.8,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            child: Text(
              _etiquetaFecha(fecha),
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _etiquetaFecha(DateTime value) {
    final fecha = DateTime(value.year, value.month, value.day);
    final hoy = DateTime.now();
    final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
    final ayer = inicioHoy.subtract(const Duration(days: 1));
    if (fecha == inicioHoy) return 'Hoy';
    if (fecha == ayer) return 'Ayer';

    const meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return '${fecha.day} de ${meses[fecha.month - 1]} de ${fecha.year}';
  }
}
