import 'package:local_notifier/local_notifier.dart'; // Added for local notifications
import '../models/captured_content.dart';
import 'database_helper.dart';

// A service to manage captured content using SQLite
class ContentService {
  // Singleton pattern
  static final ContentService _instance = ContentService._internal();
  factory ContentService() => _instance;
  ContentService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Add a new captured content
  Future<bool> addContent(CapturedContent content) async {
    try {
      await _dbHelper.insertCapture(content, content.tags);
      // debugPrint('Content saved to database: ${jsonEncode(content.toMap())}');
      return true;
    } catch (e) {
      // debugPrint('Error saving content to database: $e');
      return false;
    }
  }

  // Get all captured content
  Future<List<CapturedContent>> getAllContent() async {
    return await _dbHelper.getAllCaptures();
  }

  // Clear all content (for testing)
  Future<void> clearAll() async {
    await _dbHelper.clearAll();
  }

  // Get a single capture by ID
  Future<CapturedContent?> getContentById(int id) async {
    return await _dbHelper.getCaptureById(id);
  }

  // Delete a capture by ID
  Future<bool> deleteContent(int id) async {
    try {
      await _dbHelper.deleteCapture(id);
      return true;
    } catch (e) {
      // debugPrint('Error deleting content: $e');
      return false;
    }
  }

  // Update capture summary
  Future<int> updateCaptureSummary(int id, String summary) async {
    return await _dbHelper.updateCaptureSummary(id, summary);
  }

  Future<void> showNotification(String title, String body) async {
    LocalNotification notification = LocalNotification(
      title: title,
      body: body,
      silent: true,
    );
    notification.show();
  }
}
