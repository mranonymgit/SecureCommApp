import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:frontend/features/auth/presentation/screens/loginScreen.dart';

class ForgotPassword extends StatelessWidget {
  const ForgotPassword ({super.key});

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Restablecer Contraseña'),
        backgroundColor: const Color.fromARGB(255, 18, 89, 115),
        foregroundColor: Colors.white,
        leading: IconButton(
        icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      resizeToAvoidBottomInset: false, 
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg_login.jpeg'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Container(
            color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.2),
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                padding: const EdgeInsets.all(20.0),
                decoration: const BoxDecoration(
                  color: Color.fromARGB(26, 0, 187, 212),
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min, 
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Usuario',
                        labelStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 16.0),
                        hintText: 'Ingrese su usuario', // Corregido typo "usurario"
                        hintStyle: const TextStyle(color: Color.fromARGB(139, 72, 72, 72), fontSize: 16.0),
                        prefixIcon: const Icon(Icons.person),
                        prefixIconColor: const Color.fromARGB(255, 0, 0, 0),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(
                            color: Color.fromARGB(148, 107, 136, 150),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13.0),
                          borderSide: const BorderSide(
                            color: Color.fromARGB(209, 18, 49, 151),
                            width: 2.5,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color.fromARGB(225, 255, 255, 255).withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 20.0,),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Nueva Contraseña',
                        labelStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 16.0),
                        hintText: 'Ingrese la nueva contraseña', // Corregido typo "usurario"
                        hintStyle: const TextStyle(color: Color.fromARGB(139, 72, 72, 72), fontSize: 16.0),
                        prefixIcon: const Icon(Icons.key),
                        prefixIconColor: const Color.fromARGB(255, 0, 0, 0),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(
                            color: Color.fromARGB(148, 107, 136, 150),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13.0),
                          borderSide: const BorderSide(
                            color: Color.fromARGB(209, 18, 49, 151),
                            width: 2.5,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color.fromARGB(225, 255, 255, 255).withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 20.0,),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Confirme la Contraseña',
                        labelStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 16.0),
                        hintText: 'Ingrese nuevamente la contraseña', // Corregido typo "usurario"
                        hintStyle: const TextStyle(color: Color.fromARGB(139, 72, 72, 72), fontSize: 16.0),
                        prefixIcon: const Icon(Icons.key),
                        prefixIconColor: const Color.fromARGB(255, 0, 0, 0),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(
                            color: Color.fromARGB(148, 107, 136, 150),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13.0),
                          borderSide: const BorderSide(
                            color: Color.fromARGB(209, 18, 49, 151),
                            width: 2.5,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color.fromARGB(225, 255, 255, 255).withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (Route<dynamic> route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 19, 198, 91),
                          foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                          elevation: 5,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          shadowColor: const Color.fromARGB(255, 9, 255, 29),
                        ),
                        child: const Text(
                          'Enviar Solicitud',
                          style: TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255),
                            fontSize: 17.0,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        )
      )
    );
  }
}