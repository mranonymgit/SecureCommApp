import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/network/api_error_message.dart';
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
  String? loadErrorMessage;
  String? actionErrorMessage;

  Future<void> loadProfile() async {
    isLoading = true;
    loadErrorMessage = null;
    notifyListeners();
    try {
      profile = await getProfileUseCase();
      emergencyActive = profile?.sosActive ?? false;
    } catch (e) {
      loadErrorMessage = 'No fue posible cargar el perfil de emergencia.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> activateEmergency() => _setEmergency(true);

  Future<void> deactivateEmergency() => _setEmergency(false);

  Future<void> _setEmergency(bool active) async {
    final previousState = emergencyActive;
    emergencyActive = active;
    actionErrorMessage = null;
    notifyListeners();
    try {
      await triggerSosAlertUseCase(active: active);
    } catch (e) {
      emergencyActive = previousState;
      actionErrorMessage = ApiErrorMessage.from(
        e,
        fallback: 'No se pudo registrar la alerta SOS.',
      );
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
