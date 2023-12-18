import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:powersync_flutter_demo/attachment_queue/local_storage_adapter.dart';

class LocalStorageAdapter implements AbstractLocalStorageAdapter {
  @override
  Future<File> saveFile(String fileUri, Uint8List data) async {
    final file = File(fileUri);
    return await file.writeAsBytes(data);
  }

  @override
  Future<Uint8List> readFile(String fileUri, {String? mediaType}) async {
    final file = File(fileUri);
    return await file.readAsBytes();
  }

  @override
  Future<void> deleteFile(String fileUri) async {
    if (await fileExists(fileUri)) {
      File file = File(fileUri);
      await file.delete();
    }
  }

  @override
  Future<bool> fileExists(String fileUri) async {
    File file = File(fileUri);
    bool exists = await file.exists();
    return exists;
  }

  @override
  Future<void> makeDir(String fileUri) async {
    bool exists = await fileExists(fileUri);
    if (!exists) {
      Directory newDirectory = Directory(fileUri);
      await newDirectory.create(recursive: true);
    }
  }

  @override
  Future<void> copyFile(String sourceUri, String targetUri) async {
    File file = File(sourceUri);
    await file.copy(targetUri);
  }

  @override
  Future<String> getUserStorageDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }
}
