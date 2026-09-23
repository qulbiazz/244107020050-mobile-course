import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/sync_service.dart';
import '../providers/providers.dart';

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() =>
      _NotesPageState();
}

class _NotesPageState
    extends ConsumerState<NotesPage> {
  final titleController = TextEditingController();
  final bodyController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    bodyController.dispose();
    super.dispose();
  }

  Future<void> addNote() async {
    final title = titleController.text.trim();
    final body = bodyController.text.trim();

    if (title.isEmpty) {
      return;
    }

    await ref
        .read(noteRepositoryProvider)
        .addNote(
          title: title,
          body: body,
        );

    titleController.clear();
    bodyController.clear();

    ref.invalidate(notesProvider);

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Catatan tersimpan secara lokal.',
          ),
        ),
      );
    }
  }

  Future<void> sync() async {
    final offline =
        ref.read(forceOfflineProvider);

    if (offline) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Force Offline aktif. Sync tidak dijalankan.',
          ),
        ),
      );

      return;
    }

    final count = await syncNotes(
      ref.read(noteRepositoryProvider),
    );

    ref.invalidate(notesProvider);

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          count == 0
              ? 'Tidak ada catatan yang perlu disinkronkan.'
              : '$count catatan berhasil disinkronkan.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(notesProvider);

    final forceOffline =
        ref.watch(forceOfflineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Notes'),
        actions: [
          IconButton(
            onPressed: sync,
            icon: const Icon(Icons.sync),
            tooltip: 'Sinkronisasi',
          ),
        ],
      ),

      body: Column(
        children: [
          // STATUS OFFLINE
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: forceOffline
                ? Colors.orange.shade100
                : Colors.green.shade100,
            child: Row(
              children: [
                Icon(
                  forceOffline
                      ? Icons.cloud_off
                      : Icons.cloud_done,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    forceOffline
                        ? 'Force Offline aktif'
                        : 'Mode online',
                  ),
                ),
              ],
            ),
          ),

          // INPUT
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration:
                      const InputDecoration(
                    labelText: 'Judul',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: bodyController,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(
                    labelText: 'Isi catatan',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: addNote,
                    icon: const Icon(Icons.add),
                    label: const Text(
                      'Simpan Catatan',
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // LIST CATATAN
          Expanded(
            child: notesAsync.when(
              loading: () {
                return const Center(
                  child:
                      CircularProgressIndicator(),
                );
              },

              error: (error, stack) {
                return Center(
                  child: Text(
                    'Error: $error',
                  ),
                );
              },

              data: (notes) {
                if (notes.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada catatan.',
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: notes.length,
                  itemBuilder:
                      (context, index) {
                    final note = notes[index];

                    return ListTile(
                      leading: Icon(
                        note.dirty
                            ? Icons.cloud_upload
                            : Icons.cloud_done,
                      ),

                      title: Text(
                        note.title,
                      ),

                      subtitle: Text(
                        note.body.isEmpty
                            ? 'Tidak ada isi'
                            : note.body,
                      ),

                      trailing: note.dirty
                          ? const Chip(
                              label: Text(
                                'DIRTY',
                              ),
                            )
                          : const Chip(
                              label: Text(
                                'SYNCED',
                              ),
                            ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}