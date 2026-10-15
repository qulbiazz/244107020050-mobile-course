
class Note {
  Note({
    this.id,
    required String title,
    this.body = '',
    required this.updatedAt,
    this.dirty = false,
  }) : title = _validateTitle(title);

  final int? id;
  final String title;
  final String body;
  final DateTime updatedAt;
  final bool dirty;

  static String _validateTitle(String title) {
    if (title.trim().isEmpty) {
      throw ArgumentError('Judul tidak boleh kosong');
    }

    return title.trim();
  }
}
