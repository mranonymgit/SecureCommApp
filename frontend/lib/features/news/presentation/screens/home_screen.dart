import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 245, 245, 245),
      appBar: AppBar(
        title: const Text(
          'Mi Vecindario',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(221, 255, 255, 255)),
        ),
        backgroundColor: const Color.fromARGB(255, 18, 109, 151),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Color.fromARGB(221, 255, 255, 255)),
            onPressed: () {
              // Aquí irá la lógica de notificaciones más adelante
            },
          ),
        ],
      ),
      body: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(12.0),
            child: Image.network('https://imgs.search.brave.com/0kuK6QPm_G_0daPV7ilnHeaXe8c5JoSFd35BDqQCQpk/rs:fit:500:0:1:0/g:ce/aHR0cHM6Ly91cy4x/MjNyZi5jb20vNDUw/d20vamFua2EzMTQ3/L2phbmthMzE0NzE5/MDgvamFua2EzMTQ3/MTkwODAwMjAwLzEy/OTYyOTk4Mi12YXNv/LWVuLW1hbm8teS12/ZXJ0aWVuZG8tYWd1/YS5qcGc_dmVyPTY'),
            ),
            Padding(padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Corte de agua programado para el miércoles. ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),),
                Text('Hace 2 horas',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                )),
              ],
            )
            ),
          ],
        ),
      ),
    );
  }
}