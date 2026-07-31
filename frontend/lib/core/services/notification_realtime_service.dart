import 'package:supabase_flutter/supabase_flutter.dart';

import '../network/api_config.dart';
import '../network/api_session.dart';

/// Receives private notification signals without polling. The UI obtains the
/// authoritative notification detail from FastAPI when it is open.
class NotificationRealtimeService {
  RealtimeChannel? _channel;

  Future<void> subscribe(void Function() onChanged) async {
    final token = ApiSession.instance.realtimeToken;
    final communityId = ApiSession.instance.communityId;
    final userId = ApiSession.instance.userId;
    if (ApiConfig.supabaseUrl.isEmpty ||
        ApiConfig.supabasePublishableKey.isEmpty ||
        token == null ||
        token.isEmpty ||
        communityId == null ||
        userId == null ||
        communityId.isEmpty ||
        userId.isEmpty) {
      return;
    }
    await dispose();
    _channel = Supabase.instance.client
        .channel(
          'community:$communityId:user:$userId',
          opts: const RealtimeChannelConfig(private: true),
        )
        .onBroadcast(event: 'INSERT', callback: (_) => onChanged())
        .onBroadcast(event: 'UPDATE', callback: (_) => onChanged())
        .onBroadcast(event: 'DELETE', callback: (_) => onChanged())
        .subscribe();
  }

  Future<void> dispose() async {
    final channel = _channel;
    _channel = null;
    if (channel != null && ApiConfig.supabaseUrl.isNotEmpty) {
      await Supabase.instance.client.removeChannel(channel);
    }
  }
}
