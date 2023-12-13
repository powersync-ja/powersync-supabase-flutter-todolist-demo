import 'dart:convert';
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

  Future<bool> uploadAttachment(Attachment record) async {
    if (record.localUri == null) {
      throw Exception('No localUri for record $record');
    }

    bool fileExists = await localStorage.fileExists(record.localUri!);
    if (fileExists == false) {
      log.warning('File for ${record.id} does not exist, skipping upload');
      await attachmentsService.updateRecord(
          record.copyWith(state: AttachmentState.queuedUpload.index));
      return true;
    }

    try {
      Uint8List fileBuffer = await localStorage.readFile(record.localUri!,
          mediaType: record.mediaType!);

      await remoteStorage.uploadFile(
          record.filename, File.fromRawPath(fileBuffer),
          mediaType: record.mediaType!);
      // Mark as uploaded
      await attachmentsService
          .updateRecord(record.copyWith(state: AttachmentState.synced.index));
      log.info('Uploaded attachment "${record.id}" to Cloud Storage');
      return true;
    } catch (e) {
      if (e == 'Duplicate') {
        log.warning('File already uploaded, marking ${record.id} as synced');
        await attachmentsService
            .updateRecord(record.copyWith(state: AttachmentState.synced.index));
        return false;
      }
      // log.severe(
      //     'UploadAttachment error for record ${JSON.stringify(record, null, 2)}');
      return false;
    }
  }

  Future<bool> downloadAttachment(Attachment attachment) async {
    attachment.localUri ??=
        await attachmentsService.getLocalUri(attachment.filename);

    if (await localStorage.fileExists(attachment.localUri!)) {
      log.warning(
          'Local file already downloaded, marking "${attachment.id}" as synced');
      await attachmentsService.updateRecord(
          attachment.copyWith(state: AttachmentState.synced.index));
      return true;
    }

    try {
      dynamic fileBlob = await remoteStorage.downloadFile(attachment.filename);
      final bytes = await fileBlob.readAsBytes();
      final base64Data = base64Encode(bytes);
      // Ensure directory exists
      await localStorage
          .makeDir(attachment.localUri!.replaceAll(attachment.filename, ''));

      await localStorage.writeFile(
        attachment.localUri!,
        base64Data,
      );

      await attachmentsService.updateRecord(attachment.copyWith(
          mediaType: fileBlob.type, state: AttachmentState.synced.index));
      log.info('Downloaded attachment "${attachment.id}"');
      return true;
    } catch (e) {
      // log.severe(
      //     'Download attachment error for record ${JSON.stringify(record, null, 2)}',
      //     e);
      return false;
    }
  }

  Future<void> deleteAttachment(Attachment record) async {
    String uri = record.localUri ??
        await attachmentsService.getLocalUri(record.filename);

    await attachmentsService.deleteRecord(record.filename);

    try {
      await remoteStorage.deleteFile(record.filename);
      await localStorage.deleteFile(uri);
    } catch (e) {
      log.severe(e);
    }
  }

  Stream<void> watchDownloads() {
    return db.watch('''
      SELECT id FROM $table
      WHERE state = ${AttachmentState.queuedDownload.index}
      OR state = ${AttachmentState.queuedSync.index}}
    ''').map((result) {
      return result
          .map((row) => Attachment.fromRow(row))
          .forEach((Attachment attachment) async {
        await downloadAttachment(attachment);
      });
    });
  }

  Stream<void> watchUploads() {
    log.info('Watching uploads...');
    return db.watch('''
      SELECT id FROM $table
      WHERE local_uri IS NOT NULL
      AND state = ${AttachmentState.queuedUpload.index}
      OR state = ${AttachmentState.queuedSync.index}}
    ''').map((result) {
      log.info('This is happening');
      return result
          .map((row) => Attachment.fromRow(row))
          .forEach((Attachment attachment) async {
        await uploadAttachment(attachment);
      });
    });
  }

  Future<void> cleanUpRecords(int limit) async {
    List<Attachment> attachments =
        await attachmentsService.getAttachmentsForDeletion(limit);

    if (attachments.isEmpty) {
      return;
    }

    log.info('Deleting ${attachments.length} attachments from cache...');
    await db.writeTransaction((tx) async => {
          for (Attachment record in attachments)
            {
              await Future.wait([
                attachmentsService.deleteRecord(record.id),
                deleteAttachment(record),
              ])
            }
        });
  }

  // handleInitialIds(List<String> ids) async {
  //     String commaSeparatedIds = ids.join(',');

  //     List<Attachment> attachmentsInDatabase = await db.getAll(
  //             'SELECT * FROM $table WHERE state < ${AttachmentState.archived}')
  //         as List<Attachment>;

  //     for (var id in ids) {
  //       AttachmentRecord? record = attachmentsInDatabase.firstWhere(
  //         (attachment) => attachment.id == id,
  //         orElse: () => null!,
  //       );

  //       if (record == null) {
  //         record = await createNewRecord(id);
  //         await this.saveToQueue(record)
  //       }

  // //1. ID is not in the database
  // if (record == null) {
  //   var newRecord = await this
  //       .newAttachmentRecord(id: id, state: AttachmentState.QUEUED_SYNC);
  //   print('Attachment ($id) not found in database, creating new record');
  //   await this.saveToQueue(newRecord);
  // } else if (record.localUri == null ||
  //     !(await this.storage.fileExists(record.localUri))) {
  //   // 2. Attachment in database but no local file, mark as queued download
  //   print(
  //       'Attachment ($id) found in database but no local file, marking as queued download');
  //   await this
  //       .update(record.copyWith(state: AttachmentState.QUEUED_DOWNLOAD));
  // }

  //   for (const id of ids) {
  //       const record = attachmentsInDatabase.find((r) => r.id == id);
  //       // 1. ID is not in the database
  //       if (!record) {
  //           const newRecord = await this.newAttachmentRecord({
  //               id: id,
  //               state: AttachmentState.QUEUED_SYNC
  //           });
  //           console.debug(`Attachment (${id}) not found in database, creating new record`);
  //           await this.saveToQueue(newRecord);
  //       } else if (record.localUri == null || !(await this.storage.fileExists(record.localUri))) {
  //           // 2. Attachment in database but no local file, mark as queued download
  //           console.debug(`Attachment (${id}) found in database but no local file, marking as queued download`);
  //           await this.update({
  //               ...record,
  //               state: AttachmentState.QUEUED_DOWNLOAD
  //           });
  //       }
  //   }

  //   // 3. Attachment in database and not in AttachmentIds, mark as archived
  //   await powersync.execute(
  //       `UPDATE ${this.table} SET state = ${AttachmentState.ARCHIVED} WHERE state < ${AttachmentState.ARCHIVED
  //       } AND id NOT IN (${ids.map((id) => `'${id}'`).join(',')})`
  //   );}}
}
