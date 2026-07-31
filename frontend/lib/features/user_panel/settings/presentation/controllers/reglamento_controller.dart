import 'package:flutter/material.dart';
import '../../domain/entities/rule_item.dart';
import '../../domain/usecases/get_rules_usecase.dart';

class ReglamentoController extends ValueNotifier<bool> {
  final GetRulesUseCase getRulesUseCase;

  List<RuleItem> rules = [];
  String? errorMessage;

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
}