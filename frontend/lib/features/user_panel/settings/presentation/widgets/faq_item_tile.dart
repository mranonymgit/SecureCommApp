import 'package:flutter/material.dart';

class FaqItemTile extends StatelessWidget {
  final String pregunta;
  final String respuesta;

  const FaqItemTile({
    super.key,
    required this.pregunta,
    required this.respuesta,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: theme.colorScheme.primary,
          collapsedIconColor: theme.colorScheme.onSurface.withOpacity(0.54),
          title: Text(
            pregunta,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: theme.colorScheme.onSurface,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                respuesta,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}