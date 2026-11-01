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