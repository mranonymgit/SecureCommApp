import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class ReproductorAudioWidget extends StatelessWidget {
  final Duration duracion;
  final bool esMio;
  final String audioUrl;

  const ReproductorAudioWidget({
    super.key,
    required this.duracion,
    required this.esMio,
    required this.audioUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Reproducir audio',
          icon: const Icon(Icons.play_arrow, color: Colors.white, size: 26),
          onPressed: () => launchUrl(
            Uri.parse(audioUrl),
            mode: LaunchMode.externalApplication,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: LinearProgressIndicator(
            value: 0.3,
            backgroundColor: Colors.white24,
            color: esMio ? AppColors.accent : Colors.tealAccent,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '0:${duracion.inSeconds.toString().padLeft(2, '0')}',
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }
}
