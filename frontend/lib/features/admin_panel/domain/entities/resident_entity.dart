class ResidentEntity {
  final String id;
  final String tempPassword;
  final String name;
  final String unit;
  final String bloodType;
  final String illnesses;
  final String allergies;
  final String emergencyContact;
  final String email;
  final String phone;
  final String avatarUrl;
  final String status;

  const ResidentEntity({
    required this.id,
    required this.tempPassword,
    required this.name,
    required this.unit,
    required this.bloodType,
    required this.illnesses,
    required this.allergies,
    required this.emergencyContact,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    this.status = 'active',
  });
}
