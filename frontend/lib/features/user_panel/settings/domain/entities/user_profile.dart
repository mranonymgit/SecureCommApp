class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String? avatarUrl;
  final String? address;
  final double? latitude;
  final double? longitude;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    this.avatarUrl,
    this.address,
    this.latitude,
    this.longitude,
  });

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
    String? address,
    double? latitude,
    double? longitude,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
