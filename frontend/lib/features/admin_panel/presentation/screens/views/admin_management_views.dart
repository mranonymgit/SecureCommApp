import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_error_message.dart';
import '../../../../../core/presentation/app_toast.dart';
import '../../../../../core/services/community_realtime_service.dart';
import '../../../../user_panel/settings/presentation/screens/perfil_screen.dart';
import '../../widgets/admin_state_feedback.dart';

class AdminProfileView extends StatelessWidget {
  const AdminProfileView({super.key});

  @override
  Widget build(BuildContext context) => const PerfilScreen();
}

class PasswordRequestsView extends StatefulWidget {
  const PasswordRequestsView({super.key});

  @override
  State<PasswordRequestsView> createState() => _PasswordRequestsViewState();
}

class _PasswordRequestsViewState extends State<PasswordRequestsView> {
  final _api = ApiClient();
  List<dynamic> _items = const [];
  bool _loading = true;
  bool _refreshing = false;
  String? _error;
  StreamSubscription<CommunityChange>? _realtimeSubscription;

  @override
  void initState() {
    super.initState();
    _load();
    _realtimeSubscription = CommunityRealtimeService.instance
        .watchTables(const {'password_change_requests'})
        .listen((_) => unawaited(_load(showLoading: false)));
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (_refreshing) return;
    _refreshing = true;
    if (showLoading && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final items = await _api.getList('/api/admin/password-change-requests');
      if (mounted) {
        setState(() {
          _items = items;
          _error = null;
        });
      }
    } catch (_) {
      if (showLoading && mounted) {
        setState(() => _error = 'No fue posible cargar las solicitudes.');
      }
    } finally {
      _refreshing = false;
      if (showLoading && mounted) setState(() => _loading = false);
    }
  }

  Future<void> _review(String id, bool approve) async {
    final expectedStatus = approve ? 'approved' : 'rejected';
    try {
      await _api.postJson(
        '/api/admin/password-change-requests/$id/${approve ? 'approve' : 'reject'}',
        {},
      );
      await _load(showLoading: false);
      if (mounted) AppToast.success(context, 'Solicitud procesada.');
    } catch (error) {
      try {
        final canonical = await _api.getList(
          '/api/admin/password-change-requests',
        );
        final saved = canonical.any(
          (raw) =>
              raw is Map &&
              raw['id'].toString() == id &&
              raw['status'].toString() == expectedStatus,
        );
        if (saved) {
          if (mounted) setState(() => _items = canonical);
          if (mounted) AppToast.success(context, 'Solicitud procesada.');
          return;
        }
      } catch (_) {}
      if (mounted) {
        AppToast.error(
          context,
          ApiErrorMessage.from(
            error,
            fallback: 'No se pudo procesar la solicitud.',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => _ManagementScaffold(
    title: 'Cambios de contraseña',
    subtitle: 'Aprueba o rechaza las solicitudes pendientes de residentes.',
    child: _loading
        ? const AdminLoadingState(color: Colors.blueAccent)
        : _error != null
        ? AdminErrorState(message: _error!, onRetry: _load)
        : _items.isEmpty
        ? AdminEmptyState(
            icon: Icons.lock_reset_outlined,
            title: 'Sin solicitudes',
            message: 'No hay cambios de contraseña pendientes.',
            actionLabel: 'Actualizar',
            onAction: _load,
          )
        : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = _items[index] as Map<String, dynamic>;
              final pending = item['status'] == 'pending';
              return Card(
                color: const Color(0xFF1E1E1E),
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.blueAccent),
                  title: Text(
                    (item['full_name'] ?? 'Residente').toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '${item['email'] ?? ''}\nEstado: ${item['status']}',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  isThreeLine: true,
                  trailing: pending
                      ? Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              tooltip: 'Rechazar',
                              onPressed: () =>
                                  _review(item['id'].toString(), false),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.redAccent,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Aprobar',
                              onPressed: () =>
                                  _review(item['id'].toString(), true),
                              icon: const Icon(
                                Icons.check,
                                color: Colors.greenAccent,
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
              );
            },
          ),
  );
}

class RulesManagementView extends StatefulWidget {
  const RulesManagementView({super.key});
  @override
  State<RulesManagementView> createState() => _RulesManagementViewState();
}

class _RulesManagementViewState extends State<RulesManagementView> {
  final _api = ApiClient();
  final _title = TextEditingController();
  final _description = TextEditingController();
  bool _saving = false;
  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final description = _description.text.trim();
    if (title.isEmpty || description.isEmpty) {
      AppToast.error(context, 'Completa el título y la descripción.');
      return;
    }
    setState(() => _saving = true);
    try {
      await _api.postJson('/api/admin/community/rules', {
        'title': title,
        'description': description,
        'display_order': 0,
      });
      _finishSuccessfulSave();
    } catch (error) {
      try {
        final canonical = await _api.getList('/api/community/rules');
        final saved = canonical.any(
          (raw) =>
              raw is Map &&
              raw['title'].toString() == title &&
              raw['description'].toString() == description,
        );
        if (saved) {
          _finishSuccessfulSave();
          return;
        }
      } catch (_) {}
      if (mounted) {
        AppToast.error(
          context,
          ApiErrorMessage.from(
            error,
            fallback: 'No se pudo publicar el reglamento.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _finishSuccessfulSave() {
    _title.clear();
    _description.clear();
    if (mounted) AppToast.success(context, 'Reglamento publicado.');
  }

  @override
  Widget build(BuildContext context) => _ManagementScaffold(
    title: 'Reglamento de convivencia',
    subtitle: 'Publica reglas visibles para todos los residentes.',
    child: _FormCard(
      children: [
        TextField(
          controller: _title,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Título'),
        ),
        TextField(
          controller: _description,
          maxLines: 5,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Regla y explicación'),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: const Icon(Icons.publish),
          label: const Text('Publicar regla'),
        ),
      ],
    ),
  );
}

class FaqManagementView extends StatefulWidget {
  const FaqManagementView({super.key});
  @override
  State<FaqManagementView> createState() => _FaqManagementViewState();
}

class _FaqManagementViewState extends State<FaqManagementView> {
  final _api = ApiClient();
  final _question = TextEditingController();
  final _answer = TextEditingController();
  List<dynamic> _submitted = const [];
  bool _loading = true;
  bool _refreshing = false;
  StreamSubscription<CommunityChange>? _realtimeSubscription;
  @override
  void initState() {
    super.initState();
    _load();
    _realtimeSubscription = CommunityRealtimeService.instance
        .watchTables(const {'community_faqs', 'faq_questions'})
        .listen((_) => unawaited(_load(showLoading: false)));
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    _question.dispose();
    _answer.dispose();
    super.dispose();
  }

  Future<void> _load({bool showLoading = true}) async {
    if (_refreshing) return;
    _refreshing = true;
    if (showLoading && mounted) setState(() => _loading = true);
    try {
      final submitted = await _api.getList(
        '/api/admin/community/faqs/questions',
      );
      if (mounted) setState(() => _submitted = submitted);
    } catch (error) {
      if (showLoading && mounted) {
        AppToast.error(
          context,
          ApiErrorMessage.from(
            error,
            fallback: 'No fue posible cargar las preguntas.',
          ),
        );
      }
    } finally {
      _refreshing = false;
      if (showLoading && mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final question = _question.text.trim();
    final answer = _answer.text.trim();
    if (question.isEmpty || answer.isEmpty) {
      AppToast.error(context, 'Completa la pregunta y su respuesta.');
      return;
    }
    try {
      await _api.postJson('/api/admin/community/faqs', {
        'question': question,
        'answer': answer,
      });
      _finishSuccessfulFaq();
    } catch (error) {
      try {
        final canonical = await _api.getList('/api/community/faqs');
        final saved = canonical.any(
          (raw) =>
              raw is Map &&
              raw['question'].toString() == question &&
              raw['answer'].toString() == answer,
        );
        if (saved) {
          _finishSuccessfulFaq();
          return;
        }
      } catch (_) {}
      if (mounted) {
        AppToast.error(
          context,
          ApiErrorMessage.from(
            error,
            fallback: 'No se pudo publicar la pregunta frecuente.',
          ),
        );
      }
    }
  }

  void _finishSuccessfulFaq() {
    _question.clear();
    _answer.clear();
    if (mounted) {
      AppToast.success(context, 'Pregunta frecuente publicada.');
    }
  }

  Future<void> _answerSubmitted(Map<String, dynamic> item) async {
    final answer = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Responder pregunta'),
        content: TextField(
          controller: answer,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Respuesta'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Publicar'),
          ),
        ],
      ),
    );
    if (accepted == true && answer.text.trim().isNotEmpty) {
      try {
        await _api.postJson(
          '/api/admin/community/faqs/questions/${item['id']}/answer',
          {'answer': answer.text.trim()},
        );
        await _load(showLoading: false);
        if (mounted) AppToast.success(context, 'Respuesta publicada.');
      } catch (error) {
        await _load(showLoading: false);
        final saved = _submitted.any(
          (raw) =>
              raw is Map &&
              raw['id'].toString() == item['id'].toString() &&
              raw['status'].toString() != 'pending',
        );
        if (mounted) {
          if (saved) {
            AppToast.success(context, 'Respuesta publicada.');
          } else {
            AppToast.error(
              context,
              ApiErrorMessage.from(
                error,
                fallback: 'No se pudo publicar la respuesta.',
              ),
            );
          }
        }
      }
    }
    answer.dispose();
  }

  @override
  Widget build(BuildContext context) => _ManagementScaffold(
    title: 'Preguntas frecuentes',
    subtitle: 'Publica respuestas y atiende preguntas enviadas por residentes.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FormCard(
          children: [
            TextField(
              controller: _question,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Pregunta'),
            ),
            TextField(
              controller: _answer,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Respuesta'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _create,
              icon: const Icon(Icons.add),
              label: const Text('Agregar FAQ'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Preguntas de residentes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else
          ..._submitted.map((raw) {
            final item = raw as Map<String, dynamic>;
            return Card(
              color: const Color(0xFF1E1E1E),
              child: ListTile(
                title: Text(
                  item['question'].toString(),
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${item['full_name']} · ${item['status']}',
                  style: const TextStyle(color: Colors.white54),
                ),
                trailing: item['status'] == 'pending'
                    ? IconButton(
                        onPressed: () => _answerSubmitted(item),
                        icon: const Icon(Icons.reply, color: Colors.blueAccent),
                      )
                    : null,
              ),
            );
          }),
      ],
    ),
  );
}

class _ManagementScaffold extends StatelessWidget {
  const _ManagementScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(subtitle, style: const TextStyle(color: Colors.white54)),
        const SizedBox(height: 24),
        child,
      ],
    ),
  );
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFF1E1E1E),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: children),
    ),
  );
}
