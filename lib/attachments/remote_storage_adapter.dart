import 'dart:io';
import 'dart:typed_data';
import 'package:powersync_flutter_demo/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:powersync_flutter_demo/attachment_queue/remote_storage_adapter.dart';

class SupabaseStorageAdapter implements AbstractRemoteStorageAdapter {
  @override
  Future<void> uploadFile(String filename, File file,
      {String mediaType = 'text/plain'}) async {
    checkSupabaseBucketIsConfigured();

    try {
      await Supabase.instance.client.storage
          .from(AppConfig.supabaseStorageBucket)
          .upload(filename, file,
              fileOptions: FileOptions(contentType: mediaType));
    } catch (error) {
      throw Exception(error);
    }
  }

  @override
  Future<Uint8List> downloadFile(String filePath) async {
    checkSupabaseBucketIsConfigured();
    try {
      Uint8List blob = await Supabase.instance.client.storage
          .from(AppConfig.supabaseStorageBucket)
          .download(filePath);
      return blob;
    } catch (error) {
      throw Exception(error);
    }
  }

  @override
  Future<FileObject> deleteFile(String filename) async {
    checkSupabaseBucketIsConfigured();

    try {
      List<FileObject> blob = await Supabase.instance.client.storage
          .from(AppConfig.supabaseStorageBucket)
          .remove([filename]);
      return blob.first;
    } catch (error) {
      throw Exception(error);
    }
  }

  checkSupabaseBucketIsConfigured() {
    if (AppConfig.supabaseStorageBucket.isEmpty) {
      throw Exception(
          'Supabase storage bucket is not configured in app_config.dart');
    }
  }
}
