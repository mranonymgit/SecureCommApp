import 'package:file_picker/file_picker.dart';

mixin MediaPickerMixin {
  Future<PlatformFile?> pickMedia() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.media,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.single;
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
