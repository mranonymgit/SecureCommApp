import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/user_preferences.dart';

class ProfileController extends ChangeNotifier {
  ProfileController({SettingsRepositoryImpl? repository})
    : _repository = repository ?? SettingsRepositoryImpl();

  final SettingsRepositoryImpl _repository;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  bool isLoading = false;
  bool isSaving = false;
  bool isPickingImage = false;
  String? errorMessage;
  XFile? selectedImage;
  Uint8List? selectedImageBytes;
  String? avatarDataUrl;
  double? latitude;
  double? longitude;
  UserPreferences? preferences;

  Future<void> loadProfile() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final profile = await _repository.getProfile();
      preferences = await _repository.getPreferences();
      nameController.text = profile.fullName;
      emailController.text = profile.email;
      phoneController.text = profile.phone;
      addressController.text = profile.address ?? preferences?.address ?? '';
      avatarDataUrl = profile.avatarUrl;
      latitude = profile.latitude ?? preferences?.latitude;
      longitude = profile.longitude ?? preferences?.longitude;
    } catch (e) {
      errorMessage = 'No fue posible cargar el perfil.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      isPickingImage = true;
      notifyListeners();
      final picker = ImagePicker();
      final image = await picker.pickImage(source: source, imageQuality: 85);
      if (image == null) return;
      selectedImage = image;
      selectedImageBytes = await image.readAsBytes();
      avatarDataUrl =
          'data:image/${image.name.toLowerCase().endsWith('.png') ? 'png' : 'jpeg'};base64,${base64Encode(selectedImageBytes!)}';
    } catch (e) {
      errorMessage = 'No se pudo seleccionar la foto.';
    } finally {
      isPickingImage = false;
      notifyListeners();
    }
  }

  Future<void> useCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Ubicación desactivada.');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Permiso de ubicación denegado.');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      latitude = position.latitude;
      longitude = position.longitude;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> saveProfile() async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      final avatarUrl = selectedImageBytes == null
          ? avatarDataUrl
          : await _repository.uploadAvatar(
              selectedImageBytes!,
              selectedImage?.name ?? 'avatar.jpg',
            );
      final updated = await _repository.updateProfile(
        UserProfile(
          id: '',
          fullName: nameController.text.trim(),
          email: emailController.text.trim(),
          phone: phoneController.text.trim(),
          avatarUrl: avatarUrl,
          address: addressController.text.trim(),
          latitude: latitude,
          longitude: longitude,
        ),
      );
      final prefs = await _repository.updatePreferences(
        (preferences ??
                const UserPreferences(
                  themeMode: 'default',
                  notificationsEnabled: true,
                  language: 'es',
                ))
            .copyWith(
              address: addressController.text.trim(),
              latitude: latitude,
              longitude: longitude,
            ),
      );
      avatarDataUrl = updated.avatarUrl;
      latitude = updated.latitude ?? prefs.latitude;
      longitude = updated.longitude ?? prefs.longitude;
      preferences = prefs;
      return true;
    } catch (e) {
      errorMessage = 'No se pudo guardar el perfil.';
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }
}
