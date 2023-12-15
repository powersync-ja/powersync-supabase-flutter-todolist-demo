import 'dart:async';

import 'package:powersync/powersync.dart';
import 'package:powersync_flutter_demo/attachment_queue/attachments_service.dart';
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

  /// Create watcher to get list of ID's from a table to be used for syncing in the attachment queue
  StreamSubscription<void> watchIds();

  init() async {
    // Ensure the directory where attachments are downloaded, exists
    await localStorage.makeDir(await attachmentsService.getStorageDirectory());

    watchIds();
    syncingService.watchUploads();
    syncingService.watchDownloads();
    syncingService.watchDeletes();

    db.statusStream.listen((status) {
      log.info('CONNECTED', db.currentStatus.connected);
      if (db.currentStatus.connected) {
        trigger();
      }
    });
  }

  trigger() {
    syncingService.runDownloads();
    syncingService.runDeletes();
    syncingService.runUploads();
  }
}
