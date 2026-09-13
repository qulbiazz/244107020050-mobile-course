# Praktikum 3 — Uji ketiga state
1. Salin kode di atas ke project ToDo Anda (atau project terpisah) dan jalankan. Amati tampilan loading selama 2 detik pertama.

Aplikasi menampilkan loading terlebih dahulu, kemudian menampilkan daftar data setelah proses pemuatan selesai.

2. Ubah build() sementara untuk melempar error: throw Exception('Gagal terhubung ke server');. Jalankan dan amati UI error beserta tombol Coba lagi.

State error digunakan untuk memberikan informasi kepada pengguna bahwa data gagal dimuat dan menyediakan pilihan untuk mencoba kembali.

3. Tekan tombol Coba lagi, ref.invalidate membuat provider dijalankan ulang. Pulihkan kode, pastikan state success tampil.

ref.invalidate() dapat digunakan untuk memicu provider agar melakukan proses pemuatan ulang dari awal.

4. Refleksikan: mengapa menampilkan ulang data lama (stale data) dengan indikator refresh kadang lebih baik daripada mengosongkan layar? Kapan pola itu penting?

Menampilkan data lama (stale data) dengan indikator refresh terkadang lebih baik daripada mengosongkan layar karena pengguna masih dapat melihat informasi yang sebelumnya sudah tersedia selama data baru sedang dimuat.
Pola stale data penting ketika proses pemuatan data membutuhkan waktu, koneksi internet tidak stabil, atau data sebelumnya masih cukup relevan untuk digunakan sementara. Contohnya pada aplikasi berita, dashboard, media sosial, atau daftar transaksi.