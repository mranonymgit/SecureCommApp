class EmergencyProfile {
  final String nombre;
  final int edad;
  final String tipoSangre;
  final String padecimientos;
  final String alergias;
  final String contactoEmergencia;
  final String direccion;
  final bool sosActive;

  const EmergencyProfile({
    required this.nombre,
    required this.edad,
    required this.tipoSangre,
    required this.padecimientos,
    required this.alergias,
    required this.contactoEmergencia,
    required this.direccion,
    this.sosActive = false,
  });
}
