class NewsPost {
  final String id;
  final String adminNombre;
  final String adminFoto;
  final String fecha;
  final String hora;
  final String titulo;
  final String descripcion;
  final String? imagen;
  final String? linkUrl;
  final int likes;
  final int dislikes;
  final String? userReaction; // 'like', 'dislike', o null

  const NewsPost({
    required this.id,
    required this.adminNombre,
    required this.adminFoto,
    required this.fecha,
    required this.hora,
    required this.titulo,
    required this.descripcion,
    this.imagen,
    this.linkUrl,
    required this.likes,
    required this.dislikes,
    this.userReaction,
  });

  NewsPost copyWith({
    int? likes,
    int? dislikes,
    String? userReaction,
    bool forceNullReaction = false,
  }) {
    return NewsPost(
      id: id,
      adminNombre: adminNombre,
      adminFoto: adminFoto,
      fecha: fecha,
      hora: hora,
      titulo: titulo,
      descripcion: descripcion,
      imagen: imagen,
      linkUrl: linkUrl,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      userReaction: forceNullReaction
          ? null
          : (userReaction ?? this.userReaction),
    );
  }
}
