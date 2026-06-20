import 'package:flutter/material.dart';

class MapaLocal extends StatelessWidget{
  const MapaLocal ({super.key});


  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          // La sombra crea el efecto visual de "mueble" o botón flotante
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,       // Qué tan difuminada está la sombra
              offset: const Offset(0, 4), // Desplazamiento hacia abajo (Eje Y)
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Ver Reglamento Vecinal', style: TextStyle(fontWeight: FontWeight.bold)),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black45),
          ],
        ),
      ),
    );
  }
}