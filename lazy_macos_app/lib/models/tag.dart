/// Data model for a tag.
class Tag {
  final int? id;
  final String name;

  Tag({this.id, required this.name});

  /// Converts a Tag instance to a map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  /// Creates a Tag instance from a map.
  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'],
      name: map['name'],
    );
  }
}