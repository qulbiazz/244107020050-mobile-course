# AI Challenge Documentation

## Prompt yang diberikan

Prompt yang dipakai untuk membangun arsitektur awal aplikasi adalah:

> Buatkan aplikasi Flutter sederhana yang mengambil data dari JSONPlaceholder /posts, menggunakan repository + Riverpod, Dio terpusat dengan timeout dan logging, serta UI dengan empat state loading/error/empty/success. Tambahkan pagination 10 item per halaman dan guard request ganda. Sertakan test unit dan provider. Tulis dokumentasi AI challenge di docs/.

## Hasil AI awal

Hasil awal dari AI sudah menghasilkan struktur dasar proyek, repository, provider, dan halaman UI. Namun beberapa hal masih perlu disempurnakan agar sesuai kebutuhan tugas, seperti:

- widget test masih memakai template bawaan counter
- notifikasi error belum konsisten dengan state pager
- UI belum sepenuhnya merepresentasikan semua state yang diminta
- dokumentasi AI challenge dan keputusan teknis belum lengkap

## Perbaikan yang dilakukan

1. Menyempurnakan model `Post.fromJson` agar aman terhadap null dan field yang hilang.
2. Menetapkan `Dio` terpusat pada `api_client.dart` dengan `baseUrl`, `timeout`, dan `LogInterceptor`.
3. Memperbaiki `PagedPostsNotifier` agar request pertama dan berikutnya dilindungi dari duplikasi saat loading.
4. Menyusun state UI yang jelas untuk loading, error, empty, dan success dengan tombol retry pada error.
5. Menggantikan test default Flutter counter dengan test yang relevan untuk model dan provider.
6. Menambahkan dokumentasi AI challenge serta keputusan teknis di folder docs/.

## Alasan keputusan teknis

- Repository dipakai agar UI tidak langsung mengakses Dio. Ini menjaga pemisahan concern dan memudahkan testing.
- Riverpod dipilih karena cocok untuk state management async dan dependency injection yang sederhana.
- Pagination dibuat dengan page-based request dan guard `_isRequestInFlight` untuk mencegah request ganda saat user scroll cepat.
- Safe parsing `fromJson` penting agar aplikasi tidak crash bila response API mengirim field yang null atau tidak lengkap.
- Interceptor logging dipusatkan agar semua request dapat diawasi dengan satu konfigurasi.
