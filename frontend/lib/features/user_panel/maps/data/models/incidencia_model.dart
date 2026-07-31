import 'package:latlong2/latlong.dart';

import '../../domain/entities/incidencia.dart';

class IncidenciaModel extends Incidencia {
  const IncidenciaModel({
    required super.id,
    required super.titulo,
    required super.descripcion,
    required super.fecha,
    required super.estado,
    required super.ubicacion,
    required super.reporter,
    super.evidenciaUrl,
    super.latitude,
    super.longitude,
  });

  factory IncidenciaModel.fromJson(Map<String, dynamic> json) {
    final latitude =
        _parseDouble(json['latitude']) ?? _parseCoords(json['coords'])?.$1;
    final longitude =
        _parseDouble(json['longitude']) ?? _parseCoords(json['coords'])?.$2;
    if (latitude == null || longitude == null) {
      throw FormatException('Report is missing valid coordinates.');
    }

    return IncidenciaModel(
      id: (json['id'] ?? '').toString(),
      titulo: (json['title'] ?? json['titulo'] ?? '').toString(),
      descripcion: (json['description'] ?? json['descripcion'] ?? '')
          .toString(),
      fecha: _parseFecha(json['created_at'] ?? json['fecha']),
      estado: _parseEstado(json['status'] ?? json['estado']),
      ubicacion: LatLng(latitude, longitude),
      reporter: (json['reporter'] ?? json['reporter_name'] ?? '').toString(),
      evidenciaUrl: (json['evidence_url'] ?? json['imagenUrl'])?.toString(),
      latitude: latitude,
      longitude: longitude,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'fecha': fecha,
      'estado': estado.apiValue,
      'latitude': ubicacion.latitude,
      'longitude': ubicacion.longitude,
      'reporter': reporter,
      'evidence_url': evidenciaUrl,
    };
  }

  static EstadoIncidencia _parseEstado(dynamic estadoStr) {
    final normalized = (estadoStr ?? '').toString().toLowerCase();
    switch (normalized) {
      case 'pending':
      case 'pendiente':
        return EstadoIncidencia.pendiente;
      case 'resolved':
      case 'resuelto':
        return EstadoIncidencia.resuelto;
      case 'in_progress':
      case 'enproceso':
      case 'en_proceso':
        return EstadoIncidencia.enProceso;
      case 'critical':
      case 'critico':
        return EstadoIncidencia.critico;
      case 'cancelled':
      case 'cancelado':
        return EstadoIncidencia.cancelado;
      default:
        return EstadoIncidencia.pendiente;
    }
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static (double, double)? _parseCoords(dynamic coords) {
    if (coords == null) return null;
    final raw = coords.toString();
    final parts = raw.split(',');
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0].trim());
    final lng = double.tryParse(parts[1].trim());
    if (lat == null || lng == null) return null;
    return (lat, lng);
  }

  static String _parseFecha(dynamic value) {
    if (value == null) return 'Sin fecha';
    final text = value.toString();
    return text.isEmpty ? 'Sin fecha' : text;
  }
}
