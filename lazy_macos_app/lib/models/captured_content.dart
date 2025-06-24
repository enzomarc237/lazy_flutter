import '../services/database_helper.dart';

enum ContentType { text, url }

class CapturedContent {
  final int? id;
  final String content;
  final ContentType type;
  final DateTime timestamp;
  final String? summary;

  CapturedContent({
    this.id,
    required this.content,
    required this.type,
    DateTime? timestamp,
    this.summary,
  }) : timestamp = timestamp ?? DateTime.now();

  // Factory method to create content from string
  factory CapturedContent.fromString(String content) {
    final bool isUrl = _isUrl(content);
    return CapturedContent(
      content: content,
      type: isUrl ? ContentType.url : ContentType.text,
    );
  }

  // Helper method to check if content is a URL
  static bool _isUrl(String text) {
    // A more robust URL detection regex
    final urlPattern = RegExp(
        r'^(https?:\/\/)?' // protocol
        r'((([a-z\d]([a-z\d-]*[a-z\d])*)\.)+[a-z]{2,}|' // domain name
        r'((\d{1,3}\.){3}\d{1,3}))' // OR ip (v4) address
        r'(\:\d+)?(\/[-a-z\d%_.~+]*)*' // port and path
        r'(\?[;&a-z\d%_.~+=-]*)?' // query string
        r'(\#[-a-z\d_]*)?$', // fragment locator
        caseSensitive: false);
    return urlPattern.hasMatch(text);
  }

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      columnId: id,
      columnContent: content,
      columnType: type.toString().split('.').last,
      columnSummary: summary,
      columnCreatedAt: timestamp.toIso8601String(),
    };
  }

  // Create from map
  factory CapturedContent.fromMap(Map<String, dynamic> map) {
    return CapturedContent(
      id: map[columnId],
      content: map[columnContent],
      type: map[columnType] == 'url' ? ContentType.url : ContentType.text,
      summary: map[columnSummary],
      timestamp: DateTime.parse(map[columnCreatedAt]),
    );
  }

  CapturedContent copyWith({
    int? id,
    String? content,
    ContentType? type,
    DateTime? timestamp,
    String? summary,
  }) {
    return CapturedContent(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      summary: summary ?? this.summary,
    );
  }
}
