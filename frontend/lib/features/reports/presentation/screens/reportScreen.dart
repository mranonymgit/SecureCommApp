import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:frontend/core/utils/media_picker.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen ({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> with MediaPickerMixin {
  PlatformFile? _selectedFile;

  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();

  @override
  void dispose(){
    _tituloController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }
  Future<void> _handleAttach() async {
    final file = await pickMedia();
    if (file != null) {
      if ((file.size / 1024 / 1024) > 5) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El archivo es muy pesado (máx 5MB).'), backgroundColor: Colors.red),
        );
      } else {
        setState(() => _selectedFile = file);
      }
    }
  }

  @override
  Widget build(BuildContext context){
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Crear Reporte Vecinal',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),),
            SizedBox(height: 20),
            TextField(
              controller: _tituloController,
              decoration: InputDecoration(
                labelText: 'Titulo',
                hintText: 'Escriba un titulo para el problema...',
                prefixIcon: Icon(Icons.label),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descripcionController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                labelText: 'Descripción del problema',
                hintText: 'Describa el problema a detalle...',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _handleAttach,
              icon: const Icon(Icons.attach_file),
              label: Text(_selectedFile == null ? 'Adjuntar archivo' : 'Cambiar archivo'),
            ),
            if (_selectedFile != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  leading: const Icon(Icons.file_present),
                  title: Text(_selectedFile!.name),
                  subtitle: Text('${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB'),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => setState(() => _selectedFile = null),
                  ),
                ),
              ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                final tituloText = _tituloController.text;
                final descripcionText = _descripcionController.text;

                ScaffoldMessenger.of(context).hideCurrentSnackBar();

                if(tituloText.isEmpty || descripcionText.isEmpty){
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor, rellena todos los campos.'),
                      backgroundColor: Colors.red,
                    )
                  );
                  return;
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reporte enviado con éxito.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
                _tituloController.clear();
                _descripcionController.clear();
              },
              icon: const Icon(Icons.send),
              label: const Text('Enviar Reporte'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 18, 109, 151), // El mismo azul de tu AppBar
                foregroundColor: Colors.white, // Texto e icono en blanco
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
          ),
        ),
    );
  }
}