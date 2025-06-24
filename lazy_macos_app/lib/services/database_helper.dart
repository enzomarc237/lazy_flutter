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

const String tableTags = 'tags';
const String columnTagName = 'name';

const String tableCaptureTags = 'capture_tags';
const String columnCaptureId = 'capture_id';
const String columnTagId = 'tag_id';


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

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
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
    await _createTagTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createTagTables(db);
    }
  }

  Future<void> _createTagTables(Database db) async {
    await db.execute('''
      CREATE TABLE $tableTags (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnTagName TEXT NOT NULL UNIQUE
      )
    ''');
    await db.execute('''
      CREATE TABLE $tableCaptureTags (
        $columnCaptureId INTEGER,
        $columnTagId INTEGER,
        PRIMARY KEY ($columnCaptureId, $columnTagId),
        FOREIGN KEY ($columnCaptureId) REFERENCES $tableCaptures ($columnId) ON DELETE CASCADE,
        FOREIGN KEY ($columnTagId) REFERENCES $tableTags ($columnId) ON DELETE CASCADE
      )
    ''');
  }

  // Insert a new capture
  Future<int> insertCapture(CapturedContent capture, List<String> tags) async {
    final db = await database;
    return await db.transaction((txn) async {
      final captureId = await txn.insert(tableCaptures, capture.toMap());
      await _handleTags(txn, captureId, tags);
      return captureId;
    });
  }

  // Get all captures, ordered by created_at descending
  Future<List<CapturedContent>> getAllCaptures() async {
    final db = await database;
    final List<Map<String, dynamic>> captureMaps = await db.query(
      tableCaptures,
      orderBy: '$columnCreatedAt DESC',
    );
    
    final List<CapturedContent> captures = [];
    for (final map in captureMaps) {
      final capture = CapturedContent.fromMap(map);
      final tags = await _getTagsForCapture(db, capture.id!);
      captures.add(capture.copyWith(tags: tags));
    }

    return captures;
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
    // Deleting from captures table will cascade to capture_tags
    final count = await db.delete(tableCaptures, where: '$columnId = ?', whereArgs: [id]);
    // Optionally, clean up tags that are no longer associated with any capture
    await _cleanupOrphanedTags(db);
    return count;
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
      final capture = CapturedContent.fromMap(maps.first);
      final tags = await _getTagsForCapture(db, capture.id!);
      return capture.copyWith(tags: tags);
    }
    return null;
  }

  Future<void> _handleTags(
      DatabaseExecutor txn, int captureId, List<String> tags) async {
    // Clear existing tags for this capture
    await txn.delete(tableCaptureTags,
        where: '$columnCaptureId = ?', whereArgs: [captureId]);

    for (final tagName in tags) {
      int? tagId;
      // Check if tag exists
      final existingTags = await txn.query(tableTags,
          where: '$columnTagName = ?', whereArgs: [tagName], limit: 1);

      if (existingTags.isNotEmpty) {
        tagId = existingTags.first[columnId] as int?;
      } else {
        // Insert new tag
        tagId = await txn.insert(tableTags, {columnTagName: tagName});
      }

      if (tagId != null) {
        // Link capture and tag
        await txn.insert(tableCaptureTags,
            {columnCaptureId: captureId, columnTagId: tagId});
      }
    }
  }

  Future<List<String>> _getTagsForCapture(
      DatabaseExecutor db, int captureId) async {
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT T.$columnTagName
      FROM $tableTags T
      INNER JOIN $tableCaptureTags CT ON T.$columnId = CT.$columnTagId
      WHERE CT.$columnCaptureId = ?
    ''', [captureId]);

    return maps.map((map) => map[columnTagName] as String).toList();
  }

  Future<void> _cleanupOrphanedTags(DatabaseExecutor db) async {
    await db.rawDelete('''
      DELETE FROM $tableTags
      WHERE $columnId NOT IN (SELECT DISTINCT $columnTagId FROM $tableCaptureTags)
    ''');
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
