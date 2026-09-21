# Week 4 - Networking REST API

Aplikasi Flutter ini menampilkan daftar posting dari JSONPlaceholder melalui arsitektur repository + Riverpod dengan pagination dasar, handling loading/error/empty/success, dan integrasi Dio yang terpusat.

## Tujuan

Proyek ini dibuat untuk memenuhi tugas minggu ke-4 dalam materi Pemrograman Mobile tentang networking, REST API, state management, dan testing. Fokus utamanya adalah:

- mengambil data dari API publik tanpa key
- memisahkan akses data dari UI melalui repository
- mengelola state menggunakan Riverpod
- menerapkan pagination infinite scroll
- menyiapkan dokumentasi AI challenge dan hasil evaluasi

## Fitur utama

- Data dari JSONPlaceholder `/posts`
- Repository pattern untuk data access
- Dio dengan base URL, timeout, dan interceptor logging
- Model `Post.fromJson` yang aman terhadap null
- State: loading, error + retry, empty, dan success
- Infinite scroll 10 item per halaman
- Guard anti-request ganda saat pagination berjalan
- Test unit/provider yang relevan

## Stack teknologi

- Flutter
- Dart
- Dio
- Riverpod
- Go Router

## Struktur proyek

- lib/
- test/
- docs/
- screenshots/
- README.md

## Cara menjalankan

```bash
cd "d:/Kuliah/Kelas/Semester 5/Pemrograman Mobile/TUGAS/244107020050-mobile-course/04-week-4-networking-rest-api"
flutter pub get
flutter run
```

## Hasil yang dicapai

- UI menampilkan daftar post dari API publik
- Aplikasi siap menangani kondisi error dan retry
- Paging terbatas pada 10 item per request dan mencegah request duplikat
- Dapat diuji secara otomatis dengan unit dan provider test
- Dokumentasi AI challenge tersedia di folder docs/

## Dokumentasi tambahan

- [docs/ai_challenge.md](docs/ai_challenge.md)
- [docs/ai_prompt.md](docs/ai_prompt.md)
- [docs/technical_decisions.md](docs/technical_decisions.md)
- [docs/verification.md](docs/verification.md)