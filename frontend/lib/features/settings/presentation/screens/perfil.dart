import 'package:flutter/material.dart';

class Perfil extends StatefulWidget {
  const Perfil({super.key});

  @override
  State<Perfil> createState() => _PerfilState();
}

class _PerfilState extends State<Perfil> {

  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _passwordV = TextEditingController();

  @override
  void dispose (){
    _email.dispose();
    _password.dispose();
    _passwordV.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Mi Perfil'),
        backgroundColor: const Color.fromARGB(255, 18, 109, 151),
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildProfilePhoto(),
                    const SizedBox(height: 20.0),
                    _buildInfoText('Usuario 0001', 26.0),
                    _buildInfoText('@usuario_0001', 17.0),
                    _buildInfoText('Colonia San Luis', 17.0),
                    const SizedBox(height: 20.0),
                    _buildTextField(
                      label: 'Correo Electrónico',
                      hint: 'Escriba el nuevo correo...',
                      icon: Icons.email,
                      controller: _email
                    ),
                    _buildTextField(
                      label: 'Número telefónico',
                      hint: 'Escriba el nuevo número...',
                      icon: Icons.phone,
                      controller: _password
                    ),
                    _buildTextField(
                      label: 'Dirección',
                      hint: 'Escriba su nueva dirección...',
                      icon: Icons.location_on,
                      controller: _passwordV
                    ),
                    const SizedBox(height: 20.0),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 18, 109, 151),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          if (_email.text.isEmpty || _password.text.isEmpty || _passwordV.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Por favor. Llene todos los campos.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Se administrarán los cambios.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            _email.clear();
                            _password.clear();
                            _passwordV.clear();
                          }
                        },
                        icon: const Icon(Icons.check, size: 20.0),
                        label: const Text('Verificar cambios', style: TextStyle(fontSize: 18.0)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfilePhoto() {
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        const CircleAvatar(
          radius: 65,
          backgroundColor: Color.fromARGB(255, 18, 109, 151),
          child: Icon(Icons.person, size: 80, color: Colors.white),
        ),
        Positioned(
          bottom: -10,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color.fromARGB(255, 87, 209, 240), width: 1.5),
              borderRadius: BorderRadius.circular(22),
            ),
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 0, 131, 212),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {},
              child: const Text('Edit Photo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoText(String text, double size) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Text(
        text,
        style: TextStyle(fontSize: size, fontWeight: FontWeight.bold, color: Colors.black),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.indigo),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black),
          prefixIcon: Icon(icon),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: const BorderSide(
              color: Color.fromARGB(146, 2, 94, 112),
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13.0),
            borderSide: const BorderSide(
              color: Color.fromARGB(255, 0, 19, 52),
              width: 2.5,
            ),
          ),
        ),
      ),
    );
  }
}