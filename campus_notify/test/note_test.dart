import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/data/models/note_model.dart';

void main() {
  group('Note title validation', () {
    test('menolak judul kosong', () {
      expect(
        () => Note(title: '', updatedAt: DateTime(2026, 10, 15)),
        throwsArgumentError,
      );
    });

    test('menolak judul yang hanya berisi spasi', () {
      expect(
        () => Note(title: '   ', updatedAt: DateTime(2026, 10, 15)),
        throwsArgumentError,
      );
    });

    test('menerima judul valid dan menghapus spasi tepi', () {
      final note = Note(
        title: '  Catatan Kuliah  ',
        updatedAt: DateTime(2026, 10, 15),
      );

      expect(note.title, 'Catatan Kuliah');
    });

    test('judul kosong setelah trimming ditolak', () {
      expect(
        () => Note(title: ' \t\n ', updatedAt: DateTime(2026, 10, 15)),
        throwsArgumentError,
      );
    });

    test('body kosong diperbolehkan dan dirty default false', () {
      final note = Note(title: 'Catatan', updatedAt: DateTime(2026, 10, 15));

      expect(note.body, isEmpty);
      expect(note.dirty, isFalse);
    });
  });

  group('NoteModel mapping', () {
    test('round-trip mempertahankan field yang disimpan', () {
      final updatedAt = DateTime(2026, 10, 15, 9, 30);
      final model = NoteModel(
        id: 7,
        title: 'Catatan Kuliah',
        body: 'Materi pemrograman mobile',
        updatedAt: updatedAt,
        dirty: true,
      );

      final restored = NoteModel.fromMap(model.toMap()).toEntity();

      expect(restored.id, 7);
      expect(restored.title, 'Catatan Kuliah');
      expect(restored.body, 'Materi pemrograman mobile');
      expect(restored.updatedAt, updatedAt);
      expect(restored.dirty, isTrue);
    });
  });
}
