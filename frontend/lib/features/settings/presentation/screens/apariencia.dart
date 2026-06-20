import 'package:flutter/material.dart';

class Apariencia extends StatefulWidget {
  const Apariencia({super.key});

  @override
  State<Apariencia> createState() => _AparienciaDesplegable();
}

class _AparienciaDesplegable extends State<Apariencia> {
  // 1. Variable para guardar la opción seleccionada (Inicia con un texto por defecto)
  String _opcionSeleccionada = 'Seleccionar Manzana / Bloque';

  // 2. Lista de opciones del menú
  final List<String> _opciones = [
    'Manzana A (Av. Principal)',
    'Manzana B (Calle Central)',
    'Manzana C (Zona Norte)',
    'Manzana D (Zona Sur)',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubicación del Reporte'),
        backgroundColor: const Color.fromARGB(255, 18, 109, 151),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿En qué sector del vecindario ocurrió?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // 3. El Menú Desplegable Flotante
            PopupMenuButton<String>(
              // Ajusta la posición para que el menú caiga justo debajo del botón
              offset: const Offset(0, 50), 
              // Construimos las opciones visuales del menú
              itemBuilder: (BuildContext context) {
                return _opciones.map((String opcion) {
                  return PopupMenuItem<String>(
                    value: opcion,
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.black45, size: 20),
                        const SizedBox(width: 10),
                        Text(opcion),
                      ],
                    ),
                  );
                }).toList();
              },
              // Acción cuando el usuario selecciona una opción de la lista
              onSelected: (String nuevoValor) {
                setState(() {
                  _opcionSeleccionada = nuevoValor; // Actualizamos el texto del botón
                });
              },
              child: ElevatedButton.icon(
                onPressed: null, 
                icon: const Icon(Icons.map, color: Colors.white),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _opcionSeleccionada,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_drop_down, color: Colors.white),
                  ],
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 18, 109, 151),
                  disabledBackgroundColor: const Color.fromARGB(255, 18, 109, 151),
                  disabledForegroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            PopupMenuButton<String>(
              // Desplaza el menú hacia abajo para que no tape el icono
              offset: const Offset(0, 40), 
              icon: const Icon(
                Icons.filter_list, // Icono de embudo/filtro
                color: Color.fromARGB(255, 18, 109, 151), // Tu color azul
                size: 28,
              ),
              // Construimos las opciones de la lista
              itemBuilder: (BuildContext context) {
                return [
                  const PopupMenuItem<String>(
                    value: 'todos',
                    child: Text('Mostrar todos'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'admin',
                    child: Text('Solo Administradores'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'recientes',
                    child: Text('Más recientes'),
                  ),
                ];
              },
              // Qué pasa cuando el usuario elige una opción
              onSelected: (String valorSeleccionado) {
                print('Filtro seleccionado: $valorSeleccionado');
                // Aquí puedes meter la lógica para filtrar tus reportes o mensajes
              },
            )
          ],
        ),
      ),
    );
  }
}