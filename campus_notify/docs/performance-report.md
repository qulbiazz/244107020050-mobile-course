# Laporan Performa — Campus Notify

## Lingkungan dan skenario

- Flutter 3.29.0 stable, Dart 3.7.0, DevTools 2.42.2
- Android 15 (API 35), emulator x64; aplikasi dijalankan dalam profile mode
- Skenario: daftar pengumuman sintetis, scroll, buka detail, kembali, lalu
  gesture tarik. Daftar bersifat lokal dan belum memiliki aksi pull-to-refresh.
- Frame timing diambil dengan `adb shell dumpsys gfxinfo`; pengukuran dilakukan
  pada interval interaksi pendek dan dipengaruhi emulator serta input.

## Metrik baseline dan sesudah optimasi

| Metrik | Baseline | Sesudah | Catatan |
|---|---:|---:|---|
| DevTools FPS rata-rata | 56 FPS | 52 FPS | FPS sesi, mencakup aktivitas di luar satu interaksi terisolasi. |
| Sampel frame Android | 15 | 16 | Sampel sangat pendek. |
| Janky frames | 6 (40%) | 7 (43.75%) | Proporsi jank tidak membaik. |
| Frame time P50 | 48 ms | 46 ms | Sedikit lebih rendah, tetapi jumlah sampel tidak cukup untuk mengaitkan perubahan dengan optimasi. |
| Frame time P90 | 81 ms | 73 ms | Sama: hasil eksploratif. |
| Frame time P95 / P99 | 93 / 93 ms | 77 / 77 ms | Tidak cukup untuk menyatakan peningkatan konsisten. |
| Missed VSync | 2 | 2 | Tidak berubah. |
| Memori proses | PSS 155,249 KB; RSS 304,464 KB | PSS 144,159 → 144,546 KB; RSS 323,940 → 324,596 KB setelah 5 navigasi detail-kembali | Snapshot berasal dari sesi/data berbeda; bukan perbandingan before/after yang setara dan bukan heap snapshot Dart. |

**Kesimpulan metrik:** belum ada bukti bahwa frame pacing membaik. FPS sesi
turun dan proporsi jank naik; perubahan percentile frame saja tidak cukup
menjadi bukti. Angka memori setelah navigasi hanya menunjukkan kenaikan kecil
antar dua snapshot dan tidak dapat membuktikan ada atau tidaknya memory leak.

## Temuan profiling

1. Sebelum perubahan, satu `_AnnouncementList` mengamati daftar mentah, query,
   dan hasil filter; perubahan query berpotensi membangun ulang kolom dan
   kontrol pencarian sekaligus hasil.
2. Kartu daftar bersifat stateless sehingga tidak memerlukan automatic
   keep-alive ketika keluar dari viewport. Pencarian memindai seluruh daftar
   setiap query; ini bersifat O(n), tetapi dampak pada dataset kecil belum
   terbukti signifikan.
3. Daftar sudah menggunakan `ListView.separated` yang lazy. Tidak ada gambar
   jaringan atau request HTTP di alur daftar ini. Tidak ditemukan bukti untuk
   menyebut image decode, request berulang, atau kebocoran memori sebagai
   masalah.
4. DevTools merekam Performance frame chart, tetapi call tree/Flame Chart yang
   dapat diverifikasi tidak tersedia di sesi ini. Karena itu laporan tidak
   menebak top function atau jumlah rebuild.

Screenshot yang tersedia adalah **Performance frame chart**, bukan Flame Chart:

- Baseline: [`screenshots/before-profile.png`](../screenshots/before-profile.png)
- Sesudah optimasi: [`screenshots/after-profile.png`](../screenshots/after-profile.png)
- UI daftar sesudah optimasi:
  [`screenshots/after-profile-run.png`](../screenshots/after-profile-run.png)
- Memory chart sebelum dan sesudah siklus navigasi:
  [`screenshots/memory-before-navigation.png`](../screenshots/memory-before-navigation.png),
  [`screenshots/memory-after-navigation.png`](../screenshots/memory-after-navigation.png)

## Optimasi dan alasan

Perubahan dilakukan pada `lib/pages/home_page.dart`:

- Memisahkan Consumer daftar dari widget shell yang stateless agar langganan
  daftar tidak membangun ulang seluruh kolom pencarian.
- Menggunakan Riverpod `select` untuk status empty-state, supaya perubahan
  query/daftar yang tidak mengubah boolean tersebut tidak memicu rebuild
  empty-state.
- Menempatkan field pencarian dalam `RepaintBoundary` untuk mengisolasi repaint
  kontrol dari hasil.
- Menonaktifkan automatic keep-alives untuk item stateless; lazy
  `ListView.separated` yang telah ada tetap dipertahankan.

Pilihan ini mengurangi pekerjaan UI yang berpotensi tidak perlu tanpa
menambahkan dependency atau mengubah perilaku pencarian. Hasil pengukuran belum
menunjukkan peningkatan frame yang dapat diandalkan.

## Verifikasi

- `flutter analyze` — lulus, `No issues found`.
- `flutter test` — lulus, 30 test.
- `git diff --check` — tidak menemukan whitespace error.
- Pull-to-refresh tidak diuji karena fitur tersebut belum ada di aplikasi.

## Refleksi

1. **Optimasi berdampak terbesar:** belum dapat ditentukan dari angka profiler.
   Pemisahan consumer dan `select` adalah optimasi yang paling langsung
   mengurangi cakupan rebuild berdasarkan struktur kode, tetapi belum diukur
   melalui call tree atau rebuild counter. Tidak tepat mengklaimnya sebagai
   peningkatan FPS.
2. **Memastikan bukan placebo:** gunakan build profile, skenario dan dataset
   yang sama, ulangi pengukuran beberapa kali, bandingkan median/persentil serta
   proporsi jank, lalu verifikasi rebuild lewat DevTools/Rebuild Stats. Pada
   pengukuran ini, hasil before/after belum membuktikan peningkatan.
3. **Trade-off:** pemisahan consumer dan `select` menambah pembagian tanggung
   jawab dan sedikit kompleksitas state/UI. `RepaintBoundary` dapat menambah
   layer/lokasi compositing, sehingga perlu dipertahankan hanya bila pengukuran
   menunjukkan manfaat.
4. **Menghindari premature optimization:** jangan mengoptimalkan berdasarkan
   dugaan atau angka satu kali. Profilkan alur nyata terlebih dahulu; utamakan
   masalah yang terukur, konsisten, dan berdampak pada pengguna, kemudian
   validasi ulang sambil menjaga keterbacaan dan perilaku.

## Keterbatasan dan langkah lanjut

Emulator x64, startup, animasi, dan input dapat mendistorsi angka. Jalankan
pengukuran berulang pada perangkat fisik atau emulator stabil, gunakan dataset
lebih besar, ambil Flame Chart dan heap snapshot Dart yang dapat dibandingkan,
dan implementasikan pull-to-refresh hanya jika memang ada sumber data yang
perlu diperbarui.
