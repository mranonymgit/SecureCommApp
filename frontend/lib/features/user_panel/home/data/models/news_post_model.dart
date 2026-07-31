import '../../domain/entities/news_post.dart';

class NewsPostModel extends NewsPost {
  const NewsPostModel({
    required super.id,
    required super.adminNombre,
    required super.adminFoto,
    required super.fecha,
    required super.hora,
    required super.titulo,
    required super.descripcion,
    super.imagen,
    required super.likes,
    required super.dislikes,
    super.userReaction,
  });

  factory NewsPostModel.fromJson(Map<String, dynamic> json) {
    final createdAt = (json['created_at'] ?? json['date'] ?? '').toString();
    final parsed = DateTime.tryParse(createdAt);
    final fecha = parsed == null
        ? createdAt
        : '${parsed.day.toString().padLeft(2, '0')} de ${_monthName(parsed.month)}, ${parsed.year}';
    final hora = parsed == null
        ? (json['hora'] ?? '').toString()
        : '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';

    return NewsPostModel(
      id: (json['id'] ?? '').toString(),
      adminNombre: (json['author'] ?? json['adminNombre'] ?? 'Administración').toString(),
      adminFoto: (json['adminFoto'] ?? json['author_avatar'] ?? '').toString(),
      fecha: fecha,
      hora: hora,
      titulo: (json['title'] ?? json['titulo'] ?? '').toString(),
      descripcion: (json['content'] ?? json['descripcion'] ?? '').toString(),
      imagen: (json['image_url'] ?? json['imagen'])?.toString(),
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      dislikes: (json['dislikes'] as num?)?.toInt() ?? 0,
      userReaction: (json['user_reaction'] ?? json['userReaction'])?.toString(),
    );
  }

  static String _monthName(int month) {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return months[month - 1];
  }
}
