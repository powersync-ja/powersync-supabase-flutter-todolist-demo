import 'dart:io';

import 'package:powersync/powersync.dart';
import 'package:powersync_flutter_demo/app_config.dart';
import 'package:powersync_flutter_demo/attachment_queue/attachments_queue.dart';
import 'package:powersync_flutter_demo/attachment_queue/attachments_queue_table.dart';
import 'package:powersync_flutter_demo/attachment_queue/syncing_service.dart';

/// Global reference to the queue
late final PhotoAttachmentQueue attachmentQueue;

class PhotoAttachmentQueue extends AbstractAttachmentQueue {
  PhotoAttachmentQueue(db, localStorage, remoteStorage)
      : super(db: db, localStorage: localStorage, remoteStorage: remoteStorage);

  @override
  init() async {
    if (AppConfig.supabaseStorageBucket.isEmpty) {
      log.info(
          'No Supabase bucket configured, skip setting up PhotoAttachmentQueue watches');
      // Disable sync interval to prevent errors from trying to sync to a non-existent bucket
      syncInterval = 0;
      return;
    }

    await super.init();
  }

  @override
  Future<Attachment> createAttachment(Attachment attachment) async {
    String photoId = attachment.id;
    String filename = '${attachment.filename}.jpg';
    return Attachment(
      id: photoId,
      filename: filename,
      mediaType: 'image/jpeg',
      state: AttachmentState.queuedUpload.index,
      localUri: attachment.localUri,
      timestamp: attachment.timestamp,
      size: attachment.size,
    );
  }

  Future<Attachment> savePhoto(
      String photoId, String filename, int size, String data) async {
    String localUri = await attachmentService.getLocalUri(filename);

    Attachment photoAttachment = Attachment(
      id: photoId,
      filename: filename,
      state: AttachmentState.queuedUpload.index,
      mediaType: 'image/jpeg',
      localUri: attachmentService.getLocalFilePathSuffix(filename),
      size: size,
    );

    try {
      await localStorage.writeFile(localUri, data);
    } catch (e) {
      log.severe(e);
    }

    return attachmentService.saveRecord(photoAttachment);
  }
}
