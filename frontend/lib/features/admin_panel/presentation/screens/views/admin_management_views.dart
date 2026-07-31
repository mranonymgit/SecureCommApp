import 'package:flutter/material.dart';
import '../../../../../core/network/api_client.dart';
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
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _items = await _api.getList('/api/admin/password-change-requests');
    } catch (_) {
      _error = 'No fue posible cargar las solicitudes.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _review(String id, bool approve) async {
    try {
      await _api.postJson(
        '/api/admin/password-change-requests/$id/${approve ? 'approve' : 'reject'}',
        {},
      );
      await _load();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo procesar la solicitud.')),
        );
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
    if (_title.text.trim().isEmpty || _description.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await _api.postJson('/api/admin/community/rules', {
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'display_order': 0,
      });
      _title.clear();
      _description.clear();
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Reglamento publicado.')));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo publicar el reglamento.')),
        );
    }
    if (mounted) setState(() => _saving = false);
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
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _question.dispose();
    _answer.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      _submitted = await _api.getList('/api/admin/community/faqs/questions');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    if (_question.text.trim().isEmpty || _answer.text.trim().isEmpty) return;
    await _api.postJson('/api/admin/community/faqs', {
      'question': _question.text.trim(),
      'answer': _answer.text.trim(),
    });
    _question.clear();
    _answer.clear();
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pregunta frecuente publicada.')),
      );
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
      await _api.postJson(
        '/api/admin/community/faqs/questions/${item['id']}/answer',
        {'answer': answer.text.trim()},
      );
      await _load();
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
