# Laporan Praktikum Pengujian Aplikasi (Testing: Logika, Dependensi, UI, dan Alur Utama)

## 1. Fitur yang Diuji
Fitur yang diuji adalah fitur utama pada aplikasi **Campus Notify**, yaitu **Manajemen Pengumuman Kampus (Announcements)** yang terintegrasi dengan autentikasi, pencarian, dan navigasi detail.

---

## 2. Catatan Perilaku (Skenario Pengujian)

| ID | Jenis Skenario | Deskripsi Skenario | Ekspektasi Perilaku |
|---|---|---|---|
| **SKN-01** | Kasus Utama (*Happy Path*) | Pengguna memasukkan judul dan isi pengumuman yang valid, kemudian menekan tombol "Simpan". | Sistem memvalidasi masukan, menyimpan data melalui *repository*, menutup dialog, memunculkan *SnackBar* konfirmasi `"Pengumuman berhasil ditambahkan"`, dan memperbarui daftar pengumuman di beranda. |
| **SKN-02** | Kasus Tepi (*Edge Case*) | Pengguna memasukkan judul atau isi dengan spasi berlebih di awal/akhir (*leading/trailing whitespace*) seperti `"   Jadwal Pengganti   "`, atau melakukan pencarian dengan variasi huruf besar-kecil (*case-insensitive*) dan spasi kosong. | Entitas domain melakukan *trimming* otomatis sehingga data tersimpan dalam bentuk bersih tanpa spasi kosong di tepi. Fitur pencarian bersifat *case-insensitive* dan query kosong/hanya spasi mengembalikan seluruh daftar tanpa error. |
| **SKN-03** | Kasus Kegagalan (*Failure Case*) | 1. Pengguna menekan tombol "Simpan" dengan kolom judul atau isi kosong / hanya berisi spasi.<br>2. Terjadi kegagalan akses data (*network error / server offline*) saat membaca atau menyimpan ke *repository*. | 1. Pada level UI, form validator menampilkan pesan `"Judul wajib diisi"` dan `"Isi pengumuman wajib diisi"`, dialog tetap terbuka, dan data tidak tersimpan.<br>2. Pada level domain entitas, *constructor* melempar `ArgumentError`.<br>3. Pada level repository, kegagalan ditangani secara terisolasi tanpa menyebabkan *unhandled crash*. |

---

## 3. Uji Logika (Unit Test)
Pengujian logika bisnis dan validasi domain diimplementasikan pada file [`test/announcement_logic_test.dart`](../test/announcement_logic_test.dart) dengan pengelompokan menggunakan `group()`:

### Group 1: `Announcement Entity Validation`
- `membuat announcement berhasil jika data valid`: Memastikan entitas `Announcement` dapat dibuat dengan ID, judul, isi, dan tanggal pembuatan yang valid.
- `menghapus spasi di awal dan akhir pada judul dan konten (edge case: trimming)`: Menguji otomatisasi pembersihan spasi tepi pada *field* judul dan isi.
- `menolak judul kosong dengan ArgumentError (failure case)`: Memastikan judul berkarakter kosong `""` ditolak oleh *business rule*.
- `menolak judul yang hanya berisi whitespace dengan ArgumentError (failure case)`: Memastikan judul yang hanya terdiri atas spasi/tab/newline `\t\n ` ditolak.
- `menolak konten pengumuman kosong dengan ArgumentError (failure case)`: Memastikan isi pengumuman tidak boleh kosong.
- `menolak konten pengumuman yang hanya berisi whitespace dengan ArgumentError (failure case)`: Memastikan isi pengumuman yang hanya whitespace ditolak.

### Group 2: `SearchAnnouncements Business Rules`
- `mengembalikan pengumuman yang mengandung substring judul`: Memastikan fungsi pencarian mencocokkan kata kunci parsial.
- `pencarian tidak peka terhadap huruf besar-kecil (case-insensitive)`: Memastikan kata kunci seperti `'uJiAn'` mencocokkan pengumuman bertuliskan `'UJIAN'` atau `'Ujian'`.
- `query kosong atau hanya spasi mengembalikan seluruh daftar pengumuman (edge case)`: Menguji query `""` dan `"   "` mengembalikan semua item tanpa filter.
- `query yang tidak cocok menghasilkan daftar kosong (failure case)`: Memastikan query tanpa kecocokan menghasilkan `isEmpty`.

---

## 4. Uji Dependensi (Repository & Fake)
Akses data diabstraksi ke dalam *contract* interface:
- [`lib/features/announcements/domain/repositories/announcement_repository.dart`](../lib/features/announcements/domain/repositories/announcement_repository.dart)

Implementasi pengujian menggunakan *Fake Object* pada file [`test/announcement_repository_test.dart`](../test/announcement_repository_test.dart):
- `FakeSuccessAnnouncementRepository`: Mensimulasikan operasi penyimpanan dan pembacaan data yang sukses di memori.
- `FakeErrorAnnouncementRepository`: Mensimulasikan kegagalan I/O (misal: server offline atau koneksi terputus) dengan melemparkan `Exception`.

Kelompok pengujian:
1. `group('FakeSuccessAnnouncementRepository (Skenario Sukses)')`:
   - Pengambilan daftar data awal berhasil.
   - Penambahan pengumuman baru berhasil dan bertambah pada posisi teratas.
2. `group('FakeErrorAnnouncementRepository (Skenario Error / Kegagalan)')`:
   - `getAnnouncements` melemparkan `Exception` ketika server offline.
   - `addAnnouncement` melemparkan `Exception` saat koneksi terputus.
3. `group('Provider dengan Fake Repository')`:
   - Memastikan `AnnouncementNotifier.loadFromRepository()` memperbarui state Riverpod secara reaktif saat *repository* sukses.
   - Memastikan kegagalan *repository* ditangkap dengan baik.

---

## 5. Uji Tampilan Antarmuka (Widget Test / UI Test)
Pengujian antarmuka pengguna diimplementasikan pada file [`test/announcement_ui_test.dart`](../test/announcement_ui_test.dart) mencakup 3 aspek wajib:
1. **Pemeriksaan Tampilan Awal (*Initial State*)**:
   - Memverifikasi teks judul `'Campus Notify'`.
   - Memverifikasi *empty state*: teks `'Belum ada pengumuman'`, ikon `Icons.campaign_outlined`, dan teks bantuan `'Tekan tombol + untuk menambahkan pengumuman.'`.
   - Memverifikasi keberadaan kolom pencarian dan tombol FAB `'Tambah Pengumuman'`.
2. **Pemeriksaan Masukan Tidak Valid (*Validation Error*)**:
   - Membuka dialog form tambah pengumuman.
   - Menekan tombol `'Simpan'` saat kolom judul dan isi kosong atau hanya berisi spasi.
   - Memverifikasi pesan kesalahan validasi muncul: `'Judul wajib diisi'` dan `'Isi pengumuman wajib diisi'`.
   - Memverifikasi dialog tetap terbuka dan data tidak masuk ke daftar.
3. **Pemeriksaan Tindakan Pengguna yang Berhasil (*Successful Action*)**:
   - Memasukkan data valid pada form tambah pengumuman.
   - Menekan tombol `'Simpan'`.
   - Memverifikasi dialog tertutup (`findsNothing`).
   - Memverifikasi kemunculan *SnackBar* `'Pengumuman berhasil ditambahkan'`.
   - Memverifikasi kartu pengumuman baru tampil pada daftar utama.

---

## 6. Uji Alur Utama (Integration Test)
Pengujian integrasi end-to-end ditulis pada file [`integration_test/app_test.dart`](../integration_test/app_test.dart) untuk menguji alur multi-layer nyata aplikasi:
1. **Autentikasi (Halaman Login)**: Pengguna memasukkan email dan password valid, lalu menekan tombol *Login*.
2. **Navigasi (*GoRouter*)**: Sistem memvalidasi sesi dan secara otomatis mengarahkan ke halaman Beranda (`HomePage`).
3. **Pembuatan Pengumuman**: Pengguna menekan tombol FAB, mengisi form pengumuman di modal dialog, dan menyimpannya.
4. **Pencarian**: Pengguna mengetikkan kata kunci pada *search field* dan memverifikasi hasil filter.
5. **Halaman Detail**: Pengguna mengetuk kartu pengumuman untuk melihat detail lengkap judul dan isi.
6. **Navigasi Balik**: Pengguna menekan tombol *back* untuk kembali ke `HomePage`.
7. **Logout**: Pengguna menekan tombol *Logout* pada AppBar dan diarahkan kembali ke `LoginPage`.

> **Catatan Isolasi Pengujian**:
> Untuk menghindari kegagalan akibat ketergantungan jaringan eksternal, urutan test, atau data bersama (*shared state*), pengujian integrasi mengeset `enablePushNotifications: false` (menonaktifkan Firebase/FCM) dan menggunakan `InMemoryTokenStore` yang terisolasi per pengujian.

---

## 7. Bukti Eksekusi dan Verifikasi (Mesin Hijau)

### A. `flutter analyze`
```powershell
flutter analyze
```
**Hasil:**
```
Analyzing campus_notify...
No issues found! (ran in 8.9s)
```

### B. `flutter test` (Unit Test & Widget Test)
```powershell
flutter test
```
**Hasil:**
```
00:04 +49: All tests passed!
```
Seluruh 49 pengujian (termasuk pengujian logika entitas, use case, fake repository, dan widget UI) berhasil lulus 100%.

### C. `flutter test integration_test/app_test.dart -d <device_id>`
```powershell
flutter test integration_test/app_test.dart -d emulator-5554
```
**Hasil:**
```
00:00 +0: loading integration_test/app_test.dart
Running Gradle task 'assembleDebug'...
√ Built build\app\outputs\flutter-apk\app-debug.apk
Installing build\app\outputs\flutter-apk\app-debug.apk...
00:00 +0: Alur utama end-to-end: Login -> Beranda -> Tambah Pengumuman -> Pencarian -> Detail -> Logout
00:15 +1: (tearDownAll)
00:15 +1: All tests passed!
```
Pengujian integrasi berhasil dijalankan secara nyata pada Android Emulator (`API 35`) tanpa kegagalan.
