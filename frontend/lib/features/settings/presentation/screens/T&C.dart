import 'package:flutter/material.dart';

class TerminosYCondiciones extends StatelessWidget {
  const TerminosYCondiciones ({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos y Condiciones'),
        backgroundColor: const Color.fromARGB(255, 18, 109, 151),
        foregroundColor: Colors.white,
      ),
      // El SingleChildScrollView hace que todo su hijo sea deslizable
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0), // Margen para que el texto no toque los bordes
        child: Text(
          'Términos y Condiciones de Uso - SCA\n\n'

          'Versión 1.0 | Fecha de actualización: 25 de mayo de 2026\n\n'

          'Bienvenido a SCA (Sistema de Comunicación Vecinal), una plataforma diseñada para conectar y facilitar la comunicación entre vecinos de una misma colonia o comunidad. '
          'Al registrarte y utilizar nuestra aplicación, aceptas estos Términos y Condiciones. Te pedimos que los leas detenidamente.\n\n'

          '1. Aceptación de los Términos\n'
          'Al crear una cuenta o usar SCA, confirmas que has leído, entendido y aceptado estos Términos y Condiciones, así como nuestra Política de Privacidad. Si no estás de acuerdo, no debes usar la aplicación.\n\n'

          '2. Descripción del Servicio\n'
          'SCA es una plataforma digital que permite a los vecinos:\n'

          'Comunicarse mediante chats comunitarios\n'
          'Recibir noticias locales y alertas importantes\n'
          'Compartir información relevante sobre su colonia\n'
          'Acceder a servicios y notificaciones vecinales\n\n'

          'El servicio se encuentra actualmente en fase de desarrollo.\n\n'

          '3. Registro y Cuenta de Usuario\n'

          'Para usar SCA debes ser mayor de 18 años o contar con autorización de un tutor.\n'
          'Debes proporcionar información veraz y actualizada al registrarte.\n'
          'Eres responsable de mantener la confidencialidad de tu contraseña.\n\n'
          'SCA se reserva el derecho de suspender o eliminar cuentas que infrinjan estos términos.\n\n'


          '4. Uso Permitido y Prohibiciones\n'
          'Está permitido:\n'

          'Usar el chat para temas vecinales constructivos\n'
          'Compartir información útil para la comunidad\n\n'

          'Está prohibido:\n'

          'Publicar contenido violento, discriminatorio, ofensivo o ilegal\n'
          'Hacer spam, publicidad no autorizada o estafas\n'
          'Suplantar identidad de otros vecinos\n'
          'Recopilar datos de otros usuarios sin autorización\n'
          'Cualquier actividad que perjudique el buen funcionamiento de la plataforma\n\n'


          '5. Privacidad y Protección de Datos\n'

          'En SCA valoramos tu privacidad. Toda la información personal se trata conforme a nuestra Política de Privacidad. No vendemos tus datos a terceros.\n\n'

          '6. Propiedad Intelectual\n'
          'Todo el contenido, diseño, logos y funcionalidades de SCA son propiedad de sus desarrolladores. No puedes copiar, modificar o distribuir ningún elemento de la aplicación sin autorización.\n\n'

          '7. Limitación de Responsabilidad\n'
          'SCA se proporciona "tal cual" y "según disponibilidad". No garantizamos que el servicio esté libre de interrupciones o errores, especialmente por estar en desarrollo.\n'
          'No somos responsables por:\n'

          'Contenido publicado por los usuarios\n'
          'Daños o pérdidas derivadas del uso de la aplicación\n'
          'Interacciones entre vecinos fuera de la plataforma\n\n'


          '8. Modificaciones a los Términos\n'
          'Podemos actualizar estos Términos en cualquier momento. Te notificaremos los cambios importantes a través de la aplicación o por correo electrónico. El uso continuado de SCA después de los cambios implica tu aceptación.\n\n'

          '9. Terminación del Servicio\n'
          'Podemos suspender o terminar tu acceso a SCA en cualquier momento si incumples estos términos o por cualquier otra razón.\n\n'

          '10. Contacto\n'
          'Si tienes dudas sobre estos Términos y Condiciones, puedes contactarnos en:\n'

          'Correo: soporte@sca.app\n'
          'Dentro de la app: Sección “Ayuda y Soporte”\n\n\n'


          'Al usar SCA, contribuyes a crear una comunidad más conectada, informada y segura.\n'
          'Gracias por formar parte de esta iniciativa vecinal.',
          style: TextStyle(
            fontSize: 20,
            height: 1.5, // Interlineado cómodo para la lectura (UX)
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.justify, // Justifica el texto como un libro
        ),
      ),
    );
  }
}