import 'dart:convert';
import '../models/captured_content.dart';

// A service to manage captured content
// This is a simple in-memory implementation for now
// In Phase 3, this will be replaced with actual database storage
class ContentService {
  // Singleton pattern
  static final ContentService _instance = ContentService._internal();
  factory ContentService() => _instance;
  ContentService._internal();

  // In-memory storage - would be replaced with actual database in Phase 3
  final List<CapturedContent> _capturedItems = [];

  // Add a new captured content
  Future<bool> addContent(CapturedContent content) async {
    try {
      _capturedItems.add(content);
      // In development, print to console
      print('Content saved: ${jsonEncode(content.toMap())}');
      return true;
    } catch (e) {
      print('Error saving content: $e');
      return false;
    }
  }

  // Get all captured content
  List<CapturedContent> getAllContent() {
    return List.unmodifiable(_capturedItems);
  }

  // Clear all content (for testing)
  Future<void> clearAll() async {
    _capturedItems.clear();
  }
}
