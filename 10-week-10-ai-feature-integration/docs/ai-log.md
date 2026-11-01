# AI Log — Praktikum 2

## 1. Informasi Praktikum

- Proyek: Campus Notify
- Framework: Flutter
- Fitur: Pencarian judul pengumuman
- AI yang digunakan: GitHub Copilot

## 2. Prompt Mentah

### Prompt fitur

> Saya sedang mengembangkan aplikasi Campus Notify menggunakan Flutter.
>
> Buat fitur pencarian pengumuman berdasarkan judul pada halaman daftar pengumuman.
>
> Ketentuan:
>
> 1. Pencarian menggunakan judul pengumuman.
> 2. Pencarian tidak membedakan huruf besar dan kecil.
> 3. Jika kolom pencarian kosong, tampilkan seluruh pengumuman.
> 4. Jika tidak ada pengumuman yang cocok, tampilkan empty state dengan pesan "Pengumuman tidak ditemukan".
> 5. Ikuti arsitektur dan struktur folder yang sudah digunakan dalam proyek.
> 6. Jangan mengubah fitur login, navigasi, dan notifikasi.
> 7. Jangan menambahkan package baru jika tidak diperlukan.
>
> Sebelum menulis kode, periksa implementasi halaman daftar pengumuman dan struktur proyek yang sudah ada.
>
> Berikan implementasi kode, test case, dan langkah pengujian. Jangan mengarang nama class, method, atau file yang belum ada di proyek.

### Prompt pelaporan bug

> perbaiki ini setelah saya melakukan penambahan data muncul ini

Prompt disertai screenshot assertion Flutter: `'_dependents.isEmpty': is not true`.

## 3. Output Awal AI

Implementasi pencarian awal menambahkan state query dan provider filter di
`lib/features/announcements/presentation/providers/announcement_provider.dart`:

```dart
final announcementSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredAnnouncementsProvider = Provider<List<Announcement>>((ref) {
  final announcements = ref.watch(announcementProvider);
  final query = ref.watch(announcementSearchQueryProvider).trim().toLowerCase();

  if (query.isEmpty) return announcements;

  return announcements
      .where((announcement) => announcement.title.toLowerCase().contains(query))
      .toList();
});
```

Kolom pencarian pada `HomePage` memperbarui `announcementSearchQueryProvider`.
Daftar ditampilkan dari `filteredAnnouncementsProvider`; saat query tidak
kosong dan hasil filter kosong, UI menampilkan "Pengumuman tidak ditemukan".
Test awal mencakup kecocokan tanpa membedakan kapitalisasi, empty state, dan
mengosongkan query untuk menampilkan kembali semua data.

Pada implementasi awal, controller form tambah pengumuman dibuat di method
`_showAddAnnouncementDialog`, lalu di-dispose setelah `showDialog` selesai:

```dart
final titleController = TextEditingController();
final contentController = TextEditingController();

await showDialog<void>(
  context: context,
  builder: (dialogContext) {
    // Dialog memakai controller di atas.
    // Tombol Simpan memperbarui announcementProvider dan menutup dialog.
  },
);

titleController.dispose();
contentController.dispose();
```

## 4. Hasil Verifikasi

- Halaman daftar pengumuman yang aktif adalah `HomePage` pada
  `lib/pages/home_page.dart`; model dan provider pengumuman berada di
  `lib/features/announcements/presentation/providers/announcement_provider.dart`.
- Test widget yang menjalankan alur tambah data mereproduksi error:
  `A TextEditingController was used after being disposed`.
- Error muncul ketika dialog mulai ditutup, sementara `TextFormField` masih
  memakai controller selama animasi penutupan. Ini terkait dengan assertion
  pada screenshot.
- Perbaikan: controller dipindahkan ke stateful dialog `_AddAnnouncementDialog`.
  Controller kini di-dispose dalam `dispose()` dialog, bukan langsung sesudah
  pemanggilan `showDialog`. Dialog mengembalikan objek `Announcement`; halaman
  kemudian memperbarui provider setelah dialog selesai dan memeriksa
  `context.mounted`.
- Tidak ada perubahan pada login, navigasi, atau notifikasi dan tidak ada
  package baru.

## 5. Bukti Pengujian

- `flutter analyze lib\pages\home_page.dart test\announcement_search_test.dart`
  — **No issues found**.
- `flutter test test\announcement_search_test.dart` — **4 widget tests passed**,
  termasuk regresi tambah pengumuman.
- `flutter test` — **seluruh test suite lulus (14 tests)**.
- Pengujian manual pada emulator/perangkat **belum dilakukan**. Langkah manual
  yang disarankan: jalankan `flutter run`, buka halaman utama, tambahkan
  pengumuman melalui tombol "Tambah Pengumuman", tekan "Simpan", lalu pastikan
  dialog menutup, item baru muncul, dan tidak ada assertion/error pada layar.

## 6. Bukti Wajib: Temukan Satu Bug atau Halusinasi AI

- **Bug yang ditemukan:** controller form tambah pengumuman di-dispose sebelum
  widget `TextFormField` selesai dilepas.
- **Bukti:** setelah menambahkan test widget yang mengisi form dan menekan
  "Simpan", test mereproduksi `A TextEditingController was used after being
  disposed`. Screenshot pengguna juga menunjukkan assertion Flutter
  `'_dependents.isEmpty': is not true`.
- **Penyebab:** controller dibuat di `_showAddAnnouncementDialog` dan di-dispose
  tepat setelah `showDialog` selesai. Pada saat itu animasi penutupan masih
  membuat field form menggunakan controller tersebut.
- **Perbaikan:** controller kini dimiliki `_AddAnnouncementDialogState` dan
  di-dispose di `dispose()` milik dialog, setelah widget dilepas.
- **Verifikasi sesudah perbaikan:** test regresi memastikan dialog tertutup,
  pengumuman baru muncul di daftar, dan `tester.takeException()` bernilai null.
  Keempat test fitur serta seluruh suite Flutter lulus.
- **Halusinasi:** tidak ditemukan nama class atau file yang dikarang. Implementasi
  menggunakan `HomePage`, `Announcement`, dan provider yang memang ada dalam
  proyek.

## 7. Praktikum 3: Debug dan Refactor

### Debug dengan test merah

1. **Reproduksi dan isolasi:** implementasi sebelum refactor melakukan filter
   langsung di `filteredAnnouncementsProvider` pada presentation layer. Model
   `Announcement` juga didefinisikan di file presentation yang sama.
2. **Test merah:** awalnya dibuat
   `test/announcement_search_use_case_test.dart` untuk memverifikasi judul cocok,
   pencarian case-insensitive, query kosong, dan query tanpa hasil. Sebelum
   use case ditambahkan, test gagal saat kompilasi karena
   `domain/usecases/search_announcements.dart` dan `SearchAnnouncements` belum
   ada. Pada praktikum 7, test unit tersebut digabung dengan widget empty-state
   test ke `test/search_filter_test.dart`; file sementara awal sudah dihapus.
3. **Perbaikan:** model dipindah ke `domain/entities/announcement.dart`, lalu
   aturan filter dibuat sebagai `SearchAnnouncements` yang murni dan tidak
   bergantung pada Flutter, Riverpod, database, atau jaringan.
4. **Hasil:** keempat test use case lulus setelah implementasi.

### Refactor ke layer yang benar

- `HomePage` dan widget daftar/pencarian hanya menampilkan UI dan mengirim
  tindakan ke notifier. Tidak ada pemanggilan database atau Dio dari widget.
- `AnnouncementNotifier` menyimpan daftar dan menyediakan aksi tambah;
  `AnnouncementSearchNotifier` menyimpan kata kunci.
- Provider turunan memanggil use case untuk menghasilkan daftar terfilter,
  sehingga aturan pencarian tidak lagi berada di widget atau ditulis ulang di
  presentation.
- Bagian tampilan daftar, kartu, detail, empty state, serta field dialog
  dipisah agar fungsi/build tidak menampung keseluruhan alur panjang.
- **Batasan yang ditemukan saat inspeksi:** fitur pengumuman saat ini memang
  memakai state Riverpod in-memory; belum ada repository pengumuman atau sumber
  SQLite/Dio untuk dipanggil. Praktikum ini tidak menambahkan penyimpanan baru
  atau berpura-pura membuat data persisten. Jika repository SQLite/Dio
  pengumuman ditambahkan kelak, ia dapat dihubungkan melalui domain repository
  tanpa memindahkan akses data ke widget.

### Verifikasi akhir

- `flutter analyze` — **No issues found**.
- `dart format --set-exit-if-changed .` — formatting awal merapikan `lib/main.dart`
  yang sebelumnya tidak terformat; pemeriksaan ulang selesai dengan **29 file,
  0 changed**.
- `flutter test` — **seluruh test lulus (18 tests)** pada saat praktikum 3,
  termasuk empat test use case, pencarian widget, tambah pengumuman, dan test
  yang sudah ada.
- Pengujian manual di emulator/perangkat belum dilakukan.

## 8. AI Challenge — Review Search

Prompt review, tiga temuan, tabel usulan-vs-keputusan, keputusan per file,
test merah/hijau, serta bukti verifikasi untuk praktikum AI Challenge disimpan
di [ai-challenge-search-review.md](./ai-challenge-search-review.md).

## 9. Praktikum 7: Refactoring, Testing, dan Error Umum

- Aturan pencarian berada di use case kecil `SearchAnnouncements`, terpisah
  dari widget dan dapat diuji tanpa Flutter atau Riverpod.
- UI daftar/search dipecah menjadi widget kecil; state daftar dan kata kunci
  dikelola notifier. Widget tidak memanggil database atau Dio.
- Test unit use case dan satu widget test empty state ada di
  `test/search_filter_test.dart`. Test perilaku daftar lainnya ada di
  `test/announcement_search_test.dart`.
- Verifikasi: `flutter analyze` bersih, `dart format --set-exit-if-changed .`
  melaporkan 29 file dan 0 perubahan, serta `flutter test` lulus 20 test.
- Uji manual tiga query (`UJIAN`, `kuliah`, `beasiswa`) dan screenshot belum
  dilakukan pada perangkat dalam sesi ini. Langkah pengujian dan status bukti
  dicatat di [ai-challenge-search-review.md](./ai-challenge-search-review.md).

## 10. Mini Project / Industry Challenge

### Prompt inti dan konteks yang ditempel

**Peran:** Senior Flutter developer pada aplikasi Campus Notify.

**Konteks proyek:** Flutter, Riverpod, Clean Architecture feature-first.
Fitur pengumuman berada di `lib/features/announcements/`; halaman daftar
aktual adalah `lib/pages/home_page.dart`. State saat ini berupa list in-memory;
belum ada repository atau datasource pengumuman. SQLite dipakai oleh fitur
notes, bukan announcements. Tidak boleh mengarang endpoint atau skema database.

**Prompt inti yang dikirim:**

> Buat fitur pencarian pengumuman berdasarkan judul pada halaman daftar
> pengumuman. Pencarian tidak membedakan huruf besar/kecil. Bila query kosong,
> tampilkan seluruh pengumuman; bila tidak ada yang cocok, tampilkan empty state
> "Pengumuman tidak ditemukan". Ikuti struktur proyek, jangan mengubah login,
> navigasi, atau notifikasi, dan jangan menambah package. Periksa kode dan
> struktur proyek sebelum implementasi. Berikan kode, test, dan langkah uji.

**Konteks review yang ditempel:**

```text
Review kode search Flutter ini sebagai senior dev.
Konteks: feature-first (presentation->domain<-data),
Riverpod, SQLite + Dio.
Fokus: kebenaran, arsitektur, test. Abaikan style.
Beri 3 temuan + level blocker/saran + alasan.
```

### Output awal AI

Output awal menambahkan `announcementSearchQueryProvider` dan
`filteredAnnouncementsProvider`, dengan normalisasi `trim().toLowerCase()` dan
filter `announcement.title.contains(query)`. `HomePage` menampilkan field
search, daftar hasil, dan empty state. Setelah diperiksa, aturan filter
dipindahkan ke use case domain `SearchAnnouncements`; model dipindahkan ke
entity domain, dan UI/state dipecah. Output review, tiga usulan, serta
keputusan rinci tersimpan di
[ai-challenge-search-review.md](./ai-challenge-search-review.md).

### Refleksi

1. **Satu halusinasi AI dan pembuktiannya:** pada percakapan awal, AI
   menganggap file `announcement_search_test.dart` memiliki tiga test, lalu
   menyebut satu test regresi tambah pengumuman. Itu akurat setelah test
   ditambahkan, tetapi bukan bukti dari codebase sebelum test dibuat. Saya
   membuktikan keadaan sebenarnya dengan membaca isi file dan menjalankan
   `flutter test`; setelah reproduksi, test regresi ditambahkan dan baru
   kemudian dinyatakan ada. Tidak ada API atau file repository pengumuman yang
   diklaim sudah tersedia.
2. **Prompt paling membantu:** prompt yang menetapkan fitur spesifik,
   case-insensitivity, hasil kosong, arsitektur, larangan mengubah auth/routing/
   notification, dan meminta pemeriksaan codebase. Saya memperjelas konteks
   dengan menyebut `HomePage` sebagai daftar aktual dan menyatakan bahwa belum
   ada repository announcements, agar implementasi tidak mengarang API/DB.
3. **Refactor kode AI:** filter yang awalnya tertanam pada provider presentasi
   dipindahkan ke pure domain use case `SearchAnnouncements`; `Announcement`
   dipindahkan ke domain entity dan UI dipecah menjadi widget kecil yang
   terfokus.
4. **Keputusan tersulit:** menolak saran untuk query SQLite/Dio setiap kali
   mengetik. Secara umum itu bisa tepat pada data remote atau dataset besar,
   tetapi repository dan kontrak data pengumuman tidak tersedia. Memaksakan
   I/O akan menambah dependency dan perilaku yang tidak diminta. Keputusan dan
   bukti pencarian repo dicatat di tabel review.

Pengumpulan tugas dibuat di
`../09-week-9-ai-assisted-development/`, dengan README, salinan dokumen, dan
folder screenshot. Uji manual emulator serta screenshot masih perlu dilengkapi
oleh mahasiswa; dokumentasi tidak menyatakan bukti itu sudah tersedia.

---

# Praktikum 10 — AI Feature Integration Log

## Fitur

Asisten Kampus mengintegrasikan chat streaming. OCR dan pengenalan wajah
dijalankan lokal sebelum gambar dipertimbangkan untuk unggah; speech-to-text
menggunakan pengenalan offline jika perangkat mendukung Bahasa Indonesia.

## Prompt sistem

Prompt sistem yang dikirim ke Gemini:

> Anda adalah Asisten Kampus untuk pertanyaan informasi umum. Gunakan bahasa
> Indonesia yang jelas dan ringkas. Jangan meminta, mengulang, atau menebak
> NIK, nomor telepon, alamat, kata sandi, identitas, maupun data pribadi.
> Jangan mengarang jadwal atau kebijakan kampus; jika informasi tidak
> tersedia, nyatakan keterbatasan dengan jelas.

## User prompt

Contoh prompt pengujian anonim:

> Bagaimana cara menemukan pengumuman seminar kampus di aplikasi?

Prompt aktual selalu berasal dari pesan pengguna yang telah melewati
pemeriksaan data sensitif. Gambar dikirim hanya setelah pemeriksaan lokal dan
konfirmasi eksplisit; suara tidak dikirim sebagai audio.

## Output awal AI

> Untuk menemukan pengumuman seminar, buka halaman utama Campus Notify dan
> gunakan kolom pencarian pengumuman. Ketik kata kunci seperti “seminar” untuk
> melihat pengumuman yang sesuai.

**Catatan kejujuran:** teks di atas adalah contoh output awal ilustratif untuk
prompt yang dicatat, bukan kutipan respons Gemini live. API key tidak tersedia
dan request Gemini live tidak dijalankan selama pembuatan dokumen ini; jangan
menganggap contoh ini sebagai output yang telah diverifikasi layanan AI.

## Keputusan implementasi dan kontrol

- Respons ditampilkan streaming; error API menampilkan fallback pengumuman
  lokal dan tombol coba lagi.
- Jawaban singkat, penolakan, atau jawaban tanpa kecocokan kata bermakna dengan
  pertanyaan dianggap tidak relevan, tidak disimpan di cache, dan diganti
  fallback lokal.
- Batas biaya: 20 request per akun per hari pada perangkat ini. Cache respons
  berlaku 24 jam; cache key adalah hash prompt/gambar dan tidak menyimpan prompt
  asli. Respons yang terdeteksi berisi data pribadi tidak di-cache.
- Cache akun dibersihkan saat logout. Kuota perangkat tidak menggantikan
  penegakan kuota backend untuk produksi.

## Verifikasi

- `flutter analyze` — lulus, tidak ada isu.
- `flutter test` — lulus.
- `flutter build apk --debug` — lulus.
- Screenshot historis hasil analyze/test tersedia di folder `screenshots/`;
  tangkapan layar interaksi chat live belum direkam.
