import 'package:flutter/material.dart';

class Chatscreen extends StatelessWidget {
  const Chatscreen ({super.key});

  @override
  Widget build(BuildContext context){
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: const [
              BurbujaChat(texto: '¡Hola vecinos! ¿Saben a qué hora pasa el camión de la basura hoy?', esMio: false),
              BurbujaChat(texto: 'Hola, suele pasar a las 4:00 PM.', esMio: true),
              BurbujaChat(texto: 'Muchas gracias por el dato.', esMio: false),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              const Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Escibe un mensaje...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send, color: Color.fromARGB(255, 18, 109, 151)),
                onPressed: (

                ) {

                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BurbujaChat extends StatelessWidget {
  final String texto;
  final bool esMio;

  const BurbujaChat({super.key, required this.texto, required this.esMio});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: esMio ? const Color.fromARGB(255, 18, 109, 151) : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          texto,
          style: TextStyle(color: esMio ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}