import '../data/repositories/note_repository.dart';

Future<int> syncNotes(NoteRepository repo) async {
  final dirtyCount = await repo.countDirty();

  if (dirtyCount == 0) {
    return 0;
  }

  // Simulasi upload ke server
  await Future.delayed(
    const Duration(seconds: 1),
  );

  // Anggap server menjawab 2xx
  await repo.markAllSynced();

  return dirtyCount;
}