import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDbService {
  static Database? _db;

  static Future<Database> getDb() async {
    if (_db != null) return _db!;
    _db = await openDatabase(
      join(await getDatabasesPath(), 'aitalk.db'),
      onCreate: (db, version) async {
        await db.execute('''CREATE TABLE vocab(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          word TEXT,
          meaning TEXT,
          addedAt TEXT
        )''');
        await db.execute('''CREATE TABLE progress(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT,
          score INTEGER,
          streak INTEGER
        )''');
      },
      version: 1,
    );
    return _db!;
  }

  // Vocab CRUD
  static Future<int> addVocab(String word, String meaning) async {
    final db = await getDb();
    return await db.insert('vocab', {
      'word': word,
      'meaning': meaning,
      'addedAt': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getVocab() async {
    final db = await getDb();
    return await db.query('vocab', orderBy: 'addedAt DESC');
  }

  static Future<int> deleteVocab(int id) async {
    final db = await getDb();
    return await db.delete('vocab', where: 'id = ?', whereArgs: [id]);
  }

  // Progress CRUD
  static Future<int> addProgress(int score, int streak) async {
    final db = await getDb();
    return await db.insert('progress', {
      'date': DateTime.now().toIso8601String(),
      'score': score,
      'streak': streak,
    });
  }

  static Future<List<Map<String, dynamic>>> getProgress() async {
    final db = await getDb();
    return await db.query('progress', orderBy: 'date DESC');
  }
}
