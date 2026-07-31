import 'package:flutter/material.dart';
import 'package:frontend/features/user_panel/settings/data/repositories/settings_repository_impl.dart';
import 'package:frontend/features/user_panel/settings/domain/usecases/get_rules_usecase.dart';
import 'package:frontend/features/user_panel/settings/presentation/controllers/reglamento_controller.dart';
import 'package:frontend/features/user_panel/settings/presentation/widgets/rule_item_card.dart';

class ReglamentoScreen extends StatefulWidget {
  final GetRulesUseCase? getRulesUseCase;

  const ReglamentoScreen({super.key, this.getRulesUseCase});

  @override
  State<ReglamentoScreen> createState() => _ReglamentoScreenState();
}

class _ReglamentoScreenState extends State<ReglamentoScreen> {
  late final ReglamentoController _controller;

  @override
  void initState() {
    super.initState();
    // Si no recibe el UseCase, usa la implementación por defecto del repositorio
    final useCase =
        widget.getRulesUseCase ?? GetRulesUseCase(SettingsRepositoryImpl());
    _controller = ReglamentoController(useCase);
    _controller.loadRules();
    _controller.connectRealtime();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Reglamento de Convivencia'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: _controller,
        builder: (context, isLoading, child) {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.errorMessage != null) {
            return Center(
              child: FilledButton.icon(
                onPressed: _controller.loadRules,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar carga del reglamento'),
              ),
            );
          }

          if (_controller.rules.isEmpty) {
            return Center(
              child: Text(
                'La administración aún no ha publicado el reglamento.',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: _controller.rules.length,
            itemBuilder: (context, index) {
              final regla = _controller.rules[index];
              return RuleItemCard(
                titulo: regla.title,
                descripcion: regla.description,
              );
            },
          );
        },
      ),
    );
  }
}
