import '../../domain/entities/report_entity.dart';

class ReportModel extends ReportEntity {
  const ReportModel({
    required super.id,
    required super.title,
    required super.location,
    required super.coords,
    super.latitude,
    super.longitude,
    required super.status,
    required super.reporter,
    required super.date,
    required super.desc,
    super.evidenceUrl,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    final latitude = _parseDouble(json['latitude']) ?? _parseCoords(json['coords'])?.$1;
    final longitude = _parseDouble(json['longitude']) ?? _parseCoords(json['coords'])?.$2;

    return ReportModel(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      location: (json['location'] ?? json['location_text'] ?? 'Ubicación registrada').toString(),
      coords: (json['coords'] ?? json['coordinates'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      reporter: (json['reporter'] ?? json['reporter_name'] ?? '').toString(),
      date: (json['date'] ?? json['created_at'] ?? '').toString(),
      desc: (json['desc'] ?? json['description'] ?? '').toString(),
      latitude: latitude,
      longitude: longitude,
      evidenceUrl: (json['evidence_url'] ?? json['image_url'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'coords': coords,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'reporter': reporter,
      'date': date,
      'desc': desc,
      'evidence_url': evidenceUrl,
    };
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
}
