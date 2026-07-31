import 'package:flutter/material.dart';

enum AppToastType { success, error, info, warning }

class AppToast {
  const AppToast._();

  static void success(BuildContext context, String message) {
    show(context, message, type: AppToastType.success);
  }

  static void error(BuildContext context, String message) {
    show(context, message, type: AppToastType.error);
  }

  static void info(BuildContext context, String message) {
    show(context, message, type: AppToastType.info);
  }

  static void warning(BuildContext context, String message) {
    show(context, message, type: AppToastType.warning);
  }

  static void show(
    BuildContext context,
    String message, {
    AppToastType type = AppToastType.info,
  }) {
    final theme = Theme.of(context);
    final color = switch (type) {
      AppToastType.success => const Color(0xFF16845B),
      AppToastType.error => theme.colorScheme.error,
      AppToastType.info => theme.colorScheme.primary,
      AppToastType.warning => const Color(0xFFE65100),
    };
    final icon = switch (type) {
      AppToastType.success => Icons.check_circle_outline,
      AppToastType.error => Icons.error_outline,
      AppToastType.info => Icons.info_outline,
      AppToastType.warning => Icons.warning_amber_rounded,
    };
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          elevation: 8,
          backgroundColor: const Color(0xFF202124),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: color.withValues(alpha: 0.75)),
          ),
          content: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, height: 1.25),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
