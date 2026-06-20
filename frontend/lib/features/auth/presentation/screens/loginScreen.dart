import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontend/features/auth/presentation/screens/forgotScreen.dart';
import 'package:frontend/features/home/presentation/screens/home_screen.dart';

class LoginScreen extends StatelessWidget{
  const LoginScreen ({super.key});

  @override
  Widget build(BuildContext context){
    return Scaffold(
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
            color: const Color.fromARGB(255, 255, 255, 255).withValues(alpha: 0.3),
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
                    Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                    const SizedBox(height: 20.0),
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
                        fillColor: const Color.fromARGB(225, 255, 255, 255).withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        labelStyle: const TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontSize: 16.0),
                        hintText: 'Ingrese su contraseña',
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
                        fillColor: const Color.fromARGB(225, 255, 255, 255).withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: (){
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ForgotPassword()),
                            );
                          },
                          child: const Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(
                              color: Color.fromARGB(255, 0, 8, 255),
                              fontSize: 15.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10.0),
                    Center(
                      child: 
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const HomeScreen()),
                            (Route<dynamic> route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 19, 132, 198),
                          foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                          elevation: 5,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          shadowColor: const Color.fromARGB(255, 9, 230, 255),
                        ),
                        child: const Text(
                          'Iniciar Sesión',
                          style: TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255),
                            fontSize: 17.0,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}