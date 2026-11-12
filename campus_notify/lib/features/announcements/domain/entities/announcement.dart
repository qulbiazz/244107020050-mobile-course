class Announcement {
  Announcement({
    required this.id,
    required String title,
    required String content,
    required this.createdAt,
  })  : title = _validateTitle(title),
        content = _validateContent(content);

  final String id;
  final String title;
  final String content;
  final DateTime createdAt;

  static String _validateTitle(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Judul tidak boleh kosong');
    }
    return trimmed;
  }

  static String _validateContent(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Isi pengumuman tidak boleh kosong');
    }
    return trimmed;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Announcement &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          content == other.content;

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ content.hashCode;
}
