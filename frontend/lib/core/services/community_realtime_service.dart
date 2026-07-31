import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../network/api_client.dart';
import '../network/api_config.dart';
import '../network/api_session.dart';

class CommunityChange {
  const CommunityChange({required this.table, required this.action});

  final String table;
  final String action;
}

/// Owns exactly one private community channel and fans typed change signals out
/// to feature controllers. Data is still reconciled through FastAPI.
class CommunityRealtimeService {
  CommunityRealtimeService._();

  static final CommunityRealtimeService instance = CommunityRealtimeService._();

  final StreamController<CommunityChange> _changes =
      StreamController<CommunityChange>.broadcast(sync: true);
  RealtimeChannel? _channel;
  Future<void>? _connecting;
  Timer? _tokenRefreshTimer;
  String? _connectedCommunityId;
  bool _refreshingToken = false;

  bool get _isConfigured =>
      ApiConfig.supabaseUrl.isNotEmpty &&
      ApiConfig.supabasePublishableKey.isNotEmpty &&
      (ApiSession.instance.realtimeToken?.isNotEmpty ?? false) &&
      (ApiSession.instance.communityId?.isNotEmpty ?? false);

  Stream<CommunityChange> watchTables(Iterable<String> tables) {
    final accepted = tables.toSet();
    unawaited(ensureConnected());
    return _changes.stream.where((change) => accepted.contains(change.table));
  }

  Future<void> ensureConnected() {
    if (!_isConfigured) return Future.value();
    final communityId = ApiSession.instance.communityId!;
    if (_channel != null && _connectedCommunityId == communityId) {
      return Future.value();
    }
    return _connecting ??= _connect(communityId).whenComplete(() {
      _connecting = null;
    });
  }

  Future<void> _connect(String communityId) async {
    await disconnect();
    final channel = Supabase.instance.client
        .channel(
          'community:$communityId:changes',
          opts: const RealtimeChannelConfig(private: true),
        )
        .onBroadcast(
          event: 'INSERT',
          callback: (payload) => _emit(payload, 'INSERT'),
        )
        .onBroadcast(
          event: 'UPDATE',
          callback: (payload) => _emit(payload, 'UPDATE'),
        )
        .onBroadcast(
          event: 'DELETE',
          callback: (payload) => _emit(payload, 'DELETE'),
        );
    _channel = channel;
    _connectedCommunityId = communityId;
    channel.subscribe();
    _tokenRefreshTimer = Timer.periodic(
      const Duration(minutes: 8),
      (_) => unawaited(_refreshRealtimeToken()),
    );
  }

  void _emit(Map<String, dynamic> envelope, String action) {
    final payload = envelope['payload'];
    final data = payload is Map ? payload.cast<String, dynamic>() : envelope;
    final table = (data['table'] ?? data['table_name'] ?? '').toString();
    if (table.isNotEmpty && !_changes.isClosed) {
      _changes.add(CommunityChange(table: table, action: action));
    }
  }

  Future<void> _refreshRealtimeToken() async {
    if (_refreshingToken || !ApiSession.instance.hasToken) return;
    _refreshingToken = true;
    try {
      final response = await ApiClient().postJson(
        '/api/auth/realtime-token',
        const {},
      );
      final token = (response['realtime_token'] ?? '').toString();
      if (token.isNotEmpty) {
        ApiSession.instance.realtimeToken = token;
        await Supabase.instance.client.realtime.setAuth(token);
      }
    } catch (_) {
      // A temporary refresh failure must not interrupt the current screen.
    } finally {
      _refreshingToken = false;
    }
  }

  Future<void> disconnect() async {
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;
    final channel = _channel;
    _channel = null;
    _connectedCommunityId = null;
    if (channel != null && ApiConfig.supabaseUrl.isNotEmpty) {
      await Supabase.instance.client.removeChannel(channel);
    }
  }
}
