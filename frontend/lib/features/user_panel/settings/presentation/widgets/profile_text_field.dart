import 'package:flutter/material.dart';

class ProfileTextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;

  const ProfileTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: 14,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.38),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: theme.colorScheme.onSurface.withOpacity(0.54),
            size: 22,
          ),
          filled: true,
          fillColor: theme.cardColor,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.0),
            borderSide: BorderSide(
              color: theme.dividerColor,
              width: 1.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.0),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}