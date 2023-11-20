import 'package:powersync_flutter_demo/powersync.dart';

class FtsHelpers {
  static String _createSearchTermWithOptions(String searchTerm) {
    String searchTermWithOptions = '$searchTerm*';
    return searchTermWithOptions;
  }

  static Future<List> search(String searchTerm, String tableName) async {
    String searchTermWithOptions = _createSearchTermWithOptions(searchTerm);
    return await db.execute(
        'SELECT * FROM fts_$tableName WHERE fts_$tableName MATCH ? ORDER BY rank',
        [searchTermWithOptions]);
  }
}
