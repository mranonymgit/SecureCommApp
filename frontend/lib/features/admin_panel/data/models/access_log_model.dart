import '../../domain/entities/access_log_entity.dart';

class AccessLogModel extends AccessLogEntity {
  const AccessLogModel({
    required super.id,
    required super.visitor,
    required super.resident,
    required super.time,
    required super.type,
    required super.status,
    required super.plate,
    required super.qrCode,
    required super.entryGuard,
  });

  factory AccessLogModel.fromJson(Map<String, dynamic> json) {
    return AccessLogModel(
      id: (json['id'] ?? '').toString(),
      visitor: (json['visitor'] ?? json['visitor_name'] ?? '').toString(),
      resident:
          (json['resident'] ??
                  json['resident_name'] ??
                  json['resident_user_id'] ??
                  '')
              .toString(),
      time: (json['time'] ?? json['created_at'] ?? '').toString(),
      type: (json['type'] ?? json['action'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      plate: (json['plate'] ?? json['plate_number'] ?? '').toString(),
      qrCode: (json['qrCode'] ?? json['qr_code'] ?? '').toString(),
      entryGuard: (json['entryGuard'] ?? json['entry_guard'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'visitor': visitor,
      'resident': resident,
      'time': time,
      'type': type,
      'status': status,
      'plate': plate,
      'qrCode': qrCode,
      'entryGuard': entryGuard,
    };
  }
}
