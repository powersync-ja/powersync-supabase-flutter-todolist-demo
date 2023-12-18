import 'dart:io';
import 'dart:typed_data';

/// Abstract class used to implement the local storage adapter
abstract class AbstractLocalStorageAdapter {
  /// Save file to local storage
  /// e.g. File('path/to/file.txt').writeAsBytesSync(data)
  Future<File> saveFile(String fileURI, Uint8List data);

  /// Read file from local storage
  /// e.g. File('path/to/file.txt').readAsBytesSync()
  Future<Uint8List> readFile(String fileUri, {String mediaType});

  /// Delete file from local storage
  /// e.g. File('path/to/file.txt').delete()
  Future<void> deleteFile(String uri);

  /// Check if file exists in local storage
  /// e.g. File('path/to/file.txt').exists()
  Future<bool> fileExists(String fileUri);

  /// Make directory in local storage
  /// e.g. Directory('path/to/directory').create(recursive: true)
  Future<void> makeDir(String uri);

  /// Copy file from one location to another
  /// e.g. File('path/to/file.txt').copy('path/to/destination.txt')
  Future<void> copyFile(String sourceUri, String targetUri);

  /// Get the user storage directory
  /// e.g. await getApplicationDocumentsDirectory()
  Future<String> getUserStorageDirectory();
}
