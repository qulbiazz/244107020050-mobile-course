# Praktikum 7 — Optimasi Performa

## Lingkungan dan skenario

- Flutter 3.29.0 / Dart 3.7.0 / DevTools 2.42.2
- Android 15 (API 35), emulator x64, aplikasi profile mode
- Skenario: buka daftar pengumuman berisi data sintetis, scroll, buka detail,
  kembali, lalu lakukan gesture tarik. Daftar ini sepenuhnya lokal dan saat ini
  belum menyediakan aksi pull-to-refresh.
- Frame stats diambil dengan `adb shell dumpsys gfxinfo`; pengukuran emulator
  tidak setara dengan hasil pada perangkat fisik.

## Baseline dan temuan

Baseline Performance menunjukkan sekitar 56 FPS rata-rata selama sesi. Pada
interval interaksi yang dicatat Android terdapat 15 frame, 6 janky frames
(40%), P50 48 ms, P90 81 ms, P95/P99 93 ms, dan 2 missed VSync. Sampel ini
sangat pendek dan mencakup animasi/input emulator; daftar uji juga kecil.
Jangan ditafsirkan sebagai angka representatif steady-state. Screenshot baseline:
[`screenshots/before-profile.png`](../screenshots/before-profile.png).

| Temuan | Bukti | Penilaian |
|---|---|---|
| `_AnnouncementList` sebelumnya mengamati daftar mentah, query, dan hasil filter pada satu `ConsumerWidget`; perubahan query membangun ulang kolom, kontrol pencarian, serta hasil. | Kode sebelum perubahan di `lib/pages/home_page.dart`; DevTools tidak menghasilkan call tree yang cukup untuk menghitung biaya rebuild. | Peluang mengurangi cakupan rebuild, bukan penyebab jank yang sudah dibuktikan. |
| Filter mengubah setiap judul menjadi huruf kecil dan memindai seluruh daftar pada setiap query baru. | `SearchAnnouncements.call` di `lib/features/announcements/domain/usecases/search_announcements.dart`. | Biaya O(jumlah pengumuman) per perubahan query; daftar lokal kecil, dampak belum terukur. |
| Kartu pengumuman stateless tidak memerlukan keep-alive ketika keluar dari viewport. | `_AnnouncementCard` tidak memegang state; ListView memakai keep-alive otomatis secara default. | Wrapper keep-alive yang tidak diperlukan dihilangkan; penghematan belum terisolasi oleh profiler. |

Pemeriksaan negatif: daftar sudah memakai `ListView.separated` yang lazy; tidak
ada gambar jaringan atau pemuatan HTTP pada fitur ini. Tidak ditemukan bukti
untuk menyebut image decode, request berulang, atau memory leak sebagai masalah.
Tidak ada pull-to-refresh yang bisa diuji karena fitur refresh belum
diimplementasikan.

## Optimasi yang diterapkan

1. Memisahkan langganan Riverpod: widget daftar utama kini stateless; kontrol
   pencarian dan hasil daftar menjadi consumer terpisah.
2. Menggunakan `select` untuk status daftar kosong dan status query kosong agar
   perubahan isi teks yang tidak mengubah boolean tersebut tidak membangun ulang
   bagian empty-state.
3. Membungkus kontrol pencarian dalam `RepaintBoundary` agar repaint area kontrol
   terpisah dari area hasil.
4. Menonaktifkan automatic keep-alives untuk baris daftar yang stateless; builder
   lazy yang sudah ada tetap dipertahankan.

Verifikasi setelah perubahan: `flutter analyze` lulus tanpa temuan dan `flutter
test` lulus (30 test).

## Verifikasi setelah optimasi

Perbandingan dilakukan pada sesi profile baru dengan daftar sintetis berukuran
kecil dan gesture/interaksi yang sama. DevTools menunjukkan 56 FPS rata-rata
pada baseline dan 52 FPS setelah perubahan. Pada interval Android terdapat
15 frame/6 janky frames (40%) sebelum dan 16 frame/7 janky frames (43.75%)
sesudah; P50 48 → 46 ms, P90 81 → 73 ms, P95/P99 93 → 77 ms, missed VSync
tetap 2. Proporsi jank dan FPS sesi tidak membaik. Perubahan percentile terlalu
kecil sampelnya untuk dikaitkan dengan optimasi, sehingga hasil harus dianggap
**belum membuktikan peningkatan frame pacing**.

DevTools Performance menampilkan keseluruhan trace, yang juga mencakup startup
dan kerja emulator. Flame Chart tidak menyediakan call tree yang dapat
diverifikasi pada sesi ini, sehingga tidak ada klaim tentang fungsi teratas.

- [`screenshots/after-profile.png`](../screenshots/after-profile.png)
- Tampilan daftar setelah optimasi:
  [`screenshots/after-profile-run.png`](../screenshots/after-profile-run.png)

## Pemeriksaan memori

Lima siklus buka-detail/kembali pada proses profile yang sama menghasilkan
perubahan PSS dari 144,159 KB ke 144,546 KB (+387 KB), dan RSS dari 323,940 KB
ke 324,596 KB (+656 KB). Ini dua snapshot proses, bukan heap snapshot Dart dan
tidak membuktikan ada atau tidaknya leak. DevTools menampilkan Memory chart,
tetapi pengambilan/diff heap snapshot tidak berhasil dilakukan pada sesi ini.

- [`screenshots/memory-before-navigation.png`](../screenshots/memory-before-navigation.png)
- [`screenshots/memory-after-navigation.png`](../screenshots/memory-after-navigation.png)

## Kesimpulan dan tindak lanjut

Optimasi rebuild dan list telah diterapkan tanpa mengubah perilaku pencarian.
Data profile yang singkat belum menunjukkan penurunan jank yang dapat
diandalkan. Untuk keputusan optimasi lanjutan, rekam ulang pada perangkat fisik
dengan trace CPU pendek yang berhasil, query pencarian dan daftar lebih besar,
serta heap snapshots Dart sebelum/sesudah navigasi. Tambahkan pull-to-refresh
hanya bila alur refresh data benar-benar menjadi kebutuhan produk.
