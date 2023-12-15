import 'dart:async';

import 'package:powersync/powersync.dart';
import 'package:powersync_flutter_demo/attachment_queue/attachments_service.dart';
import 'package:powersync_flutter_demo/attachment_queue/attachments_queue_table.dart';
import 'package:powersync_flutter_demo/attachment_queue/local_storage_adapter.dart';
import 'package:powersync_flutter_demo/attachment_queue/remote_storage_adapter.dart';
import 'package:powersync_flutter_demo/attachment_queue/syncing_service.dart';

abstract class AbstractAttachmentQueue {
  PowerSyncDatabase db;
  AbstractLocalStorageAdapter localStorage;
  AbstractRemoteStorageAdapter remoteStorage;
  String attachmentDirectoryName;
  late int syncInterval;
  late AttachmentsService attachmentsService;
  late SyncingService syncingService;

  AbstractAttachmentQueue(
      {required PowerSyncDatabase db,
      required AbstractLocalStorageAdapter localStorage,
      required AbstractRemoteStorageAdapter remoteStorage,
      String attachmentDirectoryName = 'attachments',
      int syncInterval = 30000,
      int cacheLimit = 100,
      performInitialSync = true})
      : this.db = db,
        this.localStorage = localStorage,
        this.remoteStorage = remoteStorage,
        this.syncInterval = syncInterval,
        this.attachmentDirectoryName = attachmentDirectoryName {
    attachmentsService =
        AttachmentsService(db, localStorage, attachmentDirectoryName);
    syncingService =
        SyncingService(db, remoteStorage, localStorage, attachmentsService);
  }

  /// Create a new Attachment, this gets called when the attachment id is not found in the database.
  Future<Attachment> createAttachment(Attachment attachment);

  /// Create watcher to get list of ID's from a table to be used for syncing in the attachment queue
  StreamSubscription<void> watchIds();

  init() async {
    // Ensure the directory where attachments are downloaded, exists
    await localStorage.makeDir(await attachmentsService.getStorageDirectory());

    watchIds();
    syncingService.watchUploads();
    syncingService.watchDownloads();
    syncingService.watchDeletes();

    // if (syncInterval > 0) {
    //   // In addition to watching for changes, we also trigger a sync every few seconds (30 seconds, by default)
    //   // This will retry any failed uploads/downloads, in particular after the app was offline
    //   setInterval(() => this.trigger(), syncInterval);
    // }
  }

  // trigger() {
  //   this.uploadRecords();
  //   this.downloadRecords();
  //   this.expireCache();
  // }
}
