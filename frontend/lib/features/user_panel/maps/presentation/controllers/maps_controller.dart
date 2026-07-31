import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/entities/incidencia.dart';
import '../../domain/usecases/get_incidencias_usecase.dart';
import '../../domain/repositories/maps_repository.dart';

class MapsController extends ChangeNotifier {
  final GetIncidenciasUseCase getIncidenciasUseCase;
  final MapsRepository? mapsRepository;

  MapsController({
    required this.getIncidenciasUseCase,
    this.mapsRepository,
  });

  final MapController mapController = MapController();
  static const LatLng posicionInicial = LatLng(19.432608, -99.133209);

  List<Incidencia> incidencias = [];
  Incidencia? incidenciaSeleccionada;
  bool isLoading = false;
  String? errorMessage;
  bool isUpdatingStatus = false;

  Future<void> loadIncidencias() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      incidencias = await getIncidenciasUseCase();
    } catch (e) {
      errorMessage = 'Error al cargar incidencias: $e';
      incidencias = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void seleccionarIncidencia(Incidencia? incidencia) {
    incidenciaSeleccionada = incidencia;
    if (incidencia != null) {
      mapController.move(incidencia.ubicacion, 16.0);
    }
    notifyListeners();
  }

  void deseleccionarIncidencia() {
    incidenciaSeleccionada = null;
    notifyListeners();
  }

  Future<void> cambiarEstado(Incidencia incidencia, EstadoIncidencia nuevoEstado) async {
    if (mapsRepository == null) {
      errorMessage = 'No hay repositorio configurado para actualizar incidencias.';
      notifyListeners();
      return;
    }

    isUpdatingStatus = true;
    errorMessage = null;
    notifyListeners();

    try {
      final updated = await mapsRepository!.updateIncidenciaStatus(incidencia.id, nuevoEstado);
      final index = incidencias.indexWhere((item) => item.id == incidencia.id);
      if (index != -1) {
        incidencias[index] = updated;
      }
      if (incidenciaSeleccionada?.id == incidencia.id) {
        incidenciaSeleccionada = updated;
      }
    } catch (e) {
      errorMessage = 'No fue posible actualizar el estado: $e';
    } finally {
      isUpdatingStatus = false;
      notifyListeners();
    }
  }
}
