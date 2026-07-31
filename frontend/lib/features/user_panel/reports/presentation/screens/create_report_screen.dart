import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../data/repositories/reports_repository_impl.dart';
import '../../domain/usecases/create_report_usecase.dart';
import '../controllers/create_report_controller.dart';
import '../widgets/image_loading_skeleton.dart';
import '../../../../../core/presentation/app_toast.dart';

class CreateReportScreen extends StatefulWidget {
  final CreateReportController? controller;

  const CreateReportScreen({super.key, this.controller});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  late final CreateReportController _controller;
  final MapController _mapController = MapController();
  bool _mapReady = false;
  static const LatLng _defaultCenter = LatLng(19.432608, -99.133209);

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ??
        CreateReportController(CreateReportUseCase(ReportsRepositoryImpl()));
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.disposeControllers();
    super.dispose();
  }

  void _onGetLocationPressed() async {
    await _controller.obtenerUbicacion();
    if (_controller.errorMessage != null && mounted) {
      AppToast.error(context, _controller.errorMessage!);
    } else if (_controller.hasLocation && _mapReady) {
      _mapController.move(
        LatLng(_controller.latitude!, _controller.longitude!),
        17,
      );
    }
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
    if (_controller.errorMessage != null && mounted) {
      AppToast.error(context, _controller.errorMessage!);
    }
  }

  Widget _buildImagePreview() {
    if (_controller.imageBytes != null) {
      return Image.memory(
        _controller.imageBytes!,
        width: double.infinity,
        fit: BoxFit.contain,
      );
    } else if (!kIsWeb && _controller.selectedImage != null) {
      return Image.file(
        File(_controller.selectedImage!.path),
        width: double.infinity,
        fit: BoxFit.contain,
      );
    }
    return const SizedBox.shrink();
  }

  void _onSubmit() async {
    FocusScope.of(context).unfocus();
    final success = await _controller.sendReport();

    if (!mounted) return;
    if (success) {
      AppToast.success(context, 'Reporte enviado con éxito.');
    } else if (_controller.errorMessage != null) {
      AppToast.error(context, _controller.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          height: double.infinity,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crear Reporte Vecinal',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _controller.tituloController,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Título',
                    prefixIcon: Icon(
                      Icons.title_sharp,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller.descripcionController,
                  maxLines: null,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Descripción del problema',
                    prefixIcon: Icon(
                      Icons.description,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Ubicación del incidente',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _controller.isLoadingLocation
                      ? null
                      : _onGetLocationPressed,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  icon: _controller.isLoadingLocation
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(
                    _controller.hasLocation
                        ? 'Actualizar ubicación'
                        : 'Obtener coordenadas del incidente',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 260,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter:
                                _controller.hasLocation &&
                                    _controller.latitude != null &&
                                    _controller.longitude != null
                                ? LatLng(
                                    _controller.latitude!,
                                    _controller.longitude!,
                                  )
                                : _defaultCenter,
                            initialZoom: 16,
                            onMapReady: () => _mapReady = true,
                            onTap: (_, point) {
                              _controller.updateLocation(
                                point.latitude,
                                point.longitude,
                              );
                              if (_mapReady) {
                                _mapController.move(point, 17);
                              }
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.SCA.reportes',
                              keepBuffer: 0,
                              panBuffer: 0,
                              tileDisplay: const TileDisplay.instantaneous(),
                            ),
                            MarkerLayer(
                              markers: [
                                if (_controller.latitude != null &&
                                    _controller.longitude != null)
                                  Marker(
                                    point: LatLng(
                                      _controller.latitude!,
                                      _controller.longitude!,
                                    ),
                                    width: 50,
                                    height: 50,
                                    child: Icon(
                                      Icons.location_on,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                      size: 42,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 12,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).cardColor.withValues(alpha: 0.88),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Text(
                                _controller.hasLocation
                                    ? 'Puedes mover el pin tocando un punto del mapa.'
                                    : 'Toca el mapa para colocar el pin de tu reporte o usa tu ubicación actual.',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _controller.isLoadingImage
                      ? null
                      : _showImageSourceOptions,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.attach_file),
                  label: Text(
                    _controller.selectedImage == null
                        ? 'Adjuntar evidencia'
                        : 'Cambiar evidencia',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                if (_controller.isLoadingImage) ...[
                  const SizedBox(height: 16),
                  const ImageLoadingSkeleton(),
                ] else if (_controller.selectedImage != null) ...[
                  const SizedBox(height: 16),
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: _buildImagePreview(),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: 0.87),
                          child: IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            onPressed: _controller.removeImage,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: _controller.isSubmitting ? null : _onSubmit,
                  icon: _controller.isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: const Text('Enviar Reporte'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
