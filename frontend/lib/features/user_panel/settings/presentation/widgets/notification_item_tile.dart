import 'package:flutter/material.dart';

class NotificationItemTile extends StatelessWidget {
  final Map<String, dynamic> notificacion;
  final Future<void> Function() onTap;
  final Future<bool> Function() onDelete;
  final Future<bool> Function() onMarkRead;
  final VoidCallback onDismissed;

  const NotificationItemTile({
    super.key,
    required this.notificacion,
    required this.onTap,
    required this.onDelete,
    required this.onMarkRead,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final bool leida = notificacion['leida'];
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(notificacion['id']),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          return onDelete();
        }
        await onMarkRead();
        return false;
      },
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20.0),
        margin: const EdgeInsets.only(bottom: 12.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Icon(Icons.delete, color: theme.colorScheme.onError),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        margin: const EdgeInsets.only(bottom: 12.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Icon(Icons.done, color: theme.colorScheme.onPrimary),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12.0),
        color: leida
            ? theme.cardColor
            : theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(
            color: leida
                ? theme.dividerColor
                : theme.colorScheme.primary.withValues(alpha: 0.5),
            width: leida ? 1.0 : 1.5,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: () => onTap(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: leida
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.08)
                        : theme.colorScheme.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    notificacion['icono'],
                    color: leida
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.54)
                        : theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notificacion['titulo'],
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: leida
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Text(
                            notificacion['fecha'],
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(alpha: 
                                0.38,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notificacion['mensaje'],
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.3,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!leida) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
