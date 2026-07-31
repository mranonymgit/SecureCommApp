import 'package:supabase_flutter/supabase_flutter.dart';

import '../network/api_client.dart';
import '../network/api_config.dart';
import '../network/api_session.dart';

/// Private Broadcast subscription. The message body is re-read from FastAPI so
/// signed media URLs and server-side authorization always remain authoritative.
class ChatRealtimeService {
  RealtimeChannel? _channel;

  bool get isAvailable =>
      ApiConfig.supabaseUrl.isNotEmpty &&
      ApiConfig.supabasePublishableKey.isNotEmpty &&
      (ApiSession.instance.realtimeToken?.isNotEmpty ?? false) &&
      (ApiSession.instance.communityId?.isNotEmpty ?? false);

  Future<void> subscribe(
    Future<void> Function() onChanged, {
    void Function(bool isTyping)? onPeerTyping,
  }) async {
    if (!isAvailable) return;
    final thread = await ApiClient().getJson('/api/chat/thread/default');
    final threadId = (thread['id'] ?? '').toString();
    final communityId = ApiSession.instance.communityId!;
    if (threadId.isEmpty) return;

    await dispose();
    final topic = 'community:$communityId:thread:$threadId';
    final currentUserId = ApiSession.instance.userId;
    final channel = Supabase.instance.client
        .channel(topic, opts: const RealtimeChannelConfig(private: true))
        .onBroadcast(event: 'INSERT', callback: (_) => onChanged())
        .onBroadcast(event: 'UPDATE', callback: (_) => onChanged())
        .onBroadcast(event: 'DELETE', callback: (_) => onChanged())
        .onBroadcast(
          event: 'typing',
          callback: (payload) {
            final nested = payload['payload'];
            final data = nested is Map
                ? nested.cast<String, dynamic>()
                : payload;
            if (data['user_id']?.toString() != currentUserId) {
              onPeerTyping?.call(data['is_typing'] == true);
            }
          },
        );
    _channel = channel;
    channel.subscribe((status, _) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        channel.track({
          'user_id': currentUserId,
          'role': ApiSession.instance.userRole,
          'online_at': DateTime.now().toUtc().toIso8601String(),
        });
      }
    });
  }

  Future<void> setTyping(bool isTyping) async {
    final channel = _channel;
    final userId = ApiSession.instance.userId;
    if (channel == null || userId == null || userId.isEmpty) return;
    await channel.sendBroadcastMessage(
      event: 'typing',
      payload: {'user_id': userId, 'is_typing': isTyping},
    );
  }

  Future<void> dispose() async {
    final channel = _channel;
    _channel = null;
    if (channel != null && ApiConfig.supabaseUrl.isNotEmpty) {
      await Supabase.instance.client.removeChannel(channel);
    }
  }
}
