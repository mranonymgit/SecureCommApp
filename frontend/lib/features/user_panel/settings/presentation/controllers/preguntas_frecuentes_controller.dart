import 'package:flutter/material.dart';
import '../../domain/entities/faq_item.dart';
import '../../domain/usecases/get_faqs_usecase.dart';

class PreguntasFrecuentesController extends ValueNotifier<bool> {
  final GetFaqsUseCase getFaqsUseCase;

  List<FaqItem> faqs = [];
  String? errorMessage;
  bool isSubmitting = false;

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
    isSubmitting = true;
    notifyListeners();
    try {
      await getFaqsUseCase.submitQuestion(question);
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}