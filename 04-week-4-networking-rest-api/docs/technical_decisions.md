# Keputusan Teknis

## 1. Architecure choice

Project ini memakai pattern repository + provider. UI hanya membaca state, sementara repository yang menangani akses API. Desain ini membuat kode lebih rapi, lebih mudah diuji, dan terhindar dari logic network yang tercampur di widget.

## 2. Dio sebagai HTTP client utama

Semua konfigurasi HTTP disimpan di satu file, yaitu `api_client.dart`. Hal ini memastikan base URL, timeout, dan logging konsisten di seluruh aplikasi.

## 3. Safe null parsing

Model `Post.fromJson` menggunakan `Map<String, dynamic>?` dan fallback default untuk field yang tidak ada. Teknik ini menghindari crash ketika API mengembalikan JSON yang tidak lengkap.

## 4. Pagination guard

`PagedPostsNotifier` menyimpan status request aktif agar tidak terjadi double fetch pada saat scroll terus bergerak atau saat tombol retry dipencet berulang. Ini penting agar data tidak duplikat dan request tidak tumpang tindih.

## 5. State handling

Aplikasi membedakan state loading, error, empty, dan success secara eksplisit. Keputusan ini memperjelas pengalaman pengguna dan memudahkan pengujian.

## 6. Testing strategy

Minimal dua jenis pengujian dipilih:

- unit test untuk model safe parsing dan mapping error
- provider test dengan repository palsu agar state provider bisa diuji tanpa jaringan sebenarnya

Ini memberi validasi yang cukup tanpa menambah kompleksitas yang tidak diperlukan.
