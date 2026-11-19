import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/domain/repositories/note_repository.dart';
import 'package:campus_notify/features/notes/presentation/pages/notes_page.dart';
import 'package:campus_notify/features/notes/presentation/providers/notes_providers.dart';

class InMemoryNoteRepository implements NoteRepository {
  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async => (
    notes: [
      Note(
        id: 1,
        title: 'Tugas Pemrograman Mobile',
        body: 'Selesaikan pengujian daftar tugas.',
        updatedAt: DateTime(2026, 11, 12, 9),
      ),
    ],
    failure: null,
  );

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async => (note: null, failure: null);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('alur daftar tugas: buka halaman dan tampilkan catatan', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          noteRepositoryProvider.overrideWithValue(InMemoryNoteRepository()),
        ],
        child: const MaterialApp(home: NotesPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Catatan'), findsOneWidget);
    expect(find.text('Tugas Pemrograman Mobile'), findsOneWidget);
    expect(find.text('Selesaikan pengujian daftar tugas.'), findsOneWidget);
  });
}
