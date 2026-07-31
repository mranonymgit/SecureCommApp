import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../domain/entities/mensaje_chat.dart';
import 'reproductor_audio_widget.dart';

class BurbujaChat extends StatelessWidget {
  final MensajeChat mensaje; // Usar la entidad MensajeChat de dominio

  const BurbujaChat({super.key, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    final esAdmin = mensaje.tipoUsuario == TipoUsuario.admin;

    final Color colorBorde = mensaje.esMio
        ? Colors.transparent
        : (esAdmin ? Colors.redAccent.shade200 : Colors.tealAccent.shade400);

    final Color colorNombre = mensaje.esMio
        ? AppColors.accent
        : (esAdmin ? Colors.redAccent : Colors.tealAccent);

    final Color colorFondo = mensaje.esMio
        ? AppColors.primaryDark
        : (esAdmin ? const Color(0xFF2D1818) : const Color(0xFF1E1E1E));

    final Color colorTexto = Colors.white.withValues(alpha: 0.9);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: mensaje.esMio ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!mensaje.esMio) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: colorFondo,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(mensaje.esMio ? 14 : 2),
                  bottomRight: Radius.circular(mensaje.esMio ? 2 : 14),
                ),
                border: Border.all(
                  color: colorBorde,
                  width: mensaje.esMio ? 0 : 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!mensaje.esMio) ...[
                    Text(
                      mensaje.nombreUsuario,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorNombre,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (mensaje.audioUrl != null)
                    ReproductorAudioWidget(
                      duracion: mensaje.duracionAudio ?? const Duration(seconds: 0),
                      esMio: mensaje.esMio,
                    )
                  else
                    Text(
                      mensaje.texto ?? '',
                      style: TextStyle(color: colorTexto, fontSize: 14, height: 1.3),
                    ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      '${mensaje.fechaHora.hour.toString().padLeft(2, '0')}:${mensaje.fechaHora.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (mensaje.esMio) ...[
            const SizedBox(width: 8),
            _buildAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.grey.shade800,
      child: ClipOval(
        child: Image.network(
          mensaje.avatarUrl,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.person, color: Colors.white54, size: 18),
        ),
      ),
    );
  }
}