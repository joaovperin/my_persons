import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;

class DbUtils {
  static Future<sql.Database> database() async {
    final dbPath = await sql.getDatabasesPath();
    return sql.openDatabase(
      path.join(dbPath, 'banco.db'),
      version: 1,
      // Função chamada na atualização do banco
      onUpgrade: (db, oldVersion, newVersion) {},
      // Função chamada na criação do banco
      onCreate: (db, version) {
        return db.execute('''
            CREATE TABLE [Person] (
                id INTEGER PRIMARY KEY,
                name TEXT,
                email TEXT,
                phone TEXT,
                photo TEXT,
                address1 TEXT,
                address2 TEXT
            )''');
      },
    );
  }

  /// Realiza uma inserção no banco de dados
  static Future<int> insert(String table, Map<String, Object> data) async {
    final db = await DbUtils.database();
    return await db.insert(table, data);
  }

  /// Realiza uma busca no banco de dados
  static Future<List<Map<String, dynamic>>> query(String table,
      {String where, List<dynamic> args}) async {
    final db = await DbUtils.database();
    return db.query(table, where: where, whereArgs: args);
  }

  /// Deleta todos os registros do banco de dados
  static Future<void> delete(String table,
      {String where, List<dynamic> args}) async {
    final db = await DbUtils.database();
    return db.delete(table, where: where, whereArgs: args);
  }
}
