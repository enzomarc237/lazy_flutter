enum ContentType { text, url }

class CapturedContent {
  final int? id;
  final String content;
  final ContentType type;
  final DateTime timestamp;
  String? summary;

  CapturedContent({
    this.id,
    required this.content,
    required this.type,
    DateTime? timestamp,
    this.summary,
  }) : timestamp = timestamp ?? DateTime.now();

  // Factory method to create content from string
  factory CapturedContent.fromString(String content) {
    // Simple URL detection - can be enhanced with better regex
    final bool isUrl = _isUrl(content);
    return CapturedContent(
      content: content,
      type: isUrl ? ContentType.url : ContentType.text,
    );
  }

  // Helper method to check if content is a URL
  static bool _isUrl(String text) {
    // Basic URL detection - can be made more sophisticated
    final urlPattern = RegExp(
      r'^(https?:\/\/)?' + // protocol
          r'([www\.])?' + // www. optional
          r'([a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)+)' + // domain
          r'(\.[a-zA-Z]{2,})' + // TLD
          r'(\/[^\s]*)?$', // path
    );
    return urlPattern.hasMatch(text);
  }

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'type': type.toString().split('.').last,
      'summary': summary,
      'created_at': timestamp.toIso8601String(),
    };
  }

  // Create from map
  factory CapturedContent.fromMap(Map<String, dynamic> map) {
    return CapturedContent(
      id: map['id'],
      content: map['content'],
      type: map['type'] == 'url' ? ContentType.url : ContentType.text,
      summary: map['summary'],
      timestamp: DateTime.parse(map['created_at']),
    );
  }
}
