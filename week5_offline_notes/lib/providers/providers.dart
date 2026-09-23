import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/local/note.dart';
import '../data/local/post.dart';
import '../data/prefs.dart';
import '../data/repositories/note_repository.dart';
import '../data/repositories/post_repository.dart';

// ============================================================
// REPOSITORY
// ============================================================

final prefsRepositoryProvider =
    Provider<PrefsRepository>((ref) {
  return PrefsRepository();
});

final noteRepositoryProvider =
    Provider<NoteRepository>((ref) {
  return NoteRepository();
});

final postRepositoryProvider =
    Provider<PostRepository>((ref) {
  return PostRepository();
});

// ============================================================
// DARK MODE
// ============================================================

final darkModeProvider =
    AsyncNotifierProvider<DarkModeNotifier, bool>(
  DarkModeNotifier.new,
);

class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() {
    return ref
        .watch(prefsRepositoryProvider)
        .getDarkMode();
  }

  Future<void> toggle() async {
    final current = state.value ?? false;
    final next = !current;

    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await ref
          .read(prefsRepositoryProvider)
          .setDarkMode(next);

      return next;
    });
  }
}

// ============================================================
// FORCE OFFLINE
// ============================================================

final forceOfflineProvider =
    StateProvider<bool>((ref) => false);

// ============================================================
// NOTES
// ============================================================

final notesProvider =
    FutureProvider<List<Note>>((ref) async {
  final repository =
      ref.read(noteRepositoryProvider);

  return repository.fetchNotes();
});

// ============================================================
// POSTS CACHE-FIRST
// ============================================================

final postsProvider =
    FutureProvider<List<Post>>((ref) async {
  final repository =
      ref.read(postRepositoryProvider);

  final forceOffline =
      ref.watch(forceOfflineProvider);

  return repository.loadPostsCacheFirst(
    forceOffline: forceOffline,
    onRefreshComplete: () {
      ref.invalidateSelf();
    },
  );
});