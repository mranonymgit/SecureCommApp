import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entities/community_report.dart';
import '../../domain/usecases/create_report_usecase.dart';

class CreateReportController extends ChangeNotifier {
  final CreateReportUseCase createReportUseCase;

  CreateReportController(this.createReportUseCase);

  final TextEditingController tituloController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();

  XFile? selectedImage;
  Uint8List? imageBytes;
  bool isLoadingImage = false;

  double? latitude;
  double? longitude;
  bool isLoadingLocation = false;
  bool hasLocation = false;

  bool isSubmitting = false;
  String? errorMessage;

  Future<void> obtenerUbicacion() async {
    isLoadingLocation = true;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('El servicio de ubicación está desactivado.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permiso denegado.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permisos denegados permanentemente.');
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      latitude = position.latitude;
      longitude = position.longitude;
      hasLocation = true;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      isLoadingLocation = false;
      notifyListeners();
    }
  }

  void updateLocation(double lat, double lng) {
    latitude = lat;
    longitude = lng;
    hasLocation = true;
    notifyListeners();
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (image != null) {
        isLoadingImage = true;
        notifyListeners();

        final Uint8List bytes = await image.readAsBytes();
        if (bytes.lengthInBytes / (1024 * 1024) > 5) {
          errorMessage = 'La imagen excede el límite de 5MB.';
        } else {
          selectedImage = image;
          imageBytes = bytes;
        }
      }
    } catch (e) {
      errorMessage = 'Error al seleccionar imagen: $e';
    } finally {
      isLoadingImage = false;
      notifyListeners();
    }
  }

  void removeImage() {
    selectedImage = null;
    imageBytes = null;
    notifyListeners();
  }

  Future<bool> sendReport() async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (tituloController.text.trim().isEmpty ||
          descripcionController.text.trim().isEmpty) {
        throw Exception('Captura el título y la descripción del reporte.');
      }
      if (!hasLocation || latitude == null || longitude == null) {
        throw Exception(
          'Selecciona la ubicación exacta antes de enviar el reporte.',
        );
      }
      final report = CommunityReport(
        title: tituloController.text,
        description: descripcionController.text,
        latitude: latitude!,
        longitude: longitude!,
        imageBytes: imageBytes,
        imagePath: selectedImage?.path,
      );

      await createReportUseCase(report);
      clearForm();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  void clearForm() {
    tituloController.clear();
    descripcionController.clear();
    selectedImage = null;
    imageBytes = null;
    latitude = null;
    longitude = null;
    hasLocation = false;
    notifyListeners();
  }

  void disposeControllers() {
    tituloController.dispose();
    descripcionController.dispose();
    super.dispose();
  }
}
