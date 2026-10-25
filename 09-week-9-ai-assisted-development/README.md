# Week 9 — AI-Assisted Development

Mini project Campus Notify: pencarian judul pengumuman dengan filter
case-insensitive dan empty state.

## Fitur

- Mencari pengumuman berdasarkan judul.
- Pencarian tidak membedakan huruf besar/kecil.
- Query kosong menampilkan seluruh daftar.
- Tidak ada hasil menampilkan "Pengumuman tidak ditemukan".
- Filter diimplementasikan sebagai pure domain use case dan dipanggil oleh
  provider Riverpod.

Source Flutter berada di folder sibling [`../campus_notify`](../campus_notify).
Widget tidak memanggil Dio atau database. State daftar pengumuman pada versi
proyek ini masih in-memory; belum ada repository pengumuman yang dikarang untuk
mini project.

## Prompt dan hasil AI

- Prompt inti, konteks proyek, output awal, refleksi, dan catatan pengujian:
  [`docs/ai-log.md`](docs/ai-log.md).
- Prompt review, tiga temuan, tabel terima/tolak, dan bukti grep/test:
  [`docs/ai-challenge-search-review.md`](docs/ai-challenge-search-review.md).

Prompt inti meminta fitur search judul, pencocokan case-insensitive, hasil
kosong seluruh daftar, empty state, kepatuhan pada struktur feature-first,
tanpa perubahan auth/routing/notifikasi dan tanpa dependency baru. Konteks
menegaskan bahwa halaman daftar adalah `HomePage` dan pengumuman belum punya
repository/data source.

## Stack

- Flutter / Dart
- Riverpod untuk state
- GoRouter untuk routing aplikasi
- Dio dan Firebase Cloud Messaging pada aplikasi
- Tidak ada package baru untuk fitur search

## Cara menjalankan

Dari root repository:

```powershell
Set-Location .\campus_notify
flutter pub get
flutter run
```

## Verifikasi mesin

Dari folder `campus_notify`:

```powershell
flutter analyze
dart format --set-exit-if-changed .
flutter test
```

Hasil terakhir yang dijalankan:

- `flutter analyze` — No issues found.
- `dart format --set-exit-if-changed .` — 29 files, 0 changed.
- `flutter test` — All tests passed (20 tests).
- `flutter test test\search_filter_test.dart` — 5 tests passed (4 unit/use case
  tests dan 1 widget test empty state).
- Pencarian import domain untuk Flutter/Riverpod/Dio/SQLite tidak menemukan
  hasil.

## Uji manual dan screenshot

Pada emulator/perangkat, tambahkan beberapa pengumuman lalu uji query:

1. `UJIAN` — judul ujian yang cocok harus muncul.
2. `kuliah` — judul yang berisi kata kuliah harus muncul.
3. `beasiswa` — harus muncul empty state.

Ambil screenshot tiap hasil dan letakkan di [`screenshots/`](screenshots/).
Folder ini memiliki checklist; screenshot perangkat **belum diambil** dan
belum diklaim sebagai bukti pada pengumpulan ini.

## Refleksi singkat

- Kesalahan AI harus dibuktikan dengan source/test, bukan hanya diasumsikan dari
  prompt. Regression test membuktikan masalah sinkronisasi query Riverpod dan
  kolom input ketika halaman dibuat ulang.
- Prompt yang paling membantu menetapkan fitur, batas perubahan, dan struktur
  yang memang tersedia di repository.
- Filter direfactor dari presentation ke pure use case domain.
- Usulan memanggil SQLite/Dio saat mengetik ditolak karena repository
  announcements belum tersedia; I/O akan mengarang arsitektur dan tidak
  dibutuhkan oleh list in-memory saat ini.
