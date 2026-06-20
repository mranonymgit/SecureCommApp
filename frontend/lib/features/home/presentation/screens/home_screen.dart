import 'package:flutter/material.dart';
import 'package:frontend/features/news/presentation/widgets/tarjeta_noticia.dart';
import 'package:frontend/features/news/presentation/screens/reportScreen.dart';
import 'package:frontend/features/chat/presentation/screens/chatScreen.dart';
import 'package:frontend/features/settings/presentation/screens/T&C.dart';
import 'package:frontend/features/settings/presentation/screens/perfil.dart';
import 'package:frontend/features/settings/presentation/screens/settingsScreen.dart';
import 'package:frontend/features/maps/presentation/screens/map.dart';
import 'package:frontend/features/auth/presentation/screens/loginScreen.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  int _indiceActual = 1;

  void cerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(232, 18, 89, 115),
          title: const Text('¿Cerrar Sesión?', style: TextStyle(color: Color.fromARGB(255, 255, 255, 255), fontSize: 25.0)),
          content: const Text(
            'Tendrás que volver a introducir tu contraseña para acceder a la app vecinal.',
            style: TextStyle(color: Color.fromARGB(159, 255, 255, 255), fontSize: 18.0),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.blue, fontSize: 16.0)),
            ),
            TextButton(
              onPressed: () {
                // 1. Aquí borrarías los datos guardados del usuario (Tokens, SharedPreferences, etc.)
                
                // 2. LA MAGIA: Navega al Login y DESTRUYE todo lo anterior
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()), // Tu pantalla de Login
                  (Route<dynamic> route) => false, // Esta condición 'false' le dice a Flutter: "Borra todo el historial"
                );
              },
              child: const Text('Salir', style: TextStyle(color: Colors.redAccent, fontSize: 16.0)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _ = [
      const CreateReportScreen(),
      ListView.builder(itemCount: 3, itemBuilder: (context, index) {
        return TarjetaNoticia(titulo: 'Noticia vecinal número $index', fecha: 'Hace $index horas');
      },),
      const Chatscreen(),
      const MapaLocal(),
      ];
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: const Text(
          'Mi Comunidad',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color.fromARGB(221, 255, 255, 255)),
        ),
        backgroundColor: const Color.fromARGB(255, 18, 89, 115),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Opciones',
            offset: const Offset(0, 40),
            elevation: 4,
            icon: const Icon(
              Icons.menu,
              color: Color.fromARGB(255, 255, 255, 255),
              size: 36,
            ),
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  value: 'perfil',
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.black),
                      SizedBox(width: 10),
                      Text('Mi Perfil', style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  value: 'configuracion',
                  child: Row(
                    children: [
                      Icon(Icons.settings, color: Colors.black),
                      SizedBox(width: 10),
                      Text('Configuración', style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  value: 'privacidad',
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.black),
                      SizedBox(width: 10),
                      Text('Información', style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.exit_to_app, color: Colors.black),
                      SizedBox(width: 10),
                      Text('Cerrar Sesión', style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
              ];
            },
            onSelected: (String valorSeleccionado) {
              if(valorSeleccionado == 'perfil'){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Perfil()
                  )
                );
              } else if(valorSeleccionado == 'configuracion'){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Settingsscreen()
                  )
                );
              }
              else if(valorSeleccionado == 'privacidad'){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TerminosYCondiciones()
                  )
                );
              }
              else{
                cerrarSesion(context);
              }
            },
          )
        ],
      ),
      body: IndexedStack(
        index: _indiceActual,
        children: [
          const CreateReportScreen(),
          ListView.builder(
            itemCount: 3, 
            itemBuilder: (context, index) {
              return TarjetaNoticia(titulo: 'Noticia vecinal número $index', fecha: 'Hace $index horas');
            },
          ),
          const Chatscreen(),
          const MapaLocal(),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 10),
          child: GNav(
            backgroundColor: Colors.white,
            color: Colors.blueGrey,
            activeColor: const Color(0xFF0765BD),
            tabBackgroundColor: const Color(0xFFE0F7FA),
            gap: 8,
            padding: const EdgeInsets.all(16),
            selectedIndex: _indiceActual,
            onTabChange: (index) {
              setState(() {
                _indiceActual = index;
              });
            },
            tabs: const [
              GButton(icon: Icons.emergency, text: 'Reportar'),
              GButton(icon: Icons.home, text: 'Inicio'),
              GButton(icon: Icons.chat, text: 'Chat'),
              GButton(icon: Icons.map, text: 'Mapa'),
            ],
          ),
        ),
      ),
    );
  }
}