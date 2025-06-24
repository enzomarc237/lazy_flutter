import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/captured_content.dart';

/// Constants for database table and column names.
/// Using constants helps avoid typos and makes renaming columns easier.
const String tableCaptures = 'captures';
const String columnId = 'id';
const String columnContent = 'content';
const String columnType = 'type';
const String columnSummary = 'summary';
const String columnCreatedAt = 'created_at';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'lazy_app.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableCaptures (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnContent TEXT NOT NULL,
        $columnType TEXT NOT NULL,
        $columnSummary TEXT,
        $columnCreatedAt TEXT NOT NULL
      )
    ''');
  }

  // Insert a new capture
  Future<int> insertCapture(CapturedContent capture) async {
    final db = await database;
    return await db.insert(tableCaptures, capture.toMap());
  }

  // Get all captures, ordered by created_at descending
  Future<List<CapturedContent>> getAllCaptures() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableCaptures,
      orderBy: '$columnCreatedAt DESC',
    );

    return List.generate(maps.length, (i) => CapturedContent.fromMap(maps[i]));
  }

  // Update capture summary
  Future<int> updateCaptureSummary(int id, String summary) async {
    final db = await database;
    return await db.update(
      tableCaptures,
      {columnSummary: summary},
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // Delete a capture
  Future<int> deleteCapture(int id) async {
    final db = await database;
    return await db.delete(tableCaptures, where: '$columnId = ?', whereArgs: [id]);
  }

  // Clear all captures (for testing)
  Future<void> clearAll() async {
    final db = await database;
    await db.delete(tableCaptures);
  }

  // Get capture by ID
  Future<CapturedContent?> getCaptureById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableCaptures,
      where: '$columnId = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return CapturedContent.fromMap(maps.first);
    }
    return null;
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
