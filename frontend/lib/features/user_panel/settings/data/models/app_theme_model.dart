enum AppThemeMode { light, dark, deuteranopia, protanopia, tritanopia }

class AppThemeOption {
  final String id;
  final String title;
  final String description;
  final AppThemeMode mode;

  const AppThemeOption({
    required this.id,
    required this.title,
    required this.description,
    required this.mode,
  });
}