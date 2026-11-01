# AI Challenge — Review Search Pengumuman

## Prompt yang digunakan

```text
Review kode search Flutter ini sebagai senior dev.
Konteks: feature-first (presentation->domain<-data),
Riverpod, SQLite + Dio.
Fokus: kebenaran, arsitektur, test. Abaikan style.
Beri 3 temuan + level blocker/saran + alasan.
```

## Output review AI

### Temuan 1 — Query provider dan teks kolom pencarian dapat berbeda setelah halaman dibuat ulang

- **Level:** Saran.
- **Alasan:** Query disimpan oleh `announcementSearchQueryProvider` pada scope
  Riverpod yang dapat hidup lebih lama daripada state internal `TextField`.
  Saat halaman daftar dilepas lalu dibuat kembali, query lama masih memfilter
  hasil sedangkan kolom input yang dibuat ulang semula kosong. Pengguna melihat
  hasil terfilter tanpa mengetahui kata kunci aktif.
- **Bukti:** Test
  `membuat ulang halaman menyelaraskan query dan kolom pencarian` di
  `test/announcement_search_test.dart` gagal sebelum perbaikan karena
  `Perubahan Ruang Kuliah` tidak ditemukan, walaupun input halaman yang baru
  dibuat kosong.
- **Keputusan:** **Terima + refactor.**
- **Perbaikan:** `_AnnouncementSearchField` sekarang memiliki
  `TextEditingController` dengan lifecycle widget dan menyelaraskan isinya ke
  query Riverpod. Saat halaman dibuat kembali, field menunjukkan kata kunci
  yang tetap digunakan oleh filter.
- **Bukti setelah perbaikan:** test yang sama lulus; controller menunjukkan
  `UJIAN` dan hasil tetap terfilter sesuai kata kunci tersebut.

### Temuan 2 — Data pengumuman belum menggunakan repository/persistence

- **Level:** Saran.
- **Alasan:** `AnnouncementNotifier` memulai dengan list kosong dan menambahkan
  data hanya ke state in-memory. Karena itu, data pengumuman tidak bertahan
  setelah aplikasi/provider scope dibuat ulang. Search use case hanya mencari
  data yang saat ini ada dalam state tersebut.
- **Bukti:** pencarian kode pada
  `lib/features/announcements` menemukan entity, use case, dan provider
  presentation, tetapi tidak menemukan `AnnouncementRepository`, datasource,
  SQLite, atau Dio. SQLite yang ditemukan berada pada fitur `notes`, bukan
  pengumuman.
- **Keputusan:** **Terima sebagai batasan yang perlu dicatat; tidak mengubah
  persistence pada challenge ini.**
- **Alasan keputusan:** Membuat repository tanpa kontrak API/schema atau
  kebutuhan penyimpanan yang ditentukan akan menjadi perubahan lingkup dan
  berisiko mengarang endpoint atau skema database. Search tetap murni mencari
  daftar yang diberikan; tidak ada akses database dari widget.

### Temuan 3 — Search use case sebaiknya memanggil SQLite/Dio saat query berubah

- **Level:** Saran.
- **Alasan usulan review:** Melakukan query di repository dapat sesuai bila
  pengumuman memang dimuat dari database atau server dan daftar terlalu besar
  untuk difilter di memori.
- **Keputusan:** **Tolak untuk implementasi saat ini.**
- **Alasan teknis:** Belum ada announcement repository atau kontrak sumber data
  pengumuman di proyek. Use case saat ini menerima list state yang sudah
  tersedia, sehingga operasi sinkron dan murni lebih tepat. Memanggil SQLite
  atau Dio dari use case ini akan menambah dependency/data flow yang tidak
  tersedia, dan membuat pencarian tiap ketikan melakukan I/O tanpa kebutuhan
  yang terbukti. Jika repository pengumuman ditambahkan, use case dapat
  diubah secara terukur berdasarkan kontraknya.

## Tabel usulan dan keputusan

| No. | Usulan review | Bukti | Keputusan | Perubahan / alasan |
|---|---|---|---|---|
| 1 | Selaraskan query provider dengan nilai kolom setelah halaman dibuat ulang | Test lifecycle merah: list tidak cocok muncul saat field yang baru dibuat kosong | **Terima + refactor** | Controller field diinisialisasi dan diselaraskan dengan query Riverpod; test regresi lulus |
| 2 | Gunakan repository untuk data pengumuman persisten | Tidak ada announcement repository/datasource; provider hanya list in-memory | **Terima sebagai catatan, tunda implementasi** | Perlu kontrak API/DB; tidak mengarang schema atau endpoint dalam task search |
| 3 | Panggil SQLite/Dio dari search use case untuk setiap query | Data saat ini tersedia sebagai list state; tidak ada repo pengumuman | **Tolak** | I/O tidak diperlukan dan melanggar tanggung jawab use case search murni saat ini |

## Keputusan per file

| File | Keputusan | Penjelasan |
|---|---|---|
| `lib/features/announcements/domain/entities/announcement.dart` | **Terima** | Entity domain terpisah dari UI dan detail framework |
| `lib/features/announcements/domain/usecases/search_announcements.dart` | **Terima** | Aturan filter murni, case-insensitive, menangani query kosong dan tanpa hasil |
| `lib/features/announcements/presentation/providers/announcement_provider.dart` | **Terima + refactor** | Notifier menyimpan list/query; provider hasil filter mendelegasikan aturan ke use case |
| `lib/pages/home_page.dart` | **Terima + refactor** | UI membaca provider dan meneruskan input; controller search diselaraskan dengan state saat widget dibuat ulang; tidak ada panggilan database/Dio |
| `test/search_filter_test.dart` | **Terima + refactor** | Menguji aturan domain secara langsung dan empty state pada widget |
| `test/announcement_search_test.dart` | **Terima + refactor** | Widget test membuktikan hasil, empty state, penambahan data, dan sinkronisasi lifecycle search |
| `docs/ai-challenge-search-review.md` | **Terima** | Menyimpan prompt, output review, bukti, dan keputusan challenge |

## Bukti verifikasi

### Test merah

Sebelum perbaikan lifecycle search:

```text
flutter test test\announcement_search_test.dart --plain-name
"membuat ulang halaman menyelaraskan query dan kolom pencarian"
```

Hasil gagal pada ekspektasi bahwa seluruh pengumuman muncul: query lama masih
aktif pada provider walaupun halaman/kolom pencarian dibuat ulang.

### Test setelah perbaikan

```text
flutter test test\announcement_search_test.dart
```

Hasil: **5 widget tests passed**, termasuk test lifecycle.

```text
flutter test test\search_filter_test.dart
```

Hasil: **4 use case tests passed** dan satu widget test empty state.

### Pemeriksaan final

```text
flutter analyze
dart format --set-exit-if-changed .
flutter test
```

Hasil workspace:

- `flutter analyze` — **No issues found**.
- `dart format --set-exit-if-changed .` — **29 files, 0 changed**.
- `flutter test` — **All tests passed (20 tests)**.

### Uji manual 3 query dan screenshot

Uji pada emulator/perangkat belum dijalankan dari sesi ini; screenshot belum
diambil dan tidak diklaim sebagai bukti. Jalankan `flutter run`, tambahkan
beberapa pengumuman, lalu uji:

1. `UJIAN` — judul yang mengandung "Ujian" tampil tanpa membedakan kapital.
2. `kuliah` — judul yang mengandung "Kuliah" tampil.
3. `beasiswa` — empty state "Pengumuman tidak ditemukan" tampil.

Ambil screenshot untuk setiap hasil dan simpan bersama bukti praktikum.

## Penjelasan keputusan teknis

- Bug yang diterima adalah sinkronisasi antara state pencarian di Riverpod dan
  nilai input lokal widget. Test lifecycle membuktikan bahwa hasil filter lama
  bisa tetap aktif ketika input baru tampak kosong. Query dipertahankan dan
  ditampilkan kembali di kolom, sehingga state dan UI konsisten.
- Temuan persistence benar untuk kondisi saat ini, tetapi tidak diperbaiki
  karena tidak ada datasource/repository atau kontrak API pengumuman untuk
  diimplementasikan secara aman.
- Usulan query DB/Dio pada setiap perubahan kata kunci ditolak karena search
  sekarang bekerja pada list state lokal dan tidak membutuhkan I/O. Domain
  tetap bebas dependency Flutter, Riverpod, SQLite, dan Dio.
