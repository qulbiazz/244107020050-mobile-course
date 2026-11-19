import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/notes/data/models/note_repository_impl.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/domain/repositories/note_repository.dart';
import 'package:campus_notify/features/notes/domain/usecases/get_notes.dart';
import 'package:campus_notify/features/notes/presentation/providers/notes_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository({this.notes = const [], this.failure});

  final List<Note> notes;
  final Failure? failure;
  int fetchCount = 0;

  @override
  Future<({List<Note> notes, Failure? failure})> fetchNotes() async {
    fetchCount++;
    return (notes: notes, failure: failure);
  }

  @override
  Future<({Note? note, Failure? failure})> addNote({
    required String title,
    String body = '',
  }) async {
    return (
      note: Note(title: title, body: body, updatedAt: DateTime(2026, 10, 15)),
      failure: null,
    );
  }
}

void main() {
  final sampleNote = Note(
    id: 1,
    title: 'Tugas Pemrograman Mobile',
    body: 'Selesaikan praktikum pengujian.',
    updatedAt: DateTime(2026, 10, 15),
  );

  group('NoteRepository contract via fake', () {
    test('mengembalikan catatan yang tersedia', () async {
      final repository = FakeNoteRepository(notes: [sampleNote]);

      final result = await repository.fetchNotes();

      expect(result.failure, isNull);
      expect(result.notes, [sampleNote]);
    });

    test(
      'mengembalikan failure tanpa catatan saat sumber data gagal',
      () async {
        final repository = FakeNoteRepository(
          failure: const LocalFailure('database tidak tersedia'),
        );

        final result = await repository.fetchNotes();

        expect(result.notes, isEmpty);
        expect(result.failure?.message, 'database tidak tersedia');
      },
    );
  });

  group('GetNotes and notes provider', () {
    test('use case meneruskan hasil repository', () async {
      final repository = FakeNoteRepository(notes: [sampleNote]);

      final result = await GetNotes(repository).call();

      expect(result.notes, [sampleNote]);
      expect(result.failure, isNull);
    });

    test('provider menghasilkan daftar catatan saat sukses', () async {
      final repository = FakeNoteRepository(notes: [sampleNote]);
      final container = ProviderContainer(
        overrides: [noteRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final result = await container.read(notesProvider.future);

      expect(result, [sampleNote]);
      expect(repository.fetchCount, 1);
    });

    test('provider melaporkan failure repository sebagai error', () async {
      final repository = FakeNoteRepository(
        failure: const LocalFailure('gagal membaca catatan'),
      );
      final container = ProviderContainer(
        overrides: [noteRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(notesProvider.future),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('gagal membaca catatan'),
          ),
        ),
      );
    });
  });

  group('NoteRepositoryImpl database failures', () {
    test(
      'fetchNotes mengembalikan failure jika database tidak dapat dibuka',
      () async {
        final repository = NoteRepositoryImpl(
          openDb: () async => throw StateError('database unavailable'),
        );

        final result = await repository.fetchNotes();

        expect(result.notes, isEmpty);
        expect(result.failure, isA<LocalFailure>());
        expect(result.failure!.message, contains('Gagal membaca catatan'));
      },
    );

    test(
      'addNote mengembalikan failure jika database tidak dapat dibuka',
      () async {
        final repository = NoteRepositoryImpl(
          openDb: () async => throw StateError('database unavailable'),
        );

        final result = await repository.addNote(title: 'Catatan baru');

        expect(result.note, isNull);
        expect(result.failure, isA<LocalFailure>());
        expect(result.failure!.message, contains('Gagal menyimpan catatan'));
      },
    );
  });
}
