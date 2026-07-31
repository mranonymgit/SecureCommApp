import 'package:latlong2/latlong.dart';

enum EstadoIncidencia { pendiente, enProceso, resuelto, critico, cancelado }

extension EstadoIncidenciaX on EstadoIncidencia {
  String get apiValue {
    switch (this) {
      case EstadoIncidencia.pendiente:
        return 'pending';
      case EstadoIncidencia.resuelto:
        return 'resolved';
      case EstadoIncidencia.enProceso:
        return 'in_progress';
      case EstadoIncidencia.critico:
        return 'critical';
      case EstadoIncidencia.cancelado:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case EstadoIncidencia.pendiente:
        return 'Pendiente';
      case EstadoIncidencia.resuelto:
        return 'Resuelto';
      case EstadoIncidencia.enProceso:
        return 'En Proceso';
      case EstadoIncidencia.critico:
        return 'Crítico';
      case EstadoIncidencia.cancelado:
        return 'Cancelado';
    }
  }
}

class Incidencia {
  final String id;
  final String titulo;
  final String descripcion;
  final String fecha;
  final EstadoIncidencia estado;
  final LatLng ubicacion;
  final String reporter;
  final String? evidenciaUrl;
  final double? latitude;
  final double? longitude;

  const Incidencia({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.fecha,
    required this.estado,
    required this.ubicacion,
    required this.reporter,
    this.evidenciaUrl,
    this.latitude,
    this.longitude,
  });
}
