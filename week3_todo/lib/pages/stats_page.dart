import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/stats_provider.dart';

// ConsumerWidget digunakan agar halaman dapat membaca state dari Riverpod.
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Membaca state dari statsProvider.
    //
    // Hasilnya berupa AsyncValue<List<String>> yang dapat memiliki:
    // - loading
    // - error
    // - data/success
    final stats = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),

      // when() digunakan untuk menangani tiga kemungkinan state.
      body: stats.when(
        // --------------------------------------------------
        // STATE LOADING
        // --------------------------------------------------
        // Ditampilkan selama proses pengambilan data berlangsung.
        loading: () {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },

        // --------------------------------------------------
        // STATE ERROR
        // --------------------------------------------------
        // Ditampilkan apabila proses pengambilan data gagal.
        error: (error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 50,
                ),

                const SizedBox(height: 16),

                // Menampilkan pesan error.
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Tombol untuk mencoba mengambil data kembali.
                FilledButton.icon(
                  onPressed: () {
                    ref
                        .read(statsProvider.notifier)
                        .retry();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba lagi'),
                ),
              ],
            ),
          );
        },

        // --------------------------------------------------
        // STATE SUCCESS
        // --------------------------------------------------
        // Ditampilkan apabila data berhasil diperoleh.
        data: (items) {
          return ListView.builder(
            // Data yang ditampilkan terdiri dari 3 item.
            itemCount: items.length,

            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.analytics),
                title: Text(items[index]),
              );
            },
          );
        },
      ),
    );
  }
}