import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_error_message.dart';
import '../../../../../core/services/chat_audio_recorder.dart';
import '../../../../../core/services/chat_realtime_service.dart';
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
  }) {
    textController.addListener(_broadcastTyping);
  }

  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  List<MensajeChat> mensajes = [];
  bool isLoading = false;
  String? errorMessage;
  String? actionErrorMessage;
  final ChatAudioRecorder _audioRecorder = ChatAudioRecorder();
  final ChatRealtimeService _realtime = ChatRealtimeService();
  bool isRecording = false;
  bool isSendingAudio = false;
  Duration recordingDuration = Duration.zero;
  bool vecinoEstaEscribiendo = false;
  Timer? _typingDebounce;
  Timer? _recordingTimer;

  String get recordingTimeLabel {
    final minutes = recordingDuration.inMinutes.toString().padLeft(2, '0');
    final seconds = recordingDuration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds';
  }

  bool estaBuscando = false;
  String filtroTexto = '';
  DateTime? filtroFecha;

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
      hacerScrollAlFinal();
    }
  }

  Future<void> actualizarMensajesSilenciosamente() async {
    try {
      mensajes = List<MensajeChat>.from(await getMensajesUseCase());
      errorMessage = null;
      notifyListeners();
      hacerScrollAlFinal();
    } catch (error) {
      debugPrint('Error al sincronizar mensajes: $error');
    }
  }

  Future<void> conectarTiempoReal() => _realtime.subscribe(
    actualizarMensajesSilenciosamente,
    onPeerTyping: (isTyping) {
      vecinoEstaEscribiendo = isTyping;
      notifyListeners();
    },
  );

  void _broadcastTyping() {
    if (textController.text.trim().isEmpty) {
      _typingDebounce?.cancel();
      _realtime.setTyping(false);
      return;
    }
    _realtime.setTyping(true);
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(milliseconds: 900), () {
      _realtime.setTyping(false);
    });
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

  Future<String?> enviarTexto() async {
    final texto = textController.text.trim();
    if (texto.isEmpty) return null;

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
      mensajes =
          [...mensajes.where((mensaje) => mensaje.id != guardado.id), guardado]
            ..sort(
              (primerMensaje, segundoMensaje) =>
                  primerMensaje.fechaHora.compareTo(segundoMensaje.fechaHora),
            );
      actionErrorMessage = null;
      notifyListeners();
      hacerScrollAlFinal();
      return null;
    } catch (error) {
      actionErrorMessage = ApiErrorMessage.from(
        error,
        fallback: 'No fue posible enviar el mensaje.',
      );
      debugPrint('Error al enviar mensaje: $error');
      notifyListeners();
      return actionErrorMessage;
    }
  }

  Future<bool> enviarAudio(
    Uint8List bytes,
    String filename, {
    Duration? duration,
  }) async {
    try {
      final extension = filename.toLowerCase();
      final contentType = extension.endsWith('.m4a')
          ? 'audio/mp4'
          : extension.endsWith('.ogg')
          ? 'audio/ogg'
          : extension.endsWith('.webm')
          ? 'audio/webm'
          : extension.endsWith('.wav')
          ? 'audio/wav'
          : 'audio/mpeg';
      final upload = await ApiClient().uploadBytes(
        '/api/storage/chat-audio',
        bytes: bytes,
        filename: filename,
        contentType: contentType,
      );
      final objectPath = (upload['object_path'] ?? '').toString();
      if (objectPath.isEmpty) {
        throw StateError('Supabase no devolvió la referencia del audio.');
      }
      final saved = await enviarMensajeUseCase(
        MensajeChat(
          id: '',
          usuarioId: '',
          nombreUsuario: '',
          avatarUrl: '',
          tipoUsuario: TipoUsuario.usuario,
          texto: 'Audio',
          audioUrl: objectPath,
          duracionAudio: duration,
          fechaHora: DateTime.now(),
          esMio: true,
        ),
      );
      mensajes = [...mensajes.where((mensaje) => mensaje.id != saved.id), saved]
        ..sort(
          (primerMensaje, segundoMensaje) =>
              primerMensaje.fechaHora.compareTo(segundoMensaje.fechaHora),
        );
      actionErrorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      actionErrorMessage = ApiErrorMessage.from(
        error,
        fallback: 'No fue posible enviar el audio.',
      );
      debugPrint('Error al enviar audio: $error');
      notifyListeners();
      return false;
    }
  }

  Future<String?> toggleAudioRecording() async {
    try {
      if (!isRecording) {
        await _audioRecorder.start();
        isRecording = true;
        recordingDuration = Duration.zero;
        actionErrorMessage = null;
        _recordingTimer?.cancel();
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          recordingDuration += const Duration(seconds: 1);
          notifyListeners();
        });
        notifyListeners();
        return null;
      }
      final recording = await _audioRecorder.stop();
      _recordingTimer?.cancel();
      _recordingTimer = null;
      isRecording = false;
      isSendingAudio = recording != null;
      notifyListeners();
      if (recording != null) {
        final sent = await enviarAudio(
          recording.bytes,
          'mensaje-${DateTime.now().millisecondsSinceEpoch}.wav',
          duration: recording.duration,
        );
        isSendingAudio = false;
        notifyListeners();
        return sent ? null : actionErrorMessage;
      }
      return 'No se capturó audio. Intenta grabarlo nuevamente.';
    } catch (error) {
      _recordingTimer?.cancel();
      _recordingTimer = null;
      isRecording = false;
      isSendingAudio = false;
      actionErrorMessage = ApiErrorMessage.from(
        error,
        fallback: 'No fue posible grabar el audio.',
      );
      notifyListeners();
      return actionErrorMessage;
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _realtime.dispose();
    _typingDebounce?.cancel();
    _recordingTimer?.cancel();
    textController.dispose();
    scrollController.dispose();
    super.dispose();
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
}
