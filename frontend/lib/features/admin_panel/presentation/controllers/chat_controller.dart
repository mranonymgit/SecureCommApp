import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error_message.dart';
import '../../../../core/services/chat_audio_recorder.dart';
import '../../../../core/services/chat_realtime_service.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../../domain/usecases/get_chat_ai_summary_usecase.dart';
import '../../domain/usecases/get_chat_messages_usecase.dart';
import '../../domain/usecases/send_chat_message_usecase.dart';

class ChatController extends ChangeNotifier {
  final GetChatMessagesUseCase getChatMessagesUseCase;
  final SendChatMessageUseCase sendChatMessageUseCase;
  final GetChatAISummaryUseCase getChatAISummaryUseCase;

  ChatController({
    required this.getChatMessagesUseCase,
    required this.sendChatMessageUseCase,
    required this.getChatAISummaryUseCase,
  });

  List<ChatMessageEntity> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _actionErrorMessage;
  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;
  final ChatAudioRecorder _audioRecorder = ChatAudioRecorder();
  final ChatRealtimeService _realtime = ChatRealtimeService();
  bool _isRecording = false;
  bool _isSendingAudio = false;
  Duration _recordingDuration = Duration.zero;
  bool _residentIsTyping = false;
  Timer? _typingDebounce;
  Timer? _recordingTimer;

  List<ChatMessageEntity> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get actionErrorMessage => _actionErrorMessage;
  bool get hasError => _errorMessage != null;
  String get searchQuery => _searchQuery;
  DateTimeRange? get selectedDateRange => _selectedDateRange;
  bool get isRecording => _isRecording;
  bool get isSendingAudio => _isSendingAudio;
  String get recordingTimeLabel {
    final minutes = _recordingDuration.inMinutes.toString().padLeft(2, '0');
    final seconds = _recordingDuration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds';
  }

  bool get residentIsTyping => _residentIsTyping;

  List<ChatMessageEntity> get filteredMessages {
    return _messages.where((msg) {
      final query = _searchQuery.toLowerCase();
      final matchesQuery =
          query.isEmpty ||
          msg.text.toLowerCase().contains(query) ||
          msg.sender.toLowerCase().contains(query);

      final matchesDate =
          _selectedDateRange == null ||
          (msg.date.isAfter(_selectedDateRange!.start) &&
              msg.date.isBefore(
                _selectedDateRange!.end.add(const Duration(days: 1)),
              ));

      return matchesQuery && matchesDate;
    }).toList();
  }

  Future<void> loadMessages() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _messages = List<ChatMessageEntity>.from(await getChatMessagesUseCase());
    } catch (e) {
      _messages = [];
      _errorMessage = 'No fue posible cargar los mensajes del chat.';
      debugPrint('Error al cargar mensajes del chat: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshMessagesSilently() async {
    try {
      _messages = List<ChatMessageEntity>.from(await getChatMessagesUseCase());
      _errorMessage = null;
      notifyListeners();
    } catch (error) {
      debugPrint('Error al sincronizar mensajes del chat: $error');
    }
  }

  Future<void> connectRealtime() => _realtime.subscribe(
    refreshMessagesSilently,
    onPeerTyping: (isTyping) {
      _residentIsTyping = isTyping;
      notifyListeners();
    },
  );

  void notifyTyping(String text) {
    _typingDebounce?.cancel();
    if (text.trim().isEmpty) {
      _realtime.setTyping(false);
      return;
    }
    _realtime.setTyping(true);
    _typingDebounce = Timer(const Duration(milliseconds: 900), () {
      _realtime.setTyping(false);
    });
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setDateRange(DateTimeRange? range) {
    _selectedDateRange = range;
    notifyListeners();
  }

  Future<bool> sendMessage({
    required String text,
    bool isAudio = false,
    String? duration,
    String? audioUrl,
  }) async {
    if (text.trim().isEmpty) return false;

    final newMessage = ChatMessageEntity(
      id: '',
      sender: 'Administración',
      avatarUrl: null,
      text: text.trim(),
      audioDuration: duration,
      audioUrl: audioUrl,
      time: 'Ahora',
      date: DateTime.now(),
      isAdmin: true,
      isAudio: isAudio,
    );

    try {
      final sent = await sendChatMessageUseCase(newMessage);
      // La capa de datos expone listas inmutables; crear una nueva colección
      // permite reflejar el mensaje validado por el servidor de inmediato.
      _messages = [..._messages.where((message) => message.id != sent.id), sent]
        ..sort((first, second) => first.date.compareTo(second.date));
      _actionErrorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _actionErrorMessage = ApiErrorMessage.from(
        e,
        fallback: 'No fue posible enviar el mensaje.',
      );
      debugPrint('Error al enviar mensaje: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendAudio(
    Uint8List bytes,
    String filename, {
    Duration? duration,
  }) async {
    try {
      final lower = filename.toLowerCase();
      final contentType = lower.endsWith('.m4a')
          ? 'audio/mp4'
          : lower.endsWith('.ogg')
          ? 'audio/ogg'
          : lower.endsWith('.webm')
          ? 'audio/webm'
          : lower.endsWith('.wav')
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
      return sendMessage(
        text: 'Audio',
        isAudio: true,
        audioUrl: objectPath,
        duration: duration?.inSeconds.toString(),
      );
    } catch (error) {
      _actionErrorMessage = ApiErrorMessage.from(
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
      if (!_isRecording) {
        await _audioRecorder.start();
        _isRecording = true;
        _recordingDuration = Duration.zero;
        _actionErrorMessage = null;
        _recordingTimer?.cancel();
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
          _recordingDuration += const Duration(seconds: 1);
          notifyListeners();
        });
        notifyListeners();
        return null;
      }
      final recording = await _audioRecorder.stop();
      _recordingTimer?.cancel();
      _recordingTimer = null;
      _isRecording = false;
      _isSendingAudio = recording != null;
      notifyListeners();
      if (recording != null) {
        final sent = await sendAudio(
          recording.bytes,
          'admin-${DateTime.now().millisecondsSinceEpoch}.wav',
          duration: recording.duration,
        );
        _isSendingAudio = false;
        notifyListeners();
        return sent ? null : _actionErrorMessage;
      }
      return 'No se capturó audio. Intenta grabarlo nuevamente.';
    } catch (error) {
      _recordingTimer?.cancel();
      _recordingTimer = null;
      _isRecording = false;
      _isSendingAudio = false;
      _actionErrorMessage = ApiErrorMessage.from(
        error,
        fallback: 'No fue posible grabar el audio.',
      );
      notifyListeners();
      return _actionErrorMessage;
    }
  }

  Future<String> fetchAISummary() async {
    try {
      return await getChatAISummaryUseCase();
    } catch (e) {
      debugPrint('Error al generar el resumen IA del chat: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _realtime.dispose();
    _typingDebounce?.cancel();
    _recordingTimer?.cancel();
    super.dispose();
  }
}
