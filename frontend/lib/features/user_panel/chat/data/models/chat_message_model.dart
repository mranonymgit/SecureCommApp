import '../../domain/entities/mensaje_chat.dart';

class MensajeChatModel extends MensajeChat {
  const MensajeChatModel({
    required super.id,
    required super.usuarioId,
    required super.nombreUsuario,
    required super.avatarUrl,
    required super.tipoUsuario,
    super.texto,
    super.audioUrl,
    super.duracionAudio,
    required super.fechaHora,
    required super.esMio,
  });

  factory MensajeChatModel.fromJson(
    Map<String, dynamic> json, {
    required String currentUserId,
  }) {
    final senderId =
        (json['usuario_id'] ?? json['usuarioId'] ?? json['sender'] ?? '')
            .toString();
    final audioDurationSeconds =
        json['duracion_audio_segundos'] ?? json['duracionAudioSegundos'];
    final timestamp =
        json['fecha_hora'] ?? json['fechaHora'] ?? json['created_at'];
    final parsedTimestamp = timestamp == null
        ? null
        : DateTime.tryParse(timestamp.toString());
    if (parsedTimestamp == null) {
      throw FormatException('Chat message is missing a valid timestamp.');
    }
    return MensajeChatModel(
      id: (json['id'] ?? '').toString(),
      usuarioId: senderId,
      nombreUsuario:
          (json['nombre_usuario'] ?? json['nombreUsuario'] ?? 'Usuario')
              .toString(),
      avatarUrl: (json['avatar_url'] ?? json['avatarUrl'] ?? '').toString(),
      tipoUsuario:
          (json['tipo_usuario'] ?? json['tipoUsuario'] ?? '').toString() ==
              'admin'
          ? TipoUsuario.admin
          : TipoUsuario.usuario,
      texto: (json['texto'] ?? json['body'])?.toString(),
      audioUrl: (json['audio_url'] ?? json['audioUrl'])?.toString(),
      duracionAudio: audioDurationSeconds != null
          ? Duration(
              seconds: int.tryParse(audioDurationSeconds.toString()) ?? 0,
            )
          : null,
      fechaHora: parsedTimestamp.toLocal(),
      esMio: (json['es_mio'] as bool?) ?? senderId == currentUserId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuarioId': usuarioId,
      'nombreUsuario': nombreUsuario,
      'avatarUrl': avatarUrl,
      'tipoUsuario': tipoUsuario.name,
      'texto': texto,
      'audioUrl': audioUrl,
      'duracionAudioSegundos': duracionAudio?.inSeconds,
      'fechaHora': fechaHora.toIso8601String(),
    };
  }
}
