import 'package:flutter/material.dart';
import '../../../data/repositories/chat_repository_impl.dart';
import '../../../domain/usecases/get_chat_ai_summary_usecase.dart';
import '../../../domain/usecases/get_chat_messages_usecase.dart';
import '../../../domain/usecases/send_chat_message_usecase.dart';
import '../../controllers/chat_controller.dart';
import '../../widgets/admin_state_feedback.dart';

class FullChatScreen extends StatefulWidget {
  final VoidCallback onBack;
  final ChatController? controller;

  const FullChatScreen({super.key, required this.onBack, this.controller});

  @override
  State<FullChatScreen> createState() => _FullChatScreenState();
}

class _FullChatScreenState extends State<FullChatScreen> {
  late final ChatController _controller;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final repo = ChatRepositoryImpl();
    _controller =
        widget.controller ??
        ChatController(
          getChatMessagesUseCase: GetChatMessagesUseCase(repo),
          sendChatMessageUseCase: SendChatMessageUseCase(repo),
          getChatAISummaryUseCase: GetChatAISummaryUseCase(repo),
        );

    _controller.loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSendMessage() async {
    final text = _messageController.text;
    if (text.trim().isNotEmpty) {
      final enviado = await _controller.sendMessage(text: text);
      if (!enviado) return;
      _messageController.clear();
      if (!_scrollController.hasClients) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  void _showAISummary() async {
    try {
      final summaryText = await _controller.fetchAISummary();

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF1E1E1E),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Colors.purpleAccent,
                      size: 28,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Resumen Inteligente de la Conversación',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  summaryText,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A2A2A),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Entendido',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No fue posible generar el resumen IA.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: widget.onBack,
        ),
        title: const Text(
          'Chat Comunitario',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              avatar: const Icon(
                Icons.auto_awesome,
                color: Colors.purpleAccent,
                size: 18,
              ),
              label: const Text(
                'Resumen IA',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              backgroundColor: Colors.purpleAccent.withValues(alpha: 0.2),
              side: const BorderSide(color: Colors.purpleAccent),
              onPressed: _showAISummary,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔍 Barra de Búsqueda y Filtros por Fecha
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Container(
                color: const Color(0xFF1E1E1E),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: _controller.setSearchQuery,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Filtrar palabras clave o residente...',
                          hintStyle: const TextStyle(color: Colors.white38),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white38,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF2A2A2A),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.calendar_month,
                        color: _controller.selectedDateRange != null
                            ? Colors.greenAccent
                            : Colors.white54,
                      ),
                      onPressed: () async {
                        final range = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2030),
                        );
                        if (range != null) {
                          _controller.setDateRange(range);
                        }
                      },
                    ),
                    if (_controller.selectedDateRange != null)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.redAccent),
                        onPressed: () => _controller.setDateRange(null),
                      ),
                  ],
                ),
              );
            },
          ),

          // 💬 Mensajes
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                if (_controller.isLoading) {
                  return const AdminLoadingState(color: Colors.greenAccent);
                }

                if (_controller.hasError && _controller.messages.isEmpty) {
                  return AdminErrorState(
                    message:
                        _controller.errorMessage ??
                        'No se pudieron cargar los mensajes.',
                    onRetry: _controller.loadMessages,
                  );
                }

                final messages = _controller.filteredMessages;

                if (messages.isEmpty) {
                  return AdminEmptyState(
                    icon: Icons.forum_outlined,
                    title: 'Sin mensajes',
                    message:
                        _controller.searchQuery.isNotEmpty ||
                            _controller.selectedDateRange != null
                        ? 'No hay mensajes que coincidan con los filtros actuales.'
                        : 'El chat aún no tiene mensajes cargados desde la base de datos.',
                    actionLabel: 'Reintentar',
                    onAction: _controller.loadMessages,
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final mostrarFecha =
                        index == 0 ||
                        !_mismoDia(messages[index - 1].date, msg.date);
                    final isAdmin = msg.isAdmin;
                    final isAudio = msg.isAudio;
                    final avatarUrl = msg.avatarUrl;

                    return Column(
                      children: [
                        if (mostrarFecha) _SeparadorFecha(fecha: msg.date),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            mainAxisAlignment: isAdmin
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isAdmin) ...[
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.greenAccent
                                      .withValues(alpha: 0.2),
                                  backgroundImage: avatarUrl != null
                                      ? NetworkImage(avatarUrl)
                                      : null,
                                  child: avatarUrl == null
                                      ? const Icon(
                                          Icons.person,
                                          size: 20,
                                          color: Colors.greenAccent,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 8),
                              ],

                              Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 320,
                                ),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isAdmin
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFF1E1E1E),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(12),
                                    topRight: const Radius.circular(12),
                                    bottomLeft: Radius.circular(
                                      isAdmin ? 12 : 0,
                                    ),
                                    bottomRight: Radius.circular(
                                      isAdmin ? 0 : 12,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msg.sender,
                                      style: TextStyle(
                                        color: isAdmin
                                            ? Colors.white70
                                            : Colors.greenAccent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    if (isAudio)
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.play_arrow,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Container(
                                              height: 4,
                                              color: Colors.white38,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            msg.audioDuration ?? '0:00',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      Text(
                                        msg.text,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Text(
                                        msg.time,
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // 🎙️ Controles de Enviar / Grabar
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final isRecording = _controller.isRecording;
              final seconds = _controller.recordingSeconds;

              return Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFF1E1E1E),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        enabled: !isRecording,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: isRecording
                              ? 'Grabando audio... 0:${seconds.toString().padLeft(2, '0')}'
                              : 'Escribe un mensaje...',
                          hintStyle: TextStyle(
                            color: isRecording
                                ? Colors.redAccent
                                : Colors.white38,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF2A2A2A),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        isRecording ? Icons.stop : Icons.mic,
                        color: isRecording
                            ? Colors.redAccent
                            : Colors.greenAccent,
                      ),
                      onPressed: _controller.toggleRecording,
                    ),
                    IconButton(
                      onPressed: _handleSendMessage,
                      icon: const Icon(Icons.send, color: Colors.greenAccent),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  bool _mismoDia(DateTime primera, DateTime segunda) {
    return primera.year == segunda.year &&
        primera.month == segunda.month &&
        primera.day == segunda.day;
  }
}

class _SeparadorFecha extends StatelessWidget {
  const _SeparadorFecha({required this.fecha});

  final DateTime fecha;

  @override
  Widget build(BuildContext context) {
    final fechaSinHora = DateTime(fecha.year, fecha.month, fecha.day);
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final ayer = hoy.subtract(const Duration(days: 1));
    final etiqueta = fechaSinHora == hoy
        ? 'Hoy'
        : fechaSinHora == ayer
        ? 'Ayer'
        : '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            child: Text(
              etiqueta,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
