# Refleksi
1. Kapan setState masih cukup, dan kapan state harus naik ke Riverpod?

setState masih cukup digunakan ketika state hanya dibutuhkan oleh satu widget dan sifatnya sederhana atau lokal, misalnya membuka/menutup menu, mengubah tab yang sedang dipilih, atau mengatur nilai sementara pada sebuah form.

2. Apa perbedaan context.go dan context.push, dan kapan masing-masing tepat digunakan?

context.go() digunakan untuk berpindah ke lokasi/rute tertentu dan mengganti konfigurasi halaman yang sedang aktif. Cocok digunakan ketika navigasi bersifat langsung, misalnya dari halaman ToDo menuju halaman Statistik.

3. Bagaimana AsyncValue mencegah bug dibanding tiga boolean terpisah?

AsyncValue membuat status proses asynchronous menjadi lebih terstruktur karena hanya memiliki kondisi utama seperti loading, data/success, dan error.

4. Bagian mana dari hasil AI yang Anda perbaiki, dan mengapa?

Beberapa bagian hasil AI diperbaiki agar sesuai dengan kebutuhan project dan pola Riverpod yang digunakan. Pertama, kode bawaan Counter App pada widget_test.dart dihapus karena tidak sesuai dengan aplikasi ToDo dan diganti dengan test yang memeriksa StatsPage.
Kedua, penggunaan provider disesuaikan agar TodoPage menggunakan todoListProvider, bukan provider statistik. ref.watch() digunakan untuk mengamati state di dalam build(), sedangkan ref.read() digunakan pada callback seperti tambah, toggle, hapus, dan retry.
Ketiga, pengelolaan state ToDo diperbaiki menggunakan pola Notifier<List<Todo>> dan immutable state, sehingga tidak dilakukan mutasi langsung seperti state.add().
Keempat, halaman statistik menggunakan AsyncNotifier dan AsyncValue sehingga kondisi loading, error, dan success semuanya ditangani. Tombol retry juga diperbaiki agar dapat memicu pengambilan data kembali.
Perbaikan tersebut dilakukan karena hasil AI perlu diverifikasi dan disesuaikan, bukan langsung diterima. Tujuannya agar implementasi sesuai dengan struktur project, versi Riverpod yang digunakan, kebutuhan tugas, serta dapat melewati flutter analyze dan flutter test.