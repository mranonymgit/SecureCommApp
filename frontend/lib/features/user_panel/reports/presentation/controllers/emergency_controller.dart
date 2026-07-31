import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/emergency_profile.dart';
import '../../domain/usecases/get_emergency_profile_usecase.dart';
import '../../domain/usecases/trigger_sos_alert_usecase.dart';

class EmergencyController extends ChangeNotifier {
  final GetEmergencyProfileUseCase getProfileUseCase;
  final TriggerSosAlertUseCase triggerSosAlertUseCase;

  EmergencyController({
    required this.getProfileUseCase,
    required this.triggerSosAlertUseCase,
  });

  bool emergencyActive = false;
  bool isLoading = true;
  EmergencyProfile? profile;
  String? errorMessage;

  Future<void> loadProfile() async {
    isLoading = true;
    notifyListeners();
    try {
      profile = await getProfileUseCase();
    } catch (e) {
      errorMessage = 'Error al cargar perfil de emergencia: ${e.toString()}';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleEmergency() async {
    final previousState = emergencyActive;
    emergencyActive = !previousState;
    errorMessage = null;
    notifyListeners();
    try {
      await triggerSosAlertUseCase(active: emergencyActive);
    } catch (e) {
      emergencyActive = previousState;
      errorMessage = 'No se pudo registrar la alerta SOS.';
      notifyListeners();
    }
  }

  Future<bool> makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
      return true;
    }
    return false;
  }
}
