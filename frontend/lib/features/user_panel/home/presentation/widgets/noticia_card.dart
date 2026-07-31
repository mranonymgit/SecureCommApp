import 'package:flutter/material.dart';
import '../../domain/entities/news_post.dart';

class NoticiaCard extends StatefulWidget {
  final NewsPost noticia;
  final VoidCallback onLike;
  final VoidCallback onDislike;

  const NoticiaCard({
    super.key,
    required this.noticia,
    required this.onLike,
    required this.onDislike,
  });

  @override
  State<NoticiaCard> createState() => _NoticiaCardState();
}

class _NoticiaCardState extends State<NoticiaCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final noticia = widget.noticia;
    final bool esLarga = noticia.descripcion.length > 120;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.surface,
                child: ClipOval(
                  child: Image.network(
                    noticia.adminFoto,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.person, color: theme.colorScheme.onSurface),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            noticia.adminNombre,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Admin',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${noticia.fecha} • ${noticia.hora}',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            noticia.titulo,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            noticia.descripcion,
            maxLines: _isExpanded ? null : 3,
            overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          if (esLarga) ...[
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _isExpanded ? 'Ver menos' : 'Ver más',
                  style: TextStyle(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
          if (noticia.imagen != null && noticia.imagen!.isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                noticia.imagen!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: theme.colorScheme.surface,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image,
                              color: theme.colorScheme.onSurface.withOpacity(0.4), size: 40),
                          const SizedBox(height: 4),
                          Text(
                            'Error al cargar la imagen',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.4),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    color: theme.colorScheme.surface,
                    child: Center(
                      child: CircularProgressIndicator(color: theme.colorScheme.primary),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          Divider(color: theme.dividerColor),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: widget.onLike,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        noticia.userReaction == 'like'
                            ? Icons.thumb_up
                            : Icons.thumb_up_outlined,
                        color: noticia.userReaction == 'like'
                            ? theme.colorScheme.secondary
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${noticia.likes}',
                        style: TextStyle(
                          color: noticia.userReaction == 'like'
                              ? theme.colorScheme.secondary
                              : theme.colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: widget.onDislike,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        noticia.userReaction == 'dislike'
                            ? Icons.thumb_down
                            : Icons.thumb_down_outlined,
                        color: noticia.userReaction == 'dislike'
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${noticia.dislikes}',
                        style: TextStyle(
                          color: noticia.userReaction == 'dislike'
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}