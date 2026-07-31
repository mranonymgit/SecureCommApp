import '../../../../../core/network/api_client.dart';
import '../../domain/entities/mensaje_chat.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/chat_message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;
  String? _threadId;

  Future<String> _defaultThreadId() async {
    if (_threadId != null && _threadId!.isNotEmpty) {
      return _threadId!;
    }
    final data = await _apiClient.getJson('/api/chat/thread/default');
    _threadId = (data['id'] ?? '').toString();
    return _threadId!;
  }

  @override
  Future<List<MensajeChat>> getMensajes() async {
    final threadId = await _defaultThreadId();
    final items = await _apiClient.getList(
      '/api/chat/messages',
      queryParameters: {'thread_id': threadId},
    );
    return items
        .cast<Map<String, dynamic>>()
        .map((item) => MensajeChatModel.fromJson(item, currentUserId: ''))
        .toList(growable: false);
  }

  @override
  Future<MensajeChat> enviarMensaje(MensajeChat mensaje) async {
    final threadId = await _defaultThreadId();
    final data = await _apiClient.postJson('/api/chat/messages', {
      'thread_id': threadId,
      'body': mensaje.texto ?? mensaje.audioUrl ?? '',
      'audio_url': mensaje.audioUrl,
      'audio_duration': mensaje.duracionAudio?.inSeconds.toString(),
    });
    return MensajeChatModel.fromJson(data, currentUserId: '');
  }

  @override
  Future<String> obtenerResumenIA() async {
    final data = await _apiClient.getJson('/api/chat/summary');
    return (data['summary'] ?? '').toString();
  }
}
