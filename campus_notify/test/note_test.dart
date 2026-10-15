
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';

void main() {
  group('Note title validation', () {
    test('menolak judul kosong', () {
      expect(
        () => Note(
          title: '',
          updatedAt: DateTime(2026, 10, 15),
        ),
        throwsArgumentError,
      );
    });

    test('menolak judul yang hanya berisi spasi', () {
      expect(
        () => Note(
          title: '   ',
          updatedAt: DateTime(2026, 10, 15),
        ),
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
  });
}
