import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:powersync_flutter_demo/attachment_queue/local_storage_adapter.dart';

class LocalStorageAdapter implements AbstractLocalStorageAdapter {
  @override
  Future<void> writeFile(String fileUri, String data) async {
    final file = File(fileUri);
    await file.writeAsString(data);
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

  Future<Uint8List> base64ToArrayBuffer(String str) async {
    return base64.decode(str);
  }

  Future<Uint8List> stringToArrayBuffer(String str) async {
    const encoder = Utf8Encoder();
    List<int> encodedBytes = encoder.convert(str);
    Uint8List uint8List = Uint8List.fromList(encodedBytes);

    return uint8List;
  }
}
