import '../../domain/entities/emergency_profile.dart';

class EmergencyProfileModel extends EmergencyProfile {
  const EmergencyProfileModel({
    required super.nombre,
    required super.edad,
    required super.tipoSangre,
    required super.padecimientos,
    required super.alergias,
    required super.contactoEmergencia,
    required super.direccion,
    super.sosActive,
  });

  factory EmergencyProfileModel.fromJson(Map<String, dynamic> json) {
    return EmergencyProfileModel(
      nombre: (json['nombre'] ?? json['full_name'] ?? '').toString(),
      edad: json['edad'] ?? json['age'] ?? 0,
      tipoSangre: (json['tipoSangre'] ?? json['tipo_sangre'] ?? '').toString(),
      padecimientos: (json['padecimientos'] ?? json['conditions'] ?? '')
          .toString(),
      alergias: (json['alergias'] ?? '').toString(),
      contactoEmergencia:
          (json['contactoEmergencia'] ?? json['contacto_emergencia'] ?? '')
              .toString(),
      direccion: (json['direccion'] ?? json['address'] ?? '').toString(),
      sosActive: json['sos_active'] == true,
    );
  }
}
