import '../models/schema.dart';
import 'package:sqlite_async/sqlite_async.dart';

final migrations = SqliteMigrations();

SqliteMigration createFtsMigration(
    int migrationIndex, String tableName, List<String> columns) {
  String internalName =
      schema.tables.firstWhere((table) => table.name == tableName).internalName;
  String stringColumns = columns.join(', ');

  return SqliteMigration(migrationIndex, (tx) async {
    // Add FTS table
    await tx.execute('''
      CREATE VIRTUAL TABLE IF NOT EXISTS fts_$tableName
      USING fts5(id UNINDEXED, $stringColumns);
    ''');
    // Copy over records already in table
    await tx.execute('''
      INSERT INTO fts_$tableName(id, $stringColumns)
      SELECT id, ${_generateJsonExtractsForColumns('data', columns)} FROM $internalName;
    ''');
    // Add INSERT, UPDATE and DELETE and triggers to keep fts table in sync with table
    await tx.execute('''
      CREATE TRIGGER IF NOT EXISTS fts_insert_trigger_$tableName  AFTER INSERT ON $internalName
      WHEN NEW.id NOT IN (SELECT id FROM fts_$tableName)
      BEGIN
          INSERT INTO fts_$tableName(id, $stringColumns)
          VALUES (
              NEW.id,
              ${_generateJsonExtractsForColumns('NEW.data', columns)}
          );
      END;
    ''');
    await tx.execute('''
      CREATE TRIGGER IF NOT EXISTS fts_update_trigger_$tableName AFTER UPDATE ON $internalName BEGIN
        UPDATE fts_$tableName
        SET ${_generateJsonExtractsForSetOperation('NEW.data', columns)}
        WHERE id = NEW.id;
      END;
    ''');
    await tx.execute('''
      CREATE TRIGGER IF NOT EXISTS fts_delete_trigger_$tableName  AFTER DELETE ON $internalName BEGIN
        DELETE FROM fts_$tableName WHERE id = json_extract(OLD.data, '\$.id');
      END;
    ''');
  });
}

String _generateJsonExtractsForColumns(
    String jsonColumnName, List<String> columns) {
  String data = '';
  for (var i = 0; i < columns.length; i++) {
    data += 'json_extract($jsonColumnName, \'\$.${columns[i]}\')';
    if (columns[i] != columns.last) {
      data += ', ';
    }
  }

  return data;
}

String _generateJsonExtractsForSetOperation(
    String jsonColumnName, List<String> columns) {
  String data = '';

  for (var i = 0; i < columns.length; i++) {
    data +=
        '${columns[i]} = json_extract($jsonColumnName, \'\$.${columns[i]}\')';
    if (columns[i] != columns.last) {
      data += ', ';
    }
  }

  return data;
}
