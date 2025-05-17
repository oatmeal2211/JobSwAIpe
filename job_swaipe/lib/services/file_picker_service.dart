import 'dart:io' show Platform;

import 'package:file_picker/file_picker.dart';

class FilePickerService {
  Future<FilePickerResult?> pickFile() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return await FilePicker.platform.pickFiles();
    } else {
      // Handle other platforms or show a message
      return null;
    }
  }
}
