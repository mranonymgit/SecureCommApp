import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/presentation/app_toast.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_avatar_picker.dart';
import '../widgets/profile_text_field.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  late final ProfileController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ProfileController()..loadProfile();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showImageSourceOptions() {
    if (kIsWeb) {
      _pickImage(ImageSource.gallery);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(
                Icons.photo_library,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'Galería',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.camera_alt,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                'Tomar foto',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    await _controller.pickImage(source);
    final error = _controller.actionErrorMessage;
    if (error != null && mounted) AppToast.error(context, error);
  }

  Future<void> _useCurrentLocation() async {
    await _controller.useCurrentLocation();
    final error = _controller.actionErrorMessage;
    if (error != null && mounted) AppToast.error(context, error);
  }

  Future<void> _guardar() async {
    final ok = await _controller.saveProfile();
    if (!mounted) return;
    if (ok) {
      AppToast.success(context, 'Perfil actualizado.');
    } else {
      AppToast.error(
        context,
        _controller.actionErrorMessage ?? 'No se pudo guardar el perfil.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Mi Perfil',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.loadErrorMessage != null) {
            return Center(
              child: FilledButton.icon(
                onPressed: _controller.loadProfile,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar carga del perfil'),
              ),
            );
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _showImageSourceOptions,
                      child: ProfileAvatarPicker(
                        imageFile: _controller.selectedImage,
                        avatarDataUrl: _controller.avatarDataUrl,
                        onPickImage: _showImageSourceOptions,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _controller.nameController.text.isEmpty
                          ? 'Perfil de residente'
                          : _controller.nameController.text,
                      style: TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    ProfileTextField(
                      label: 'Nombre completo',
                      hint: 'Escriba su nombre...',
                      icon: Icons.person_outline,
                      controller: _controller.nameController,
                    ),
                    ProfileTextField(
                      label: 'Correo Electrónico',
                      hint: 'Escriba el nuevo correo...',
                      icon: Icons.email_outlined,
                      controller: _controller.emailController,
                    ),
                    ProfileTextField(
                      label: 'Número telefónico',
                      hint: 'Escriba el nuevo número...',
                      icon: Icons.phone_outlined,
                      controller: _controller.phoneController,
                    ),
                    ProfileTextField(
                      label: 'Dirección',
                      hint: 'Escriba su dirección...',
                      icon: Icons.location_on_outlined,
                      controller: _controller.addressController,
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _useCurrentLocation,
                        icon: const Icon(Icons.my_location),
                        label: const Text('Usar ubicación actual'),
                      ),
                    ),
                    if (_controller.latitude != null &&
                        _controller.longitude != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Coordenadas: ${_controller.latitude!.toStringAsFixed(6)}, ${_controller.longitude!.toStringAsFixed(6)}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(alpha: 
                              0.68,
                            ),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24.0),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _controller.isSaving ? null : _guardar,
                        icon: _controller.isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.check_circle_outline,
                                size: 22.0,
                              ),
                        label: const Text(
                          'Guardar cambios',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
