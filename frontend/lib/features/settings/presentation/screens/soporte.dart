import 'package:flutter/material.dart';
import 'package:frontend/features/settings/presentation/screens/preguntasFrecuentes.dart';

class Soporte extends StatelessWidget{
  const Soporte ({super.key});

  @override
  Widget build(BuildContext context){
    return Column(
      children: [
        Expanded(
          child: Card(
            clipBehavior: Clip.antiAlias, // Asegura que el efecto del botón no se salga de las esquinas redondeadas
            elevation: 3,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InkWell(
              onTap: () {
                // Al presionar la tarjeta, navegamos a la otra pantalla
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PreguntasFrecuentes()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // 1. Icono o imagen a la izquierda
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 232, 244, 251),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.gavel, color: Color.fromARGB(255, 18, 109, 151)),
                    ),
                    const SizedBox(width: 16),
                    
                    // 2. Textos ordenados verticalmente (Título y subtítulo)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Reglamento de Convivencia',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Lee las normas aprobadas por el comité del vecindario.',
                            style: TextStyle(fontSize: 13, color: Colors.black54),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis, // Si el texto es muy largo, pone "..."
                          ),
                        ],
                      ),
                    ),
                    
                    // 3. Una pequeña flecha indicativa a la derecha (Toque de UX)
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black38),
                  ],
                ),
              ),
            ),
          )
        ),
      ],
    );
  }
}