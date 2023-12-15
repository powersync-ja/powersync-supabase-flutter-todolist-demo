import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:logging/logging.dart';
import 'package:powersync/powersync.dart';
import 'package:powersync_flutter_demo/attachment_queue/local_storage_adapter.dart';
import 'package:powersync_flutter_demo/attachment_queue/remote_storage_adapter.dart';
import 'attachments_queue_table.dart';
import './attachments_service.dart';

final log = Logger('Upload');

class SyncingService {
  final PowerSyncDatabase db;
  final AbstractRemoteStorageAdapter remoteStorage;
  final AbstractLocalStorageAdapter localStorage;
  final AttachmentsService attachmentsService;

  SyncingService(
      this.db, this.remoteStorage, this.localStorage, this.attachmentsService);

  get table {
    return ATTACHMENTS_QUEUE_TABLE;
  }

  Future<void> uploadAttachment(Attachment attachment) async {
    if (attachment.localUri == null) {
      throw Exception('No localUri for record $attachment');
    }

    String imagePath =
        await attachmentsService.getLocalUri(attachment.filename);

    try {
      await remoteStorage.uploadFile(attachment.filename, File(imagePath),
          mediaType: attachment.mediaType!);
      // Mark as uploaded
      await attachmentsService.deleteAttachment(attachment.id);
      log.info('Uploaded attachment "${attachment.id}" to Cloud Storage');
      return;
    } catch (e) {
      if (e == 'Duplicate') {
        log.warning(
            'File already uploaded, marking ${attachment.id} as synced');
        await attachmentsService.deleteAttachment(attachment.id);
        return;
      }
      log.severe('UploadAttachment error for record $attachment', e);
      return;
    }
  }

  Future<bool> downloadAttachment(Attachment attachment) async {
    String imagePath =
        await attachmentsService.getLocalUri(attachment.filename);

    try {
      Uint8List fileBlob =
          await remoteStorage.downloadFile(attachment.filename);

      // Ensure directory exists
      await localStorage
          .makeDir(await attachmentsService.getStorageDirectory());

      await File(imagePath).writeAsBytes(fileBlob);
      // await File(imagePath).delete();

      log.info('Downloaded file "${attachment.id}"');
      await attachmentsService.deleteAttachment(attachment.id);
      return true;
    } catch (e) {
      log.severe('Download attachment error for record $attachment}', e);
      return false;
    }
  }

  Future<void> deleteAttachment(Attachment record) async {
    String fileUri = await attachmentsService.getLocalUri(record.filename);
    try {
      await remoteStorage.deleteFile(record.filename);
      await localStorage.deleteFile(fileUri);
      await attachmentsService.deleteAttachment(record.id);
    } catch (e) {
      log.severe(e);
    }
  }

  StreamSubscription<void> watchDownloads() {
    log.info('Watching downloads...');
    return db.watch('''
      SELECT * FROM $table
      WHERE state = ${AttachmentState.queuedDownload.index}
    ''').map((results) {
      return results.map((row) => Attachment.fromRow(row));
    }).listen((attachments) async {
      for (Attachment attachment in attachments) {
        log.info('Downloading ${attachment.filename}');
        await downloadAttachment(attachment);
      }
    });
  }

  StreamSubscription<void> watchUploads() {
    log.info('Watching uploads...');
    return db.watch('''
      SELECT * FROM $table
      WHERE local_uri IS NOT NULL
      AND state = ${AttachmentState.queuedUpload.index}
    ''').map((results) {
      return results.map((row) => Attachment.fromRow(row));
    }).listen((attachments) async {
      for (Attachment attachment in attachments) {
        log.info('Uploading ${attachment.filename}');
        await uploadAttachment(attachment);
      }
    });
  }

  StreamSubscription<void> watchDeletes() {
    log.info('Watching deletes...');
    return db.watch('''
      SELECT * FROM $table
      WHERE state = ${AttachmentState.queuedDelete.index}
    ''').map((results) {
      return results.map((row) => Attachment.fromRow(row));
    }).listen((attachments) async {
      for (Attachment attachment in attachments) {
        log.info('Deleting ${attachment.filename}');
        await deleteAttachment(attachment);
      }
    });
  }

  reconcileId(String id, List<String> idsNotInQueue) async {
    bool idIsNotInQueue = idsNotInQueue.contains(id);
    String imagePath = await attachmentsService.getLocalUri('$id.jpg');
    File file = File(imagePath);
    bool fileExists = await file.exists();

    if (idIsNotInQueue) {
      if (fileExists) {
        log.info('ignore file $id.jpg as it already exists');
        return;
      }
      log.info('Adding $id to queue');
      return await attachmentsService.saveRecord(Attachment(
        id: id,
        filename: '$id.jpg',
        state: AttachmentState.queuedDownload.index,
      ));
    }

    Attachment? attachment = await attachmentsService.getAttachment(id);
    if (attachment == null) {
      return;
    }

    int state = fileExists
        ? AttachmentState.queuedUpload.index
        : AttachmentState.queuedDownload.index;

    log.info('Updating attachment with $id');
    await attachmentsService.updateAttachmentState(id, state);
  }
}
