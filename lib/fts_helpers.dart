import 'package:powersync_flutter_demo/powersync.dart';

class FtsHelpers {
  static String _createSearchTermWithOptions(String searchTerm) {
    // adding * to the end of the search term will match any word that starts with the search term
    // e.g. searching bl will match blue, black, etc.
    // consult FTS5 Full-text Query Syntax documentation for more options
    String searchTermWithOptions = '$searchTerm*';
    return searchTermWithOptions;
  }

  /// Search the FTS table for the given searchTerm
  static Future<List> search(String searchTerm, String tableName) async {
    String searchTermWithOptions = _createSearchTermWithOptions(searchTerm);
    return await db.execute(
        'SELECT * FROM fts_$tableName WHERE fts_$tableName MATCH ? ORDER BY rank',
        [searchTermWithOptions]);
  }
}
