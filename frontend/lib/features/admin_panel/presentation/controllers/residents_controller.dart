import 'package:flutter/material.dart';
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

  List<ResidentEntity> get residents => _residents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

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
      illnesses: illnesses.isEmpty ? 'Ninguna' : illnesses,
      allergies: allergies.isEmpty ? 'Ninguna' : allergies,
      emergencyContact: emergencyContact,
      email: email,
      phone: phone,
      avatarUrl: '',
    );

    try {
      final added = await addResidentUseCase(newResident);
      _residents.insert(0, added);
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'No fue posible crear el residente.';
      debugPrint('Error al agregar residente: $e');
      notifyListeners();
      return false;
    }
  }
}
