import 'package:flutter/material.dart';
import '../../domain/entities/mensaje_chat.dart';
import '../../domain/usecases/get_mensajes_usecase.dart';
import '../../domain/usecases/enviar_mensaje_usecase.dart';
import '../../domain/usecases/obtener_resumen_ia_usecase.dart';

class ChatController extends ChangeNotifier {
  final GetMensajesUseCase getMensajesUseCase;
  final EnviarMensajeUseCase enviarMensajeUseCase;
  final ObtenerResumenIAUseCase obtenerResumenIAUseCase;

  ChatController({
    required this.getMensajesUseCase,
    required this.enviarMensajeUseCase,
    required this.obtenerResumenIAUseCase,
  });

  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  List<MensajeChat> mensajes = [];
  bool isLoading = false;
  String? errorMessage;

  bool estaBuscando = false;
  String filtroTexto = '';
  DateTime? filtroFecha;
  bool grabandoAudio = false;

  Future<void> cargarMensajes() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      mensajes = List<MensajeChat>.from(await getMensajesUseCase());
    } catch (error) {
      mensajes = [];
      errorMessage = 'No fue posible cargar los mensajes.';
      debugPrint('Error al cargar mensajes: $error');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void toggleBusqueda(bool valor) {
    estaBuscando = valor;
    if (!valor) {
      filtroTexto = '';
      filtroFecha = null;
    }
    notifyListeners();
  }

  void setFiltroTexto(String val) {
    filtroTexto = val;
    notifyListeners();
  }

  void setFiltroFecha(DateTime? fecha) {
    filtroFecha = fecha;
    if (fecha != null) estaBuscando = true;
    notifyListeners();
  }

  void setGrabandoAudio(bool valor) {
    grabandoAudio = valor;
    notifyListeners();
  }

  List<MensajeChat> get mensajesFiltrados {
    return mensajes.where((m) {
      final coincideTexto =
          filtroTexto.isEmpty ||
          (m.texto?.toLowerCase().contains(filtroTexto.toLowerCase()) ??
              false) ||
          m.nombreUsuario.toLowerCase().contains(filtroTexto.toLowerCase());

      final coincideFecha =
          filtroFecha == null ||
          (m.fechaHora.year == filtroFecha!.year &&
              m.fechaHora.month == filtroFecha!.month &&
              m.fechaHora.day == filtroFecha!.day);

      return coincideTexto && coincideFecha;
    }).toList();
  }

  Future<void> enviarTexto() async {
    final texto = textController.text.trim();
    if (texto.isEmpty) return;

    final nuevo = MensajeChat(
      id: '',
      usuarioId: '',
      nombreUsuario: '',
      avatarUrl: '',
      tipoUsuario: TipoUsuario.usuario,
      texto: texto,
      fechaHora: DateTime.now(),
      esMio: true,
    );

    try {
      final guardado = await enviarMensajeUseCase(nuevo);
      textController.clear();
      // Los repositorios pueden devolver listas de solo lectura. Reemplazar la
      // colección evita mutarlas y hace visible el mensaje confirmado por API.
      mensajes = [...mensajes, guardado];
      errorMessage = null;
      notifyListeners();
      hacerScrollAlFinal();
    } catch (error) {
      errorMessage = 'No fue posible enviar el mensaje.';
      debugPrint('Error al enviar mensaje: $error');
      notifyListeners();
    }
  }

  void reportarAudioNoDisponible() {
    grabandoAudio = false;
    errorMessage =
        'El envío de audio requiere integrar almacenamiento y grabación reales.';
    notifyListeners();
  }

  void hacerScrollAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<String> obtenerResumen() async {
    return await obtenerResumenIAUseCase();
  }

  @override
  void dispose() {
    textController.dispose();
    scrollController.dispose();
    super.dispose();
  }
}
