import 'package:powersync/powersync.dart';
import 'package:powersync/sqlite3.dart' as sqlite;

const ATTACHMENTS_QUEUE_TABLE = 'attachments_queue';

class Attachment {
  String id;
  String filename;
  String? localUri;
  int? size;
  String? mediaType;
  int? timestamp;
  int state;

  Attachment({
    required this.id,
    required this.filename,
    this.localUri,
    this.size,
    this.mediaType,
    this.timestamp,
    required this.state,
  });

  Attachment copyWith({
    String? id,
    String? filename,
    String? localUri,
    int? size,
    String? mediaType,
    int? timestamp,
    int? state,
  }) {
    return Attachment(
        id: id ?? this.id,
        filename: filename ?? this.filename,
        localUri: localUri ?? this.localUri,
        size: size ?? this.size,
        mediaType: mediaType ?? this.mediaType,
        timestamp: timestamp ?? this.timestamp,
        state: state ?? this.state);
  }

  @override
  String toString() {
    return 'Attachment{id: $id, filename: $filename, localUri: $localUri, size: $size, mediaType: $mediaType, timestamp: $timestamp, state: $state}';
  }

  factory Attachment.fromRow(sqlite.Row row) {
    return Attachment(
        id: row['id'],
        filename: row['filename'],
        localUri: row['local_uri'],
        size: row['size'],
        mediaType: row['media_type'],
        timestamp: row['timestamp'],
        state: row['state']);
  }
}

enum AttachmentState {
  queuedUpload, // Attachment to be uploaded
  queuedDownload, // Attachment to be downloaded
  queuedDelete, // Attachment to be deleted
}

class AttachmentsQueueTable extends Table {
  AttachmentsQueueTable(
      {List<Column> additionalColumns = const [],
      List<Index> indexes = const [],
      String? viewName})
      : super.localOnly(
            ATTACHMENTS_QUEUE_TABLE,
            [
              const Column.text('filename'),
              const Column.text('local_uri'),
              const Column.integer('timestamp'),
              const Column.integer('size'),
              const Column.text('media_type'),
              const Column.integer('state'),
              ...additionalColumns,
            ],
            viewName: viewName,
            indexes: indexes);
}
