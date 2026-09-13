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