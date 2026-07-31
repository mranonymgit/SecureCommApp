import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileAvatarPicker extends StatelessWidget {
  final XFile? imageFile;
  final String? avatarDataUrl;
  final VoidCallback onPickImage;

  const ProfileAvatarPicker({
    super.key,
    required this.imageFile,
    this.avatarDataUrl,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    ImageProvider? imageProvider;

    if (imageFile != null) {
      if (kIsWeb) {
        imageProvider = NetworkImage(imageFile!.path);
      } else {
        imageProvider = FileImage(File(imageFile!.path));
      }
    } else if (avatarDataUrl != null &&
        avatarDataUrl!.startsWith('data:image')) {
      final base64Index = avatarDataUrl!.indexOf('base64,');
      if (base64Index != -1) {
        final raw = avatarDataUrl!.substring(base64Index + 7);
        imageProvider = MemoryImage(base64Decode(raw));
      }
    } else if (avatarDataUrl != null &&
        (avatarDataUrl!.startsWith('https://') ||
            avatarDataUrl!.startsWith('http://'))) {
      imageProvider = NetworkImage(avatarDataUrl!);
    }

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.primary, width: 2),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 60,
            backgroundColor: theme.cardColor,
            backgroundImage: imageProvider,
            child: imageFile == null
                ? Icon(
                    Icons.person,
                    size: 70,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                  )
                : null,
          ),
        ),
        Positioned(
          bottom: -4,
          right: -4,
          child: Material(
            color: theme.colorScheme.primary,
            shape: const CircleBorder(),
            elevation: 4,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPickImage,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: 20,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
