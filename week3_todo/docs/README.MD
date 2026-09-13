Bisa. Karena ini Praktikum 3 state loading/error/success, kita bisa buat struktur sederhana seperti ini:

lib/
├── main.dart
├── pages/
│   └── stats_page.dart
└── providers/
    └── stats_provider.dart

test/
└── stats_provider_test.dart

Pastikan Riverpod sudah ada:

flutter pub add flutter_riverpod
flutter pub add --dev flutter_test
1. lib/providers/stats_provider.dart
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

// AsyncNotifier digunakan untuk mengelola state asynchronous.
// State yang dihasilkan berupa AsyncValue<List<String>>,
// sehingga dapat memiliki kondisi loading, error, dan data.
class StatsNotifier extends AsyncNotifier<List<String>> {
  // Fungsi build() dijalankan ketika provider pertama kali digunakan.
  @override
  Future<List<String>> build() async {
    // Simulasi proses mengambil data dari server selama 2 detik.
    await Future.delayed(const Duration(seconds: 2));

    // Membuat angka acak antara 0 sampai 1.
    // Jika hasil kurang dari 0.3, maka dianggap terjadi error.
    final random = Random();

    if (random.nextDouble() < 0.3) {
      throw Exception('Gagal mengambil data statistik');
    }

    // Jika tidak error, kembalikan 3 data statistik.
    return [
      'Total Tugas: 12',
      'Tugas Selesai: 8',
      'Progress: 67%',
    ];
  }

  // Fungsi retry digunakan untuk menjalankan kembali provider.
  void retry() {
    ref.invalidateSelf();
  }
}

// Provider yang digunakan oleh UI.
// Provider ini menghasilkan AsyncValue<List<String>>.
final statsProvider =
    AsyncNotifierProvider<StatsNotifier, List<String>>(
  StatsNotifier.new,
);
2. lib/pages/stats_page.dart
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
3. lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pages/stats_page.dart';

void main() {
  // ProviderScope merupakan root container untuk Riverpod.
  // Semua provider di dalam aplikasi dikelola melalui ProviderScope.
  runApp(
    const ProviderScope(
      child: StatsApp(),
    ),
  );
}

class StatsApp extends StatelessWidget {
  const StatsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Stats Riverpod',

      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),

      // Halaman utama aplikasi.
      home: const StatsPage(),
    );
  }
}
4. Unit Test test/stats_provider_test.dart

Untuk unit test notifier, kita tidak perlu mengetes tampilan StatsPage. Kita fokus memastikan notifier menghasilkan data yang benar.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:stats_riverpod/providers/stats_provider.dart';

void main() {
  test(
    'StatsNotifier berhasil mengambil 3 data statistik',
    () async {
      // Membuat container khusus untuk menjalankan provider
      // tanpa harus menjalankan seluruh aplikasi Flutter.
      final container = ProviderContainer();

      // Memastikan container dibersihkan setelah test selesai.
      addTearDown(container.dispose);

      // Membaca provider dan menunggu proses asynchronous selesai.
      final result = await container.read(statsProvider.future);

      // Memastikan jumlah data yang diterima adalah 3.
      expect(result.length, 3);

      // Memastikan data pertama sesuai.
      expect(result[0], 'Total Tugas: 12');

      // Memastikan data kedua sesuai.
      expect(result[1], 'Tugas Selesai: 8');

      // Memastikan data ketiga sesuai.
      expect(result[2], 'Progress: 67%');
    },
  );
}