import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/services/community_realtime_service.dart';
import '../../../../core/network/api_error_message.dart';
import '../../domain/entities/resident_entity.dart';
import '../../domain/repositories/residents_repository.dart';
import '../../domain/usecases/add_resident_usecase.dart';
import '../../domain/usecases/get_residents_usecase.dart';

class ResidentsController extends ChangeNotifier {
  final GetResidentsUseCase getResidentsUseCase;
  final AddResidentUseCase addResidentUseCase;
  final ResidentsRepository repository;

  ResidentsController({
    required this.getResidentsUseCase,
    required this.addResidentUseCase,
    required this.repository,
  });

  List<ResidentEntity> _residents = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _actionErrorMessage;
  StreamSubscription<CommunityChange>? _realtimeSubscription;

  List<ResidentEntity> get residents => _residents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  String? get actionErrorMessage => _actionErrorMessage;

  Future<void> loadResidents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _residents = await getResidentsUseCase();
    } catch (e) {
      _residents = [];
      _errorMessage = 'No fue posible cargar los residentes.';
      debugPrint('Error al cargar residentes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void connectRealtime() {
    _realtimeSubscription ??= CommunityRealtimeService.instance
        .watchTables(const {'users', 'resident_profiles'})
        .listen((_) => unawaited(refreshResidentsSilently()));
  }

  Future<void> refreshResidentsSilently() async {
    try {
      _residents = await getResidentsUseCase();
      _errorMessage = null;
      notifyListeners();
    } catch (_) {
      // Preserve the current list while Render reconnects.
    }
  }

  Future<bool> createResident({
    required String name,
    required String unit,
    required String initialPassword,
    required String bloodType,
    required String illnesses,
    required String allergies,
    required String emergencyContact,
    required String email,
    required String phone,
  }) async {
    final newResident = ResidentEntity(
      id: '',
      tempPassword: initialPassword,
      name: name,
      unit: unit,
      bloodType: bloodType,
      illnesses: illnesses,
      allergies: allergies,
      emergencyContact: emergencyContact,
      email: email,
      phone: phone,
      avatarUrl: '',
      status: 'active',
    );

    try {
      final added = await addResidentUseCase(newResident);
      _residents = [
        added,
        ..._residents.where((resident) => resident.id != added.id),
      ];
      _actionErrorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      try {
        final canonical = await getResidentsUseCase();
        final saved = canonical.any(
          (item) => item.email.toLowerCase() == email.toLowerCase(),
        );
        if (saved) {
          _residents = canonical;
          _actionErrorMessage = null;
          notifyListeners();
          return true;
        }
      } catch (_) {}
      _actionErrorMessage = ApiErrorMessage.from(
        error,
        fallback: 'No fue posible crear el residente.',
      );
      debugPrint('Error al agregar residente: $error');
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }
}
