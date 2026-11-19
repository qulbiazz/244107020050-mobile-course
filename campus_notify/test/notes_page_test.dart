import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/domain/repositories/note_repository.dart';
import 'package:campus_notify/features/notes/presentation/pages/notes_page.dart';
import 'package:campus_notify/features/notes/presentation/providers/notes_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository({this.notes = const [], this.failure});

  List<Note> notes;
  Failure? failure;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async => (
    notes: notes,
    failure: failure,
  );

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async => (
    note: Note(title: title, body: body, updatedAt: DateTime(2026, 10, 15)),
    failure: null,
  );
}

Widget buildNotesPage(FakeNoteRepository repository) {
  return ProviderScope(
    overrides: [noteRepositoryProvider.overrideWithValue(repository)],
    child: const MaterialApp(home: NotesPage()),
  );
}

void main() {
  testWidgets('menampilkan empty state jika belum ada catatan', (tester) async {
    await tester.pumpWidget(buildNotesPage(FakeNoteRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Catatan'), findsOneWidget);
    expect(find.text('Belum ada catatan.'), findsOneWidget);
  });

  testWidgets('menampilkan catatan yang dimuat dari repository', (
    tester,
  ) async {
    final repository = FakeNoteRepository(
      notes: [
        Note(
          id: 1,
          title: 'Tugas Pemrograman Mobile',
          body: 'Selesaikan praktikum pengujian.',
          updatedAt: DateTime(2026, 10, 15),
        ),
      ],
    );

    await tester.pumpWidget(buildNotesPage(repository));
    await tester.pumpAndSettle();

    expect(find.text('Tugas Pemrograman Mobile'), findsOneWidget);
    expect(find.text('Selesaikan praktikum pengujian.'), findsOneWidget);
  });

  testWidgets('menampilkan error dan mencoba memuat ulang setelah retry', (
    tester,
  ) async {
    final repository = FakeNoteRepository(
      failure: const LocalFailure('database tidak tersedia'),
    );

    await tester.pumpWidget(buildNotesPage(repository));
    await tester.pumpAndSettle();

    expect(find.textContaining('Gagal memuat catatan:'), findsOneWidget);

    repository
      ..failure = null
      ..notes = [
        Note(
          id: 2,
          title: 'Catatan berhasil dimuat',
          updatedAt: DateTime(2026, 10, 16),
        ),
      ];

    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();

    expect(find.text('Catatan berhasil dimuat'), findsOneWidget);
  });
}
