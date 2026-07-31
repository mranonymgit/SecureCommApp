import '../../../../core/network/api_client.dart';
import '../../domain/entities/chat_message_entity.dart';
import '../models/chat_message_model.dart';

abstract class ChatService {
  Future<List<ChatMessageModel>> fetchMessages();
  Future<ChatMessageModel> sendMessage(ChatMessageEntity message);
  Future<String> fetchAISummary();
}

class ChatServiceImpl implements ChatService {
  final ApiClient _apiClient;

  ChatServiceImpl({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<String> _defaultThreadId() async {
    final data = await _apiClient.getJson('/api/chat/thread/default');
    return (data['id'] ?? '').toString();
  }

  @override
  Future<List<ChatMessageModel>> fetchMessages() async {
    final threadId = await _defaultThreadId();
    final items = await _apiClient.getList('/api/chat/messages', queryParameters: {'thread_id': threadId});
    return items.cast<Map<String, dynamic>>().map(ChatMessageModel.fromJson).toList(growable: false);
  }

  @override
  Future<ChatMessageModel> sendMessage(ChatMessageEntity message) async {
    final threadId = await _defaultThreadId();
    final payload = {
      'thread_id': threadId,
      'body': message.text,
      'audio_url': null,
      'audio_duration': message.audioDuration,
    };
    final data = await _apiClient.postJson('/api/chat/messages', payload);
    return ChatMessageModel.fromJson(data);
  }

  @override
  Future<String> fetchAISummary() async {
    final data = await _apiClient.getJson('/api/chat/summary');
    return (data['summary'] ?? '').toString();
  }
}
