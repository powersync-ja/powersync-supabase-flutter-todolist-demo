import 'dart:async';

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

  Future<Attachment> savePhoto(String photoId, int size) async {
    String filename = '$photoId.jpg';
    Attachment photoAttachment = Attachment(
      id: photoId,
      filename: filename,
      state: AttachmentState.queuedUpload.index,
      mediaType: 'image/jpeg',
      localUri: attachmentsService.getLocalFilePathSuffix(filename),
      size: size,
    );

    return attachmentsService.saveRecord(photoAttachment);
  }

  @override
  StreamSubscription<void> watchIds() {
    log.info('Watching photos in todos...');
    return db.watch('''
      SELECT photo_id FROM todos
      WHERE photo_id IS NOT NULL
    ''').map((results) {
      return results.map((row) => row['photo_id'] as String).toList();
    }).listen((ids) async {
      List<String> idsInQueue = await attachmentsService.getAttachmentIds();
      for (String id in ids) {
        log.info('Reconciling photo with id:$id');
        await syncingService.reconcileId(id, idsInQueue);
      }
    });
  }
}
