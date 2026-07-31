import 'package:flutter/material.dart';

import '../../../../../core/presentation/app_toast.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/usecases/get_faqs_usecase.dart';
import '../controllers/preguntas_frecuentes_controller.dart';
import '../widgets/faq_item_tile.dart';
import '../widgets/faq_submit_form_card.dart';

class PreguntasFrecuentesScreen extends StatefulWidget {
  const PreguntasFrecuentesScreen({super.key});

  @override
  State<PreguntasFrecuentesScreen> createState() =>
      _PreguntasFrecuentesScreenState();
}

class _PreguntasFrecuentesScreenState extends State<PreguntasFrecuentesScreen> {
  late final PreguntasFrecuentesController _controller;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nuevaPreguntaController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller =
        PreguntasFrecuentesController(GetFaqsUseCase(SettingsRepositoryImpl()))
          ..loadFaqs()
          ..connectRealtime();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nuevaPreguntaController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _filtrar(String query) {
    setState(() {});
  }

  Future<void> _enviarNuevaPregunta() async {
    final ok = await _controller.sendQuestion(
      _nuevaPreguntaController.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      _nuevaPreguntaController.clear();
      AppToast.success(context, 'Tu pregunta fue enviada al comité.');
    } else {
      AppToast.error(
        context,
        _controller.actionErrorMessage ?? 'No se pudo enviar la pregunta.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Preguntas Frecuentes'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.errorMessage != null) {
            return Center(
              child: FilledButton.icon(
                onPressed: _controller.loadFaqs,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar carga de preguntas'),
              ),
            );
          }

          final query = _searchController.text.toLowerCase();
          final faqs = _controller.faqs.where((faq) {
            if (query.isEmpty) return true;
            return faq.question.toLowerCase().contains(query) ||
                faq.answer.toLowerCase().contains(query);
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _filtrar,
                  decoration: InputDecoration(
                    labelText: 'Buscar en preguntas frecuentes...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: theme.cardColor,
                  ),
                ),
                const SizedBox(height: 20),
                if (faqs.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No se encontraron resultados.',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 
                            0.6,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  ...faqs.map(
                    (faq) => FaqItemTile(
                      pregunta: faq.question,
                      respuesta: faq.answer,
                    ),
                  ),
                const SizedBox(height: 24),
                FaqSubmitFormCard(
                  controller: _nuevaPreguntaController,
                  onSubmit: _enviarNuevaPregunta,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
