class ReportEntity {
  final String id;
  final String title;
  final String location;
  final String coords;
  final double? latitude;
  final double? longitude;
  final String status;
  final String reporter;
  final String date;
  final String desc;
  final String? evidenceUrl;

  const ReportEntity({
    required this.id,
    required this.title,
    required this.location,
    required this.coords,
    this.latitude,
    this.longitude,
    required this.status,
    required this.reporter,
    required this.date,
    required this.desc,
    this.evidenceUrl,
  });

  ReportEntity copyWith({
    String? id,
    String? title,
    String? location,
    String? coords,
    double? latitude,
    double? longitude,
    String? status,
    String? reporter,
    String? date,
    String? desc,
    String? evidenceUrl,
  }) {
    return ReportEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      coords: coords ?? this.coords,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      reporter: reporter ?? this.reporter,
      date: date ?? this.date,
      desc: desc ?? this.desc,
      evidenceUrl: evidenceUrl ?? this.evidenceUrl,
    );
  }
}
