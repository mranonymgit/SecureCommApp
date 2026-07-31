import 'dart:async';
import 'package:flutter/material.dart';
import '../../../data/repositories/residents_repository_impl.dart';
import '../../../domain/entities/resident_entity.dart';
import '../../../domain/usecases/add_resident_usecase.dart';
import '../../../domain/usecases/get_residents_usecase.dart';
import '../../controllers/residents_controller.dart';
import '../../widgets/admin_state_feedback.dart';

class ResidentsView extends StatefulWidget {
  final ResidentsController? controller;

  const ResidentsView({super.key, this.controller});

  @override
  State<ResidentsView> createState() => _ResidentsViewState();
}

class _ResidentsViewState extends State<ResidentsView> {
  late final ResidentsController _controller;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    final repo = ResidentsRepositoryImpl();
    _controller =
        widget.controller ??
        ResidentsController(
          getResidentsUseCase: GetResidentsUseCase(repo),
          addResidentUseCase: AddResidentUseCase(repo),
          repository: repo,
        );

    _controller.loadResidents();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _controller.loadResidents(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _showResidentDetail(ResidentEntity r) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.blueAccent,
              backgroundImage: r.avatarUrl.isNotEmpty
                  ? NetworkImage(r.avatarUrl)
                  : null,
              child: r.avatarUrl.isEmpty
                  ? Text(
                      r.name.isNotEmpty ? r.name[0] : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    r.unit,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(color: Colors.white24),
              _buildSectionTitle('Datos de Acceso al Sistema'),
              _buildDetailRow('ID Único de Usuario:', r.id),
              _buildDetailRow(
                'Contraseña Temporal:',
                r.tempPassword.isNotEmpty
                    ? r.tempPassword
                    : 'No disponible por seguridad',
              ),
              const SizedBox(height: 12),
              _buildSectionTitle('Información Médica y Salud'),
              _buildDetailRow('Tipo de Sangre:', r.bloodType),
              _buildDetailRow('Enfermedades / Padecimientos:', r.illnesses),
              _buildDetailRow('Alergias a Medicamentos:', r.allergies),
              const SizedBox(height: 12),
              _buildSectionTitle('Contacto y Emergencia'),
              _buildDetailRow('Contacto de Emergencia:', r.emergencyContact),
              _buildDetailRow('Correo Electrónico:', r.email),
              _buildDetailRow('Teléfono Principal:', r.phone),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A2A2A),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddResidentDialog() {
    final nameCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    final bloodCtrl = TextEditingController();
    final illnessesCtrl = TextEditingController();
    final allergiesCtrl = TextEditingController();
    final emergencyCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Alta de Nuevo Residente',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Credenciales de acceso'),
              const SizedBox(height: 8),
              const Text(
                'El identificador lo genera la base de datos. Define una contraseña temporal segura para el residente.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Datos Generales'),
              _buildTextField(nameCtrl, 'Nombre Completo'),
              _buildTextField(unitCtrl, 'Casa / Torre / Departamento'),
              _buildTextField(emailCtrl, 'Correo Electrónico'),
              _buildTextField(phoneCtrl, 'Teléfono'),
              _buildTextField(
                passwordCtrl,
                'Contraseña temporal (mínimo 12 caracteres)',
                obscureText: true,
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Ficha Médica y Emergencia'),
              _buildTextField(bloodCtrl, 'Tipo de Sangre (ej. O+, A-)'),
              _buildTextField(illnessesCtrl, 'Enfermedades / Padecimientos'),
              _buildTextField(allergiesCtrl, 'Alergias a Medicamentos'),
              _buildTextField(
                emergencyCtrl,
                'Contacto de Emergencia (Nombre y Tel)',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && passwordCtrl.text.length >= 12) {
                final created = await _controller.createResident(
                  name: nameCtrl.text.trim(),
                  unit: unitCtrl.text.trim(),
                  initialPassword: passwordCtrl.text,
                  bloodType: bloodCtrl.text.trim(),
                  illnesses: illnessesCtrl.text.trim(),
                  allergies: allergiesCtrl.text.trim(),
                  emergencyContact: emergencyCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                );
                if (!mounted) return;
                if (created) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Residente creado y habilitado para iniciar sesión.',
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _controller.errorMessage ??
                            'No fue posible crear el residente.',
                      ),
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Nombre y contraseña de al menos 12 caracteres son obligatorios.',
                    ),
                  ),
                );
              }
            },
            child: const Text(
              'Guardar Residente',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.blueAccent,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
          isDense: true,
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.blueAccent),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📱 Encabezado Responsivo
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;

              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gestión de Residentes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                        ),
                        onPressed: _showAddResidentDialog,
                        icon: const Icon(Icons.person_add, color: Colors.white),
                        label: const Text(
                          'Nuevo Residente',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Gestión de Residentes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                    ),
                    onPressed: _showAddResidentDialog,
                    icon: const Icon(Icons.person_add, color: Colors.white),
                    label: const Text(
                      'Nuevo Residente',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // 👥 Lista de Residentes
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              if (_controller.isLoading) {
                return const AdminLoadingState(color: Colors.blueAccent);
              }

              if (_controller.hasError) {
                return AdminErrorState(
                  message:
                      _controller.errorMessage ??
                      'No se pudieron cargar los residentes.',
                  onRetry: _controller.loadResidents,
                );
              }

              if (_controller.residents.isEmpty) {
                return AdminEmptyState(
                  icon: Icons.people_outline,
                  title: 'Sin residentes',
                  message:
                      'Todavía no hay residentes cargados desde la base de datos.',
                  actionLabel: 'Reintentar',
                  onAction: _controller.loadResidents,
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _controller.residents.length,
                itemBuilder: (context, index) {
                  final r = _controller.residents[index];

                  return Card(
                    color: const Color(0xFF1E1E1E),
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      onTap: () => _showResidentDetail(r),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.blueAccent,
                        backgroundImage: r.avatarUrl.isNotEmpty
                            ? NetworkImage(r.avatarUrl)
                            : null,
                        child: Text(
                          r.name.isNotEmpty ? r.name[0] : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              r.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              r.bloodType,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        '${r.unit} • ID: ${r.id}\nContacto: ${r.phone}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.white38,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
