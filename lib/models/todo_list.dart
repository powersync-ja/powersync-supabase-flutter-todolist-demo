import 'package:powersync/sqlite3.dart' as sqlite;

import './todo_item.dart';
import '../powersync.dart';

class TodoList {
  final String id;
  final String name;

  TodoList({required this.id, required this.name});

  factory TodoList.fromRow(sqlite.Row row) {
    return TodoList(id: row['id'], name: row['name']);
  }

  Stream<List<TodoItem>> watchItems() {
    return db.watch(
        'SELECT * FROM todos WHERE list_id = ? ORDER BY completed ASC, created_at DESC',
        parameters: [id]).map((event) {
      return event.map(TodoItem.fromRow).toList(growable: false);
    });
  }

  static Stream<List<TodoList>> watchLists() {
    return db.watch('SELECT * FROM lists ORDER BY created_at').map((results) {
      return results.map(TodoList.fromRow).toList(growable: false);
    });
  }

  static Future<TodoList> create(String name) async {
    final results = await db.execute('''INSERT INTO
           lists(id, created_at, name, owner_id)
           VALUES(uuid(), datetime(), ?, ?)
           RETURNING *''', [name, getUserId()]);
    return TodoList.fromRow(results.first);
  }

  Future<void> delete() async {
    await db.execute('DELETE FROM lists WHERE id = ?', [id]);
  }

  Future<TodoItem> add(String description) async {
    final results = await db.execute('''INSERT INTO
          todos(id, created_at, completed, list_id, description, created_by)
          VALUES(uuid(), datetime(), FALSE, ?, ?, ?)
          RETURNING *''', [id, description, getUserId()]);
    return TodoItem.fromRow(results.first);
  }
}
