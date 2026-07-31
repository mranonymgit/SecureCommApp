enum TipoUsuario { admin, usuario }

enum TipoMensaje { texto, audio }

class MensajeChat {
  final String id;
  final String usuarioId;
  final String nombreUsuario;
  final String avatarUrl;
  final TipoUsuario tipoUsuario;
  final String? texto;
  final String? audioUrl;
  final Duration? duracionAudio;
  final DateTime fechaHora;
  final bool esMio;

  const MensajeChat({
    required this.id,
    required this.usuarioId,
    required this.nombreUsuario,
    required this.avatarUrl,
    required this.tipoUsuario,
    this.texto,
    this.audioUrl,
    this.duracionAudio,
    required this.fechaHora,
    required this.esMio,
  });

  TipoMensaje get tipoMensaje =>
      audioUrl != null ? TipoMensaje.audio : TipoMensaje.texto;
}
