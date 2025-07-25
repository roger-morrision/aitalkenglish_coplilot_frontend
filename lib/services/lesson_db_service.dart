import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/lesson.dart';

class LessonDbService {
  static Database? _db;

  static Future<Database> getDb() async {
    if (_db != null) return _db!;
    _db = await openDatabase(
      join(await getDatabasesPath(), 'aitalk.db'),
      onCreate: (db, version) async {
        await db.execute('''CREATE TABLE lesson(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          description TEXT,
          scheduledAt TEXT,
          completed INTEGER
        )''');
        await db.execute('''CREATE TABLE streak(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT,
          count INTEGER
        )''');
        await db.execute('''CREATE TABLE badge(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          description TEXT,
          icon TEXT,
          achieved INTEGER
        )''');
      },
      version: 1,
    );
    return _db!;
  }
  // Streak logic
  static Future<int> updateStreak(DateTime date, int count) async {
    final db = await getDb();
    return await db.insert('streak', {
      'date': date.toIso8601String(),
      'count': count,
    });
  }

  static Future<int> getCurrentStreak() async {
    final db = await getDb();
    final maps = await db.query('streak', orderBy: 'date DESC', limit: 1);
    if (maps.isNotEmpty) {
      return (maps.first['count'] as int?) ?? 0;
    }
    return 0;
  }

  // Badge logic
  static Future<int> addBadge(String name, String description, String icon) async {
    final db = await getDb();
    return await db.insert('badge', {
      'name': name,
      'description': description,
      'icon': icon,
      'achieved': 1,
    });
  }

  static Future<List<Map<String, dynamic>>> getBadges() async {
    final db = await getDb();
    return await db.query('badge');
  }

  static Future<int> addLesson(Lesson lesson) async {
    final db = await getDb();
    return await db.insert('lesson', lesson.toMap());
  }

  static Future<List<Lesson>> getLessons() async {
    final db = await getDb();
    final maps = await db.query('lesson', orderBy: 'scheduledAt ASC');
    return maps.map((m) => Lesson.fromMap(m)).toList();
  }

  static Future<int> completeLesson(int id) async {
    final db = await getDb();
    return await db.update('lesson', {'completed': 1}, where: 'id = ?', whereArgs: [id]);
  }
}
