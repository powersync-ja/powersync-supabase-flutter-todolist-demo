import 'package:powersync/powersync.dart';
import 'package:powersync_flutter_demo/attachment_queue/attachments_queue_table.dart';
import 'package:powersync_flutter_demo/attachment_queue/local_storage_adapter.dart';

class AttachmentsService {
  final PowerSyncDatabase db;
  final AbstractLocalStorageAdapter localStorage;
  final String attachmentDirectoryName;

  AttachmentsService(this.db, this.localStorage, this.attachmentDirectoryName);

  get table {
    return ATTACHMENTS_QUEUE_TABLE;
  }

  /// Returns the local file path for the given filename, used to store in the database.
  /// Example: filename: "attachment-1.jpg" returns "attachments/attachment-1.jpg"
  String getLocalFilePathSuffix(String filename) {
    return '$attachmentDirectoryName/$filename';
  }

  /// Returns the directory where attachments are stored on the device, used to make dir
  /// Example: "/var/mobile/Containers/Data/Application/.../Library/attachments/"
  Future<String> getStorageDirectory() async {
    String userStorageDirectory = await localStorage.getUserStorageDirectory();
    return '$userStorageDirectory/$attachmentDirectoryName';
  }

  /// Return users storage directory with the attachmentPath use to load the file.
  /// Example: filePath: "attachments/attachment-1.jpg" returns "/var/mobile/Containers/Data/Application/.../Library/attachments/attachment-1.jpg"
  Future<String> getLocalUri(String filePath) async {
    String storageDirectory = await getStorageDirectory();
    return '$storageDirectory/$filePath';
  }

  Future<void> deleteRecord(String filename) async =>
      await db.execute('DELETE FROM $table WHERE filename = ?', [filename]);

  Future<Attachment?> getRecord(String id) async =>
      await (db.getOptional('SELECT * FROM $table WHERE id = ?', [id])
          as Attachment?);

  Future<void> updateRecord(Attachment record) async {
    int timestamp = DateTime.now().millisecondsSinceEpoch;

    await db.execute('''
      UPDATE $table
      SET
        timestamp = ?,
        filename = ?,
        local_uri = ?,
        size = ?,
        media_type = ?,
        state = ?
      WHERE id = ?
    ''', [
      timestamp,
      record.filename,
      record.localUri,
      record.size,
      record.mediaType,
      record.state,
      record.id
    ]);
  }

  Future<Attachment?> getNextUploadRecord() async {
    return db.getOptional('''
      SELECT * FROM $table
      WHERE local_uri IS NOT NULL
      AND (state = ${AttachmentState.queuedUpload.index}
      OR state = ${AttachmentState.queuedSync.index})
      ORDER BY timestamp ASC}}
    ''') as Attachment?;
  }

  Future<List<String>> getIdsToDownload() async {
    List<Attachment> records = await db.getAll('''
      SELECT id FROM $table
      WHERE state = ${AttachmentState.queuedDownload.index}
      OR state = ${AttachmentState.queuedSync.index}
      ORDER BY timestamp ASC
    ''') as List<Attachment>;

    return records.map((record) => record.id).toList();
  }

  Future<Attachment> saveRecord(Attachment record) async {
    Attachment updatedRecord = record.copyWith(
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    await db.execute('''
      INSERT OR REPLACE INTO $table
      (id, timestamp, filename, local_uri, media_type, size, state) VALUES (?, ?, ?, ?, ?, ?, ?)
    ''', [
      updatedRecord.id,
      updatedRecord.timestamp,
      updatedRecord.filename,
      updatedRecord.localUri,
      updatedRecord.mediaType,
      updatedRecord.size,
      updatedRecord.state
    ]);

    return updatedRecord;
  }

  Future<List<Attachment>> getAttachmentsForDeletion(int limit) async {
    List<Attachment> records = await db.getAll('''
      SELECT * FROM $table
      WHERE state = ${AttachmentState.synced.index} OR state = ${AttachmentState.archived.index}
      ORDER BY timestamp DESC
      LIMIT $limit
    ''') as List<Attachment>;

    return records;
  }
}
