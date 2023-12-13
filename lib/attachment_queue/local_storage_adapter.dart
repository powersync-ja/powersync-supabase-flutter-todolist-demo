import 'dart:typed_data';

abstract class AbstractLocalStorageAdapter {
  Future<void> writeFile(String fileURI, String data);

  Future<Uint8List> readFile(String fileUri, {String mediaType});

  Future<void> deleteFile(String uri);

  Future<bool> fileExists(String fileUri);

  Future<void> makeDir(String uri);

  Future<void> copyFile(String sourceUri, String targetUri);

  Future<String> getUserStorageDirectory();
}
