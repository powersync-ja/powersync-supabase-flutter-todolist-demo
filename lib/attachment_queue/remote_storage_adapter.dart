import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AbstractRemoteStorageAdapter {
  Future<void> uploadFile(String filePath, File file, {String mediaType});

  Future<Uint8List> downloadFile(String filePath);

  Future<FileObject> deleteFile(String filename);
}
