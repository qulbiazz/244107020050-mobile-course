# Uji kirim pertama dari Firebase Console
1. Buka Firebase Console -> Messaging -> buat campaign notifikasi percobaan.
2. Masukkan title dan body, targetkan aplikasi Android Anda.
3. Kirim saat aplikasi dalam state background: banner sistem harus muncul. Klik banner: aplikasi terbuka.
5. Catat hasilnya sebagai bukti screenshots/fcm-console-test.png.
[!hasil screenshots](screenshots/fcm-console-test.png)
[!hasil screenshots](screenshots/02-foreground-notification.png)
[!hasil screenshots](screenshots/03-background-notification.png)
[!hasil screenshots](screenshots/04-terminated-notification.png)
[!hasil screenshots](screenshots/05-topic-notification.png)

# Checklist verifikasi mandiri
1. Token hanya di flutter_secure_storage, tidak di SharedPreferences/log/screenshot penuh.✅
2. 401 memicu refresh sekali lalu retry; refresh mati memaksa login ulang.✅
3. Ketiga app state teruji dengan tabel bukti; klik masuk ke rute yang benar.✅
4. Topik untuk broadcast, token untuk pesan personal.✅
5. flutter analyze bersih dan semua test lulus.
# Refleksi
1. Mengapa refresh token tidak boleh disimpan di SharedPreferences? Apa risikonya bila bocor?
SharedPreferences digunakan untuk penyimpanan data sederhana dan bukan dirancang sebagai tempat penyimpanan rahasia. Refresh token memiliki umur yang lebih panjang dan dapat digunakan untuk mendapatkan access token baru. Jika refresh token bocor, pihak lain berpotensi mempertahankan akses ke akun sampai token tersebut tidak berlaku atau dicabut.

Karena itu, project menggunakan flutter_secure_storage untuk menyimpan access token dan refresh token.

2. Apa yang rusak bila onTokenRefresh diabaikan selama satu semester perkuliahan?
FCM token dapat berubah. Jika aplikasi tidak mengirim token baru ke backend, backend dapat terus menggunakan token lama sehingga notification tidak lagi sampai ke perangkat tersebut.

Karena itu project menggunakan:
FirebaseMessaging.instance.onTokenRefresh.listen(...)
untuk mendeteksi token baru dan mengirimkannya kembali ke endpoint device.

3. Kapan memakai topik dan kapan memakai token perangkat? Beri contoh pesan kampus untuk masing-masing.
Topic digunakan untuk broadcast.
Contoh:
Topic:
pengumuman-kampus
Pesan:
Besok perkuliahan dilaksanakan secara daring.
Pesan tersebut dapat diterima oleh seluruh perangkat yang subscribe.
Sedangkan token perangkat digunakan untuk pesan yang ditujukan kepada perangkat/user tertentu.
Contoh:
Notifikasi personal:
Nilai UTS Anda telah tersedia.
Untuk informasi personal seperti nilai atau tagihan, token perangkat lebih sesuai daripada topic.

4. Bagian mana dari draf AI yang Anda tolak atau perbaiki, dan mengapa?
Bagian yang perlu diperiksa dan diperbaiki adalah lifecycle notification dan keamanan token. Implementasi akhir menggunakan background handler top-level, @pragma('vm:entry-point'), foreground local notification, onMessageOpenedApp, getInitialMessage, parsing data.route, serta onTokenRefresh.

Selain itu, token tidak seharusnya dicetak secara penuh pada log atau dimasukkan ke screenshot dokumentasi.

---

# Praktikum 10 — Integrasi Fitur AI

## Fitur yang diintegrasikan

Campus Notify menyediakan Asisten Kampus dengan streaming jawaban AI,
pemindaian OCR lokal dari kamera/galeri, input suara offline Bahasa Indonesia,
dan deskripsi gambar setelah pemeriksaan privasi serta persetujuan pengguna.
Inisialisasi Firebase/FCM berjalan setelah layar aplikasi tampil; jika push
notification gagal disiapkan, aplikasi tetap dapat digunakan dan menampilkan
peringatan beserta opsi untuk mencoba lagi.

### Persiapan

1. Jalankan `flutter pub get`.
2. Sediakan Gemini API key melalui mekanisme aman aplikasi:
   `AiService.saveApiKey(key)`. Jangan menaruh key di source code, README,
   log, atau screenshot.
3. Buka Asisten Kampus dari ikon chat di halaman utama. Input AI hanya untuk
   informasi umum; jangan gunakan NIK, nomor telepon, alamat, atau data sensitif.

## Bukti mesin hijau

Jalankan dari root proyek (folder yang berisi `pubspec.yaml`):

```powershell
flutter analyze
flutter test
```

Hasil verifikasi terakhir:

| Perintah | Hasil |
|---|---|
| `flutter analyze` | Lulus — No issues found |
| `flutter test` | Lulus — 30 test |
| `flutter build apk --debug` | Lulus |

## Risiko dan mitigasi

| Risiko | Mitigasi |
|---|---|
| Data pribadi terkirim ke AI | Prompt teks diperiksa sebelum request. OCR dan deteksi wajah berjalan lokal; gambar dengan teks pribadi atau wajah ditahan. Unggah gambar memerlukan konfirmasi. |
| Biaya AI meningkat | Maksimal 20 request per akun per hari pada perangkat; cache lokal berlaku 24 jam dan cache hit tidak memanggil API. |
| API key atau prompt bocor lewat cache | API key disimpan menggunakan `flutter_secure_storage`; cache hanya menyimpan hash request dan jawaban terbatas, bukan prompt. Cache per akun dibersihkan saat logout. |
| API gagal atau kuota habis | Tampilkan pesan dan fallback ke pengumuman kampus lokal yang relevan; tersedia tombol coba lagi. |
| Jawaban tidak relevan | Validasi jawaban terhadap prompt; bila tidak lolos, tampilkan fallback lokal dan jangan simpan jawaban itu di cache. |

> Batas 20 request ditegakkan di penyimpanan lokal perangkat. Produksi perlu
> menerapkan kuota otoritatif lintas perangkat di backend.

## Refleksi

1. **Fitur AI dan alasan:** Asisten chat dipilih karena cocok untuk pertanyaan
   umum kampus; OCR lokal membantu membaca pengumuman tanpa mengunggah dokumen.
   Input suara memudahkan aksesibilitas dan input cepat.
2. **Privasi:** NIK, nomor telepon, alamat, dan pola sensitif ditolak sebelum
   request teks. OCR serta pengenalan wajah dijalankan di perangkat. Audio
   dikenali offline. Gambar hanya diunggah setelah konfirmasi dan pemeriksaan.
3. **Fallback:** saat AI error, kuota tercapai, atau jawaban tidak relevan, chat
   menampilkan pengumuman lokal yang cocok dan opsi mencoba AI kembali.
4. **Pelajaran UX:** pengguna perlu tahu dengan jelas kapan data diproses lokal
   dan kapan akan meninggalkan perangkat; minta persetujuan tepat sebelum
   unggah dan tampilkan jalur offline yang tetap berguna.

Log prompt sistem, user prompt, dan output awal AI ada di
[`docs/ai-log.md`](docs/ai-log.md). Bukti visual disimpan di
[`screenshots/`](screenshots/).


# WEEK 7 CLEAN ARCHITECTUR

# Usulan AI vs Keputusan Final

| Aspek | Usulan | Keputusan final | Alasan |
|---|---|---|---|
| Feature-first | Memisahkan `auth` dan `announcements` | Diterapkan | Memudahkan pemeliharaan per fitur. |
| Repository interface | Ditempatkan di `domain/repositories/` | Diterapkan | Domain hanya mengenal kontrak. |
| Repository implementation | Ditempatkan di `data/repositories/` | Diterapkan | Implementasi mengelola akses eksternal. |
| Entity dan model | Dipisahkan | Diterapkan bila diperlukan | Entity tidak menangani serialisasi API. |
| Use case untuk setiap CRUD | Membuat use case `get`, `create`, `update`, dan `delete` | Ditolak jika hanya meneruskan satu pemanggilan | Menambah boilerplate tanpa logika tambahan. |
| Use case dengan aturan bisnis | Membuat use case khusus | Diterapkan bila diperlukan | Berguna untuk validasi kompleks, orkestrasi, atau proses bisnis yang digunakan ulang. |
| Dependency injection | Menggunakan Riverpod | Diterapkan | Tidak memerlukan package DI tambahan. |
| FCM | Memisahkan service notifikasi | Diterapkan | Memisahkan SDK notifikasi dari UI dan navigasi. |
| Semua kode dimasukkan ke `core/` | Menjadikan `core` tempat kode bersama | Ditolak | `core` hanya untuk kebutuhan lintas fitur. |

## Kesimpulan

Clean Architecture tidak berarti setiap operasi harus mempunyai banyak lapisan. Tujuan utama refactor ini adalah memisahkan tanggung jawab, menjaga domain tetap independen, dan mempermudah pengujian. Use case dibuat saat memiliki aturan bisnis atau orkestrasi yang nyata, bukan hanya untuk meneruskan pemanggilan repository.

# Dokumentasi AI Challenge — Campus Notify

Folder ini berisi dokumentasi evaluasi AI Challenge untuk penerapan Clean Architecture pada aplikasi Campus Notify.

## Isi Dokumentasi

- `AI_CHALLENGE.md`: prompt AI, usulan struktur folder, pemetaan file, dan wiring Riverpod.
- `DECISION_TABLE.md`: perbandingan usulan AI dan keputusan teknis final.
- `VERIFICATION.md`: perintah grep dan hasil verifikasi arsitektur.

## Checklist Sebelum Demo

- [✓] Repository interface berada di domain.
- [✓] Repository implementation berada di data.
- [✓] Domain tidak mengimpor Flutter, Dio, SQLite, atau Firebase.
- [✓] Entity tidak menangani serialisasi API.
- [✓] UI tidak memanggil Dio secara langsung.
- [✓] Wiring dependency menggunakan Riverpod.
- [✓] Keputusan mengenai use case didokumentasikan.
- [✓] Hasil tiga grep dicatat berdasarkan output aktual.
- [✓] `flutter analyze` telah dijalankan.
- [✓] Hasil `flutter test` dicatat secara jujur.
[!hasil screenshots](screenshots/week7_flutter-analyze.png)

[!hasil screenshots](screenshots/)
[!hasil screenshots](screenshots/week7_flutter-analyze.png)
[!hasil screenshots](screenshots/week7_flutter-analyze.png)

## Praktikum 3 — Profiling Flutter DevTools

Profiling dilakukan pada Android Emulator dalam `--profile` mode. Sesi
Performance menunjukkan 53 FPS rata-rata; pengukuran frame singkat setelah
interaksi chat mencatat 34 frame dengan 10 janky frames (29.41%). Snapshot
memori proses mencatat PSS 201,412 KB dan RSS 351,228 KB. Karena pengukuran
dilakukan di emulator dan mencakup interaksi UI, hasil ini bersifat eksploratif,
bukan baseline produksi.

Laporan metode, hasil CPU sampling, batasan pengukuran, dan bukti:
[`docs/flutter-devtools-profiling.md`](docs/flutter-devtools-profiling.md).

## Praktikum 7 — Optimasi Performa

Perubahan pada daftar pengumuman mempersempit cakupan rebuild, menambahkan
`select` untuk status empty-state, memisahkan repaint kontrol pencarian, dan
meniadakan keep-alive baris stateless. Baseline dan post-optimasi tersedia di
[`docs/performance-report.md`](docs/performance-report.md). Verifikasi setelah
perubahan: `flutter analyze` lulus (`No issues found`) dan `flutter test` lulus
(30 test). Metrik emulator belum membuktikan peningkatan jank; laporan
mendokumentasikan temuan, refleksi, dan keterbatasan pengukuran.

---

## Praktikum — Pengujian Perilaku dan Alur Aplikasi (Unit, Dependency, Widget, & Integration Test)

Pengujian komprehensif dilakukan pada fitur utama aplikasi (**Pengumuman Kampus**), mencakup:
1. **Pencatatan Perilaku & Skenario**: Kasus utama (*happy path*), kasus tepi (*edge case: trimming & case-insensitivity*), dan kasus kegagalan (*failure case: validasi input kosong & server failure*).
2. **Uji Logika (Unit Test)**: Validasi aturan bisnis domain entitas `Announcement` dan `SearchAnnouncements` yang dikelompokkan dengan `group()` di [`test/announcement_logic_test.dart`](test/announcement_logic_test.dart).
3. **Uji Dependensi**: Pemisahan akses data menggunakan `AnnouncementRepository`, diuji menggunakan `FakeSuccessAnnouncementRepository` dan `FakeErrorAnnouncementRepository` di [`test/announcement_repository_test.dart`](test/announcement_repository_test.dart).
4. **Uji UI (Widget Test)**: Pengujian tampilan awal *empty state*, validasi masukan tidak valid, dan tindakan pengguna berhasil di [`test/announcement_ui_test.dart`](test/announcement_ui_test.dart).
5. **Uji Alur Utama (Integration Test)**: Pengujian alur end-to-end lintas modul (`Login -> Beranda -> Tambah Pengumuman -> Cari -> Detail -> Logout`) di [`integration_test/app_test.dart`](integration_test/app_test.dart).

Laporan lengkap skenario, arsitektur pengujian, dan bukti verifikasi tersedia di [`docs/praktikum-pengujian.md`](docs/praktikum-pengujian.md).

### Hasil Verifikasi Mesin Hijau:
| Perintah | Hasil |
|---|---|
| `flutter analyze` | Lulus — No issues found |
| `flutter test` | Lulus — 62 tests passed |
| `flutter test --coverage` | Lulus — 62 tests; cakupan baris seluruh `lib/` 27,44% (264/962) |
| `flutter test integration_test/app_test.dart -d emulator-5554` | Lulus — All tests passed (Android API 35) |

Angka cakupan hanya menunjukkan baris yang dijalankan, bukan bahwa semua
perilaku telah diperiksa. Cakupan fitur pengumuman yang relevan lebih tinggi:
`HomePage` 80,6%, use case pencarian dan provider 100%; cakupan keseluruhan
turun karena fitur lain belum menjadi fokus tugas ini.

### Temuan yang Belum Terselesaikan

Tidak ada kegagalan pada tes atau analisis yang dijalankan. Namun, alur chat/AI,
integrasi jaringan dan ML Kit, notifikasi push, serta penyimpanan autentikasi
belum memiliki cakupan perilaku yang memadai. Tes integrasi menggunakan
`InMemoryTokenStore` dan menonaktifkan push, sehingga tidak memverifikasi
Firebase, layanan eksternal, atau penyimpanan token perangkat sebenarnya.

### Refleksi

1. **Bug yang mungkin terlewat:** pencarian yang menampilkan hasil salah untuk
   variasi huruf besar-kecil atau query kosong, serta pengumuman dengan judul
   atau isi kosong yang lolos validasi.
2. **Fake yang digunakan:** fake repository memodelkan hasil sukses dan error
   tanpa jaringan atau server sungguhan; `InMemoryTokenStore` mengisolasi sesi
   integrasi tanpa plugin penyimpanan perangkat. Hasilnya konsisten dan dapat
   diulang, termasuk ketika skenario error diuji.
3. **Nilai widget vs integrasi:** widget test memeriksa tampilan dan validasi
   form secara cepat serta terisolasi. Tes integrasi memastikan modul login,
   navigasi, pengumuman, pencarian, detail, dan logout bekerja bersama pada
   alur pengguna di emulator.

---

## Praktikum — Uji Fitur Daftar Tugas (Catatan)

Di aplikasi saat ini, daftar tugas yang dimaksud direpresentasikan oleh fitur
**Catatan** pada `NotesPage`; belum ada layar tugas terpisah atau navigasi ke
halaman Catatan dari beranda. Pengujian berikut mencakup alur daftar yang sudah
tersedia tanpa mengubah navigasi aplikasi.

### Skenario

| Skenario | Pengujian | Hasil yang diharapkan |
|---|---|---|
| Sukses | Daftar catatan berhasil dimuat; pemetaan model ke entitas | Judul, isi, ID, waktu, dan status tersimpan dipertahankan |
| Input tidak valid | Judul kosong atau hanya whitespace | Entitas menolak nilai dengan `ArgumentError`; judul valid di-trim |
| Daftar kosong | Repository mengembalikan daftar kosong | Empty state `Belum ada catatan.` ditampilkan |
| Kegagalan data | Database gagal dibuka atau repository mengembalikan `Failure` | Error ditampilkan dan tidak disamarkan sebagai daftar kosong |
| Pemulihan | Pengguna menekan `Coba Lagi` setelah error | Provider dimuat ulang dan catatan yang tersedia ditampilkan |

Unit test di [`test/note_test.dart`](test/note_test.dart) memeriksa validasi
judul, nilai default, dan round-trip pemetaan `NoteModel`. Pengujian
[`test/note_repository_test.dart`](test/note_repository_test.dart) memakai fake
repository untuk hasil sukses/gagal, menguji use case dan provider, serta
memverifikasi kegagalan pembukaan database di implementasi repository.
Widget test di [`test/notes_page_test.dart`](test/notes_page_test.dart)
memeriksa empty state, hasil daftar, pesan error, dan interaksi retry.

Tes integrasi [`integration_test/notes_flow_test.dart`](integration_test/notes_flow_test.dart)
memasang `NotesPage` pada perangkat/emulator, memuat data melalui provider dan
fake repository, lalu memastikan judul serta isi muncul. Ini memverifikasi
integrasi daftar dan provider pada perangkat, tetapi bukan navigasi dari login
atau operasi SQLite sungguhan karena halaman Catatan belum terhubung ke rute
utama.

### Hasil dan Analisis

| Perintah | Hasil |
|---|---|
| `flutter test` | Lulus — 62 tes |
| `flutter test --coverage` | Lulus — 62 tes; 264/962 baris (27,44%) pada seluruh `lib/` |
| `flutter test integration_test/notes_flow_test.dart -d emulator-5554` | Lulus — 1 tes pada emulator Android API 35 |
| `flutter analyze` | Lulus — No issues found |

Cakupan area Catatan pada laporan tersebut: `NotesPage` 100%, entitas `Note`
100%, use case `GetNotes` 100%, provider 85,7%, model `NoteModel` 95,2%, dan
`NoteRepositoryImpl` 50%. Bagian database yang tidak tercakup sukses adalah
interaksi `sqflite` aktual; tes repository menguji kegagalan membuka database,
sedangkan perilaku daftar sukses diuji melalui fake. Persentase cakupan adalah
petunjuk area yang dijalankan, bukan bukti lengkap untuk seluruh perilaku.

### Refleksi

1. Bug yang mungkin terlewat tanpa tes ini adalah judul whitespace yang
   tersimpan, catatan yang hilang atau salah dipetakan saat dibaca, serta tombol
   retry yang tidak memuat ulang daftar setelah kegagalan database.
2. Fake repository menggantikan database lokal sehingga tes sukses dan gagal
   berjalan tanpa kondisi perangkat, data lama, atau plugin SQLite; hasil tes
   menjadi cepat dan dapat diulang. Kegagalan membuka database asli tetap
   diperiksa dengan dependency injection pada repository.
3. Widget test memeriksa empty state, isi daftar, pesan error, dan tombol retry
   secara terisolasi. Tes integrasi memverifikasi bahwa provider dan halaman
   daftar bekerja bersama pada perangkat dengan data repository; ia belum
   menguji navigasi aplikasi maupun penyimpanan SQLite sebenarnya.
