import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final darkMode =
        ref.watch(darkModeProvider);

    final forceOffline =
        ref.watch(forceOfflineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),

      body: ListView(
        children: [
          const SizedBox(height: 12),

          // DARK MODE
          darkMode.when(
            loading: () {
              return const ListTile(
                title: Text('Dark Mode'),
                trailing:
                    CircularProgressIndicator(),
              );
            },

            error: (error, stack) {
              return ListTile(
                title: const Text(
                  'Dark Mode',
                ),
                subtitle: Text(
                  'Error: $error',
                ),
              );
            },

            data: (enabled) {
              return SwitchListTile(
                title: const Text(
                  'Dark Mode',
                ),
                subtitle: const Text(
                  'Simpan preferensi dengan SharedPreferences',
                ),
                value: enabled,
                onChanged: (_) {
                  ref
                      .read(
                        darkModeProvider
                            .notifier,
                      )
                      .toggle();
                },
              );
            },
          ),

          const Divider(),

          // FORCE OFFLINE
          SwitchListTile(
            title: const Text(
              'Force Offline',
            ),
            subtitle: const Text(
              'Simulasi tanpa koneksi internet',
            ),
            value: forceOffline,

            onChanged: (value) {
              ref
                  .read(
                    forceOfflineProvider
                        .notifier,
                  )
                  .state = value;

              // Refresh posts agar status
              // offline langsung diterapkan.
              ref.invalidate(postsProvider);
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(
              Icons.info_outline,
            ),
            title: const Text(
              'Mekanisme aplikasi',
            ),
            subtitle: const Text(
              'Notes → SQLite\n'
              'Posts → Cache-first + Dio\n'
              'Settings → SharedPreferences',
            ),
          ),

          const SizedBox(height: 20),

          Padding(
            padding:
                const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Aturan Konflik',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Last-write-wins berdasarkan updated_at.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}