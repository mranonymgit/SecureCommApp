import 'package:flutter/material.dart';

class AcercaDeTab extends StatelessWidget {
  const AcercaDeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          Image.asset(
            'assets/images/OIcon.png',
            width: 90,
            height: 90,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.location_city,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'SCA - Sistema de Comunicación Vecinal',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Text(
            'Versión 1.0.0 (Fase Beta)',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Theme.of(context).dividerColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¿Qué es SCA?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'SCA es una plataforma digital moderna creada para integrar a la comunidad. Nuestro objetivo es resolver problemas cotidianos del vecindario mediante el uso eficiente de la tecnología, promoviendo un entorno transparente, seguro y colaborativo.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.87),
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Theme.of(context).dividerColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Características Principales',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const FeatureTile(
                    icon: Icons.chat_bubble_outline,
                    title: 'Comunicación Directa',
                    subtitle:
                        'Chat comunitario y avisos del comité en tiempo real.',
                  ),
                  Divider(color: Theme.of(context).dividerColor),
                  const FeatureTile(
                    icon: Icons.report_problem_outlined,
                    title: 'Reportes Vecinales',
                    subtitle:
                        'Gestiona incidencias y da seguimiento a su solución.',
                  ),
                  Divider(color: Theme.of(context).dividerColor),
                  const FeatureTile(
                    icon: Icons.security,
                    title: 'Comunidad Segura',
                    subtitle:
                        'Acceso exclusivo a residentes verificación de identidad.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '© 2026 SCA. Todos los derechos reservados.',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const FeatureTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TerminosYDatosTab extends StatelessWidget {
  const TerminosYDatosTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        'Términos, Condiciones y Uso de Datos - SCA\n\n'
        'Versión 1.0 | Fecha de actualización: 25 de mayo de 2026\n\n'
        'Bienvenido a SCA (Sistema de Comunicación Vecinal), una plataforma diseñada para conectar y facilitar la comunicación entre vecinos de una misma colonia o comunidad. '
        'Al registrarte y utilizar nuestra aplicación, aceptas estos Términos y Condiciones. Te pedimos que los leas detenidamente.\n\n'
        '1. Aceptación de los Términos\n'
        'Al crear una cuenta o usar SCA, confirmas que has leído, entendido y aceptado estos Términos y Condiciones, así como nuestra Política de Privacidad. Si no estás de acuerdo, no debes usar la aplicación.\n\n'
        '2. Descripción del Servicio\n'
        'SCA es una plataforma digital que permite a los vecinos:\n'
        '• Comunicarse mediante chats comunitarios\n'
        '• Recibir noticias locales y alertas importantes\n'
        '• Compartir información relevante sobre su colonia\n'
        '• Acceder a servicios y notificaciones vecinales\n\n'
        'El servicio se encuentra actualmente en fase de desarrollo.\n\n'
        '3. Registro y Cuenta de Usuario\n'
        '• Para usar SCA debes ser mayor de 18 años o contar con autorización de un tutor.\n'
        '• Debes proporcionar información veraz y actualizada al registrarte.\n'
        '• Eres responsable de mantener la confidencialidad de tu contraseña.\n'
        'SCA se reserva el derecho de suspender o eliminar cuentas que infrinjan estos términos.\n\n'
        '4. Uso Permitido y Prohibiciones\n'
        'Está permitido:\n'
        '• Usar el chat para temas vecinales constructivos\n'
        '• Compartir información útil para la comunidad\n\n'
        'Está prohibido:\n'
        '• Publicar contenido violento, discriminatorio, ofensivo o ilegal\n'
        '• Hacer spam, publicidad no autorizada o estafas\n'
        '• Suplantar identidad de otros vecinos\n'
        '• Recopilar datos de otros usuarios sin autorización\n'
        '• Cualquier actividad que perjudique el buen funcionamiento de la plataforma\n\n'
        '5. Privacidad y Tratamiento de Datos Personales\n'
        'En SCA la seguridad de tu información es fundamental. Respecto al uso de tus datos:\n'
        '• Recopilamos datos básicos (nombre, correo, teléfono y dirección) únicamente para validar tu residencia en la comunidad.\n'
        '• Los datos de uso y ubicación opcional se emplean exclusivamente para enviar alertas y notificaciones locales precisas.\n'
        '• No vendemos, alquilamos ni compartimos tus datos personales con terceros con fines comerciales.\n'
        '• Puedes solicitar la eliminación de tu cuenta y datos asociados en cualquier momento mediante la opción de soporte dentro de la aplicación.\n\n'
        '6. Propiedad Intelectual\n'
        'Todo el contenido, diseño, logos y funcionalidades de SCA son propiedad de sus desarrolladores. No puedes copiar, modificar o distribuir ningún elemento de la aplicación sin autorización.\n\n'
        '7. Limitación de Responsabilidad\n'
        'SCA se proporciona "tal cual" y "según disponibilidad". No garantizamos que el servicio esté libre de interrupciones o errores, especialmente por estar en desarrollo.\n'
        'No somos responsables por:\n'
        '• Contenido publicado por los usuarios\n'
        '• Daños o pérdidas derivadas del uso de la aplicación\n'
        '• Interacciones entre vecinos fuera de la plataforma\n\n'
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
          fontSize: 14,
          height: 1.6,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.87),
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }
}
