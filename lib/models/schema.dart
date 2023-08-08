import 'package:powersync/powersync.dart';

const schema = Schema(([
  Table('todos', [
    Column.text('list_id'),
    Column.text('created_at'),
    Column.text('completed_at'),
    Column.text('description'),
    Column.integer('completed'),
    Column.text('created_by'),
    Column.text('completed_by'),
  ], indexes: [
    Index('list', [IndexedColumn('list_id')])
  ]),
  Table('lists', [
    Column.text('created_at'),
    Column.text('name'),
    Column.text('owner_id')
  ]),

  // Local-only table to store session credentials.
  // Note: This stores the credentials in plaintext, used for simplicity in the demo.
  // flutter_secure_storage may be a better option for storing sensitive credentials.
  Table.localOnly(
    'credentials',
    [Column.text('data')],
  )
]));
