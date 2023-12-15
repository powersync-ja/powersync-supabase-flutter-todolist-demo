import 'package:powersync/powersync.dart';
import 'package:powersync_flutter_demo/attachment_queue/attachments_queue_table.dart';
import 'package:powersync_flutter_demo/attachment_queue/local_storage_adapter.dart';
import 'package:powersync_flutter_demo/attachment_queue/syncing_service.dart';
import 'package:sqlite_async/sqlite3.dart';

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

  Future<void> deleteAttachment(String id) async =>
      db.execute('DELETE FROM $table WHERE id = ?', [id]);

  Future<Attachment?> getAttachment(String id) async =>
      db.getOptional('SELECT * FROM $table WHERE id = ?', [id]).then((row) {
        if (row == null) {
          return null;
        }
        return Attachment.fromRow(row);
      });

  Future<void> updateAttachmentState(String id, int state) async {
    await db.execute('''
      UPDATE $table
      SET
        state = ?
      WHERE id = ?
    ''', [state, id]);
  }

  Future<void> updateAttachment(Attachment record) async {
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
      ORDER BY timestamp ASC}}
    ''') as Attachment?;
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

  Future<List<String>> getAttachmentIds() async {
    ResultSet results =
        await db.getAll('SELECT id FROM $table WHERE id IS NOT NULL');

    List<String> ids = results.map((row) => row['id'] as String).toList();

    return ids;
  }

  Future<void> clearQueue() async {
    log.info('Clearing attachment queue...');
    await db.execute('DELETE FROM $table');
  }
}
