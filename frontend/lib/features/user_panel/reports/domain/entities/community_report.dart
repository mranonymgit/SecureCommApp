import 'dart:typed_data';

class CommunityReport {
  final String? id;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final Uint8List? imageBytes;
  final String? imagePath;

  const CommunityReport({
    this.id,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.imageBytes,
    this.imagePath,
  });
}