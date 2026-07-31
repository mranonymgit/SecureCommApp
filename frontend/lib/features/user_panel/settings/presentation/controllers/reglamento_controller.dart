import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/services/community_realtime_service.dart';
import '../../domain/entities/rule_item.dart';
import '../../domain/usecases/get_rules_usecase.dart';

class ReglamentoController extends ValueNotifier<bool> {
  final GetRulesUseCase getRulesUseCase;

  List<RuleItem> rules = [];
  String? errorMessage;
  StreamSubscription<CommunityChange>? _realtimeSubscription;

  ReglamentoController(this.getRulesUseCase) : super(true); // true = isLoading

  Future<void> loadRules() async {
    value = true;
    errorMessage = null;
    try {
      rules = await getRulesUseCase();
    } catch (e) {
      errorMessage = 'Error al cargar el reglamento: ${e.toString()}';
    } finally {
      value = false;
    }
  }

  void connectRealtime() {
    _realtimeSubscription ??= CommunityRealtimeService.instance
        .watchTables(const {'community_rules'})
        .listen((_) => unawaited(_refreshSilently()));
  }

  Future<void> _refreshSilently() async {
    try {
      rules = await getRulesUseCase();
      errorMessage = null;
      notifyListeners();
    } catch (_) {
      // Keep the current rules visible while connectivity is restored.
    }
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }
}
