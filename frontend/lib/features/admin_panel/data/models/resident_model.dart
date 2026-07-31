import '../../domain/entities/resident_entity.dart';

class ResidentModel extends ResidentEntity {
  const ResidentModel({
    required super.id,
    required super.tempPassword,
    required super.name,
    required super.unit,
    required super.bloodType,
    required super.illnesses,
    required super.allergies,
    required super.emergencyContact,
    required super.email,
    required super.phone,
    required super.avatarUrl,
    super.status,
  });

  factory ResidentModel.fromJson(Map<String, dynamic> json) {
    return ResidentModel(
      id: (json['id'] ?? '').toString(),
      tempPassword: (json['tempPassword'] ?? json['temp_password'] ?? '')
          .toString(),
      name: (json['name'] ?? json['full_name'] ?? '').toString(),
      unit: (json['unit'] ?? json['unit_name'] ?? json['unitLabel'] ?? '')
          .toString(),
      bloodType: (json['bloodType'] ?? json['blood_type'] ?? '').toString(),
      illnesses: (json['illnesses'] ?? json['conditions'] ?? 'Ninguna')
          .toString(),
      allergies: (json['allergies'] ?? '').toString(),
      emergencyContact:
          (json['emergencyContact'] ?? json['emergency_contact'] ?? '')
              .toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      avatarUrl: (json['avatarUrl'] ?? json['avatar_url'] ?? '').toString(),
      status: (json['status'] ?? 'active').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tempPassword': tempPassword,
      'name': name,
      'unit': unit,
      'bloodType': bloodType,
      'illnesses': illnesses,
      'allergies': allergies,
      'emergencyContact': emergencyContact,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'status': status,
    };
  }
}
