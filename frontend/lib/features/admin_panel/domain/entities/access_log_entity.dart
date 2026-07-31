class AccessLogEntity {
  final String id;
  final String visitor;
  final String resident;
  final String time;
  final String type;
  final String status;
  final String plate;
  final String qrCode;
  final String entryGuard;

  const AccessLogEntity({
    required this.id,
    required this.visitor,
    required this.resident,
    required this.time,
    required this.type,
    required this.status,
    required this.plate,
    required this.qrCode,
    required this.entryGuard,
  });
}