import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/network/api_error_message.dart';
import '../../../../../core/services/community_realtime_service.dart';
import '../../domain/entities/faq_item.dart';
import '../../domain/usecases/get_faqs_usecase.dart';

class PreguntasFrecuentesController extends ValueNotifier<bool> {
  final GetFaqsUseCase getFaqsUseCase;

  List<FaqItem> faqs = [];
  String? errorMessage;
  String? actionErrorMessage;
  bool isSubmitting = false;
  StreamSubscription<CommunityChange>? _realtimeSubscription;

  PreguntasFrecuentesController(this.getFaqsUseCase) : super(true);

  Future<void> loadFaqs() async {
    value = true;
    errorMessage = null;
    try {
      faqs = await getFaqsUseCase();
    } catch (e) {
      errorMessage = 'Error al cargar preguntas: ${e.toString()}';
    } finally {
      value = false;
    }
  }

  Future<bool> sendQuestion(String question) async {
    actionErrorMessage = null;
    isSubmitting = true;
    notifyListeners();
    try {
      await getFaqsUseCase.submitQuestion(question);
      return true;
    } catch (e) {
      actionErrorMessage = ApiErrorMessage.from(
        e,
        fallback: 'No fue posible enviar tu pregunta.',
      );
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  void connectRealtime() {
    _realtimeSubscription ??= CommunityRealtimeService.instance
        .watchTables(const {'community_faqs'})
        .listen((_) => unawaited(_refreshSilently()));
  }

  Future<void> _refreshSilently() async {
    try {
      faqs = await getFaqsUseCase();
      errorMessage = null;
      notifyListeners();
    } catch (_) {
      // Keep the current FAQ list visible during transient network failures.
    }
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }
}
