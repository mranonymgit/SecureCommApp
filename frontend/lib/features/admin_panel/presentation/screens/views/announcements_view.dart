import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/repositories/announcements_repository_impl.dart';
import '../../../domain/usecases/create_announcement_usecase.dart';
import '../../../domain/usecases/get_announcements_usecase.dart';
import '../../controllers/announcements_controller.dart';
import '../../widgets/admin_state_feedback.dart';

class AnnouncementsView extends StatefulWidget {
  final AnnouncementsController? controller;

  const AnnouncementsView({super.key, this.controller});

  @override
  State<AnnouncementsView> createState() => _AnnouncementsViewState();
}

class _AnnouncementsViewState extends State<AnnouncementsView> {
  late final AnnouncementsController _controller;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    final repo = AnnouncementsRepositoryImpl();
    _controller =
        widget.controller ??
        AnnouncementsController(
          getAnnouncementsUseCase: GetAnnouncementsUseCase(repo),
          createAnnouncementUseCase: CreateAnnouncementUseCase(repo),
        );

    _controller.fetchAnnouncements();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _controller.fetchAnnouncements(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _showAddAnnouncementDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final imageCtrl = TextEditingController();
    final linkCtrl = TextEditingController();
    XFile? selectedImage;
    String category = 'General';
    bool isImportant = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text(
              'Nuevo Comunicado / Aviso',
              style: TextStyle(color: Colors.white),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Título del Comunicado',
                      labelStyle: TextStyle(color: Colors.white60),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final image = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 85,
                      );
                      if (image == null) return;
                      setModalState(() => selectedImage = image);
                    },
                    icon: const Icon(Icons.image_outlined),
                    label: Text(
                      selectedImage == null
                          ? 'Adjuntar imagen desde el dispositivo'
                          : selectedImage!.name,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    dropdownColor: const Color(0xFF2A2A2A),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      labelStyle: TextStyle(color: Colors.white60),
                    ),
                    items:
                        [
                              'General',
                              'Mantenimiento',
                              'Reunión',
                              'Seguridad',
                              'Urgente',
                            ]
                            .map(
                              (cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              ),
                            )
                            .toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: imageCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'URL de la Imagen (Opcional)',
                      hintText: 'https://ejemplo.com/imagen.jpg',
                      hintStyle: TextStyle(color: Colors.white24),
                      labelStyle: TextStyle(color: Colors.white60),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: linkCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Enlace externo (opcional)',
                      hintText: 'https://ejemplo.com',
                      labelStyle: TextStyle(color: Colors.white60),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentCtrl,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Contenido del Comunicado',
                      labelStyle: TextStyle(color: Colors.white60),
                      alignLabelWithHint: true,
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blueAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Checkbox(
                        value: isImportant,
                        activeColor: Colors.redAccent,
                        onChanged: (val) {
                          setModalState(() => isImportant = val ?? false);
                        },
                      ),
                      const Text(
                        'Marcar como Importante',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                ),
                onPressed: () async {
                  if (titleCtrl.text.isNotEmpty &&
                      contentCtrl.text.isNotEmpty) {
                    String? imageUrl = imageCtrl.text.trim().isNotEmpty
                        ? imageCtrl.text.trim()
                        : null;
                    if (selectedImage != null) {
                      imageUrl = await _controller.uploadImage(
                        await selectedImage!.readAsBytes(),
                        selectedImage!.name,
                      );
                      if (imageUrl == null) return;
                    }
                    _controller.addAnnouncement(
                      title: titleCtrl.text.trim(),
                      category: category,
                      content: contentCtrl.text.trim(),
                      imageUrl: imageUrl,
                      linkUrl: linkCtrl.text.trim().isEmpty
                          ? null
                          : linkCtrl.text.trim(),
                      isImportant: isImportant,
                    );
                    Navigator.pop(dialogContext);
                  }
                },
                child: const Text(
                  'Publicar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📢 Encabezado Responsivo
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;

              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Avisos y Comunicados',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Publicación de noticias y avisos oficiales para la comunidad',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _showAddAnnouncementDialog,
                        icon: const Icon(Icons.campaign, color: Colors.white),
                        label: const Text(
                          'Nuevo Comunicado',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Avisos y Comunicados',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Publicación de noticias y avisos oficiales para la comunidad',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onPressed: _showAddAnnouncementDialog,
                    icon: const Icon(Icons.campaign, color: Colors.white),
                    label: const Text(
                      'Nuevo Comunicado',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // 📰 Lista de Comunicados con AnimatedBuilder
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              if (_controller.isLoading) {
                return const AdminLoadingState(color: Colors.blueAccent);
              }

              if (_controller.hasError) {
                return AdminErrorState(
                  message:
                      _controller.errorMessage ??
                      'No se pudieron cargar los comunicados.',
                  onRetry: _controller.fetchAnnouncements,
                );
              }

              if (_controller.announcements.isEmpty) {
                return AdminEmptyState(
                  icon: Icons.campaign_outlined,
                  title: 'Sin comunicados',
                  message:
                      'Aún no hay avisos publicados desde la base de datos.',
                  actionLabel: 'Reintentar',
                  onAction: _controller.fetchAnnouncements,
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _controller.announcements.length,
                itemBuilder: (context, index) {
                  final item = _controller.announcements[index];
                  final hasImage =
                      item.imageUrl != null && item.imageUrl!.isNotEmpty;

                  return Card(
                    color: const Color(0xFF1E1E1E),
                    margin: const EdgeInsets.only(bottom: 20),
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: item.isImportant
                          ? const BorderSide(
                              color: Colors.redAccent,
                              width: 1.5,
                            )
                          : BorderSide.none,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🖼️ Imagen
                        if (hasImage)
                          Image.network(
                            item.imageUrl!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 200,
                                color: const Color(0xFF2A2A2A),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 120,
                                color: const Color(0xFF2A2A2A),
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.broken_image,
                                        color: Colors.white38,
                                        size: 36,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'No se pudo cargar la imagen',
                                        style: TextStyle(
                                          color: Colors.white38,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                        // 📝 Contenido
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      item.category,
                                      style: const TextStyle(
                                        color: Colors.blueAccent,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (item.isImportant) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'Urgente',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const Spacer(),
                                  Text(
                                    item.date.isNotEmpty
                                        ? item.date
                                        : 'Pendiente de fecha',
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                item.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.content,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                              if (item.linkUrl?.isNotEmpty ?? false)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton.icon(
                                    onPressed: () => launchUrl(
                                      Uri.parse(item.linkUrl!),
                                      mode: LaunchMode.externalApplication,
                                    ),
                                    icon: const Icon(
                                      Icons.open_in_new,
                                      size: 17,
                                    ),
                                    label: const Text('Abrir enlace adjunto'),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              const Divider(color: Colors.white12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Publicado por: ${item.author.isNotEmpty ? item.author : 'Pendiente de asignación'}',
                                    style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.share_outlined,
                                      color: Colors.white54,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Enlace del comunicado copiado',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
