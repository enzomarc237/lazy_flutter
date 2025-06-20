import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/captured_content.dart';

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
      CREATE TABLE captures (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content TEXT NOT NULL,
        type TEXT NOT NULL,
        summary TEXT,
        source_application_name TEXT,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // Insert a new capture
  Future<int> insertCapture(CapturedContent capture) async {
    final db = await database;
    final map = capture.toMap();

    // Convert enum to string for storage
    map['type'] = capture.type.toString().split('.').last;

    return await db.insert('captures', map);
  }

  // Get all captures, ordered by created_at descending
  Future<List<CapturedContent>> getAllCaptures() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'captures',
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      final map = maps[i];
      return CapturedContent(
        id: map['id'],
        content: map['content'],
        type: map['type'] == 'url' ? ContentType.url : ContentType.text,
        summary: map['summary'],
        timestamp: DateTime.parse(map['created_at']),
      );
    });
  }

  // Update capture summary
  Future<int> updateCaptureSummary(int id, String summary) async {
    final db = await database;
    return await db.update(
      'captures',
      {'summary': summary},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete a capture
  Future<int> deleteCapture(int id) async {
    final db = await database;
    return await db.delete('captures', where: 'id = ?', whereArgs: [id]);
  }

  // Clear all captures (for testing)
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('captures');
  }

  // Get capture by ID
  Future<CapturedContent?> getCaptureById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'captures',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      final map = maps.first;
      return CapturedContent(
        id: map['id'],
        content: map['content'],
        type: map['type'] == 'url' ? ContentType.url : ContentType.text,
        summary: map['summary'],
        timestamp: DateTime.parse(map['created_at']),
      );
    }
    return null;
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
