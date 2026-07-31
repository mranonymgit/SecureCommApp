import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_theme.dart';

class ThemeOptionTile extends StatelessWidget {
  final ColorBlindnessTheme tema;
  final bool isSelected;
  final ValueChanged<ColorBlindnessTheme?> onSelect;

  const ThemeOptionTile({
    super.key,
    required this.tema,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: ListTile(
            title: Text(tema.name),
            subtitle: Text(tema.description),
            leading: Radio<String>(
              value: tema.key,
              groupValue: isSelected ? tema.key : null,
              activeColor: theme.colorScheme.primary,
              onChanged: (_) => onSelect(tema),
            ),
            onTap: () => onSelect(tema),
          ),
        ),
      ),
    );
  }
}
