import 'package:flutter/material.dart';

class TarjetaNoticia extends StatelessWidget {
  const TarjetaNoticia({super.key, required this.titulo, required this.fecha});

  final String titulo;
  final String fecha;

  @override
  Widget build(BuildContext context){
    return Card(
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
                Text(titulo,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),),
                Text(fecha,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                )),
              ],
            )
            ),
          ],
        ),
      );
  }
}