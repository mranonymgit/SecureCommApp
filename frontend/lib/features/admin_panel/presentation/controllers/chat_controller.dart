import 'dart:async';
import 'package:flutter/material.dart';
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
  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;

  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _timer;

  List<ChatMessageEntity> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  String get searchQuery => _searchQuery;
  DateTimeRange? get selectedDateRange => _selectedDateRange;
  bool get isRecording => _isRecording;
  int get recordingSeconds => _recordingSeconds;

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
  }) async {
    if (text.trim().isEmpty) return false;

    final newMessage = ChatMessageEntity(
      id: '',
      sender: 'Administración',
      avatarUrl: null,
      text: text.trim(),
      audioDuration: duration,
      time: 'Ahora',
      date: DateTime.now(),
      isAdmin: true,
      isAudio: isAudio,
    );

    try {
      final sent = await sendChatMessageUseCase(newMessage);
      // La capa de datos expone listas inmutables; crear una nueva colección
      // permite reflejar el mensaje validado por el servidor de inmediato.
      _messages = [..._messages, sent];
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'No fue posible enviar el mensaje.';
      debugPrint('Error al enviar mensaje: $e');
      notifyListeners();
      return false;
    }
  }

  void toggleRecording() {
    if (_isRecording) {
      _timer?.cancel();
      _isRecording = false;
      _recordingSeconds = 0;
      _errorMessage =
          'El envío de audio requiere integrar almacenamiento y grabación reales.';
      notifyListeners();
    } else {
      _isRecording = true;
      _recordingSeconds = 0;
      notifyListeners();

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingSeconds++;
        notifyListeners();
      });
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
    _timer?.cancel();
    super.dispose();
  }
}
