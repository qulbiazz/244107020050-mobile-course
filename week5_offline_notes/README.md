3. Simulasi offline yang deterministik
Selain mode pesawat sungguhan, sediakan toggle forceOffline pada provider agar demo dan testing tidak bergantung pada kondisi Wi-Fi kelas:

- Matikan Wi-Fi / aktifkan mode pesawat, buka kembali aplikasi: catatan tetap tampil, badge dirty tetap akurat.
- Nyalakan kembali koneksi, jalankan syncNotes: badge kembali ke 0.
- Tuliskan langkah dan hasil observasi Anda (screenshot sebelum/sesudah) ke folder screenshots/


# Hasil Observasi Praktikum 3
## Cache-first dan Antrean Sync

### 1. Pengujian Cache-first

#### Langkah
1. Jalankan aplikasi dalam kondisi koneksi aktif.
2. Aplikasi mengambil data posts dari API JSONPlaceholder.
3. Data dari API disimpan ke database SQLite pada tabel `cached_posts`.
4. Matikan koneksi atau aktifkan `Force Offline`.
5. Buka kembali halaman posts.
6. Amati data yang ditampilkan.

#### Hasil Observasi
Data posts tetap dapat ditampilkan meskipun koneksi internet tidak tersedia.
Data yang ditampilkan berasal dari cache SQLite.

Screenshot:
- [screenchots](screenshots/01-cache-offline.png)

---

### 2. Pengujian Dirty Notes

#### Langkah
1. Aktifkan `Force Offline`.
2. Tambahkan sebuah catatan baru.
3. Periksa badge jumlah dirty.
4. Catatan akan disimpan ke SQLite dengan nilai `dirty = 1`.

#### Hasil Observasi
Catatan tetap tersimpan dan dapat ditampilkan ketika aplikasi dalam kondisi
offline. Badge dirty menunjukkan jumlah catatan yang belum disinkronkan.

Screenshot:
-  [screenchots](screenshots/02-cache-online.png)

---

### 3. Pengujian Sinkronisasi

#### Langkah
1. Pastikan terdapat catatan dengan status `dirty`.
2. Matikan `Force Offline` untuk mengaktifkan kembali koneksi.
3. Tekan tombol `Sync`.
4. Sistem menjalankan fungsi `syncNotes()`.
5. Sistem menghitung jumlah data dirty.
6. Sistem melakukan simulasi upload selama 1 detik.
7. Data dirty ditandai sebagai sudah tersinkronisasi.
8. Badge dirty diperbarui.

#### Hasil Observasi
Sebelum sinkronisasi, badge menunjukkan jumlah catatan yang masih dirty.
Setelah proses sinkronisasi selesai, badge berubah menjadi `0`.

Screenshot:
-  [screenchots](screenshots/03-dirty-note-offline.png)

---

## Kesimpulan

Implementasi cache-first berhasil membuat data tetap dapat ditampilkan dari
SQLite ketika aplikasi berada dalam kondisi offline.

Data catatan yang dibuat ketika offline ditandai sebagai dirty dan tetap
tersimpan secara lokal. Setelah koneksi kembali aktif, proses `syncNotes()`
dapat menjalankan sinkronisasi dan mengubah status data menjadi synced,
sehingga jumlah dirty pada badge kembali menjadi `0`.




---

# 5. `docs/README.md`

Ini bisa menjadi halaman utama dokumentasi:

```markdown
# AI Challenge - Offline Notes

## Tujuan

Membandingkan beberapa pilihan local storage untuk aplikasi Flutter
Offline Notes dan menentukan storage yang sesuai berdasarkan kebutuhan
aplikasi.

## Storage yang dibandingkan

1. SharedPreferences
2. Hive
3. sqflite (SQLite)
4. Drift

## Dokumentasi

- `ai_prompt.txt` → prompt yang digunakan untuk AI
- `ai_output_awal.md` → output awal AI
- `perbandingan_storage.md` → perbandingan dan keputusan final
- `ai_verification.md` → hasil verifikasi dan testing

## Keputusan

| Kebutuhan | Storage | Alasan |
|---|---|---|
| Preferensi tema | SharedPreferences | Data sederhana key-value |
| Waktu terakhir dibuka | SharedPreferences | Data sederhana key-value |
| Catatan | SQLite/sqflite | Mendukung koleksi, query, CRUD |
| Status sync | SQLite/sqflite | Dapat menggunakan `dirty` |
| Cache posts | SQLite/sqflite | Data koleksi yang perlu disimpan lokal |

## AI Verification Checklist

- [✓] **Apakah AI menempatkan daftar catatan di SharedPreferences?**  
  Tidak. SharedPreferences digunakan untuk menyimpan preferensi sederhana
  seperti `dark_mode` dan `last_opened_at`. Daftar catatan menggunakan SQLite
  karena lebih sesuai untuk koleksi data.

- [✓] **Apakah skema AI mendukung antrean sync (`dirty` flag / `updated_at`)?**  
  Ya. Skema notes menggunakan `dirty` untuk menandai catatan yang belum
  disinkronkan dan `updated_at` untuk mencatat waktu perubahan.

- [✓] **Apakah klaim "real-time" AI didukung stream (Drift/watch) atau hanya asumsi?**  
  Pada implementasi ini tidak menggunakan Stream. Perubahan data diperbarui
  dengan melakukan invalidate pada Riverpod provider. Drift memiliki dukungan
  reactive query/watch, tetapi tidak digunakan dalam implementasi ini.

- [✓] **Apakah estimasi boilerplate AI masuk akal setelah mencoba instalasi
  (`flutter pub add` + migrasi skema)?**  
  Ya. SharedPreferences memiliki boilerplate yang lebih sedikit, sedangkan
  SQLite membutuhkan konfigurasi database, model, repository, schema, dan
  migrasi ketika terjadi perubahan struktur database.

- [✓] **Keputusan final dan alasan**  
  SharedPreferences dipilih untuk preferensi aplikasi karena datanya sederhana
  dan berbentuk key-value. SQLite/sqflite dipilih untuk catatan dan cache karena
  mendukung CRUD, query, banyak record, serta kebutuhan sinkronisasi melalui
  `dirty` dan `updated_at`.



# Checklist verifikasi mandiri
- UI tidak memanggil SQLite/SharedPreferences langsung; semua lewat repository + provider. [✓]
- Aplikasi penuh berfungsi dalam mode pesawat: baca, tambah, hapus catatan. [✓]
- Badge dirty akurat sebelum/sesudah sync; cache posts tampil tanpa internet. [✓]
- flutter analyze tanpa issue dan semua test lulus. [✓]
- Hasil AI diverifikasi dan didokumentasikan pada folder docs/. [✓]


# Refleksi
1. Mengapa daftar catatan tidak boleh disimpan di SharedPreferences? Apa yang rusak jika aturan ini dilanggar?
-> SharedPreferences lebih cocok untuk menyimpan data sederhana dalam bentuk key-value, seperti preferensi tema atau waktu terakhir aplikasi dibuka. Daftar catatan merupakan kumpulan data yang membutuhkan operasi CRUD, pencarian, sorting, dan penyimpanan dalam jumlah banyak, sehingga lebih sesuai menggunakan SQLite.

Jika daftar catatan dipaksakan disimpan di SharedPreferences, seluruh daftar harus diserialisasi menjadi satu data, misalnya JSON. Setiap ada perubahan pada satu catatan, data tersebut harus dibaca dan ditulis kembali. Hal ini membuat pengelolaan data menjadi lebih rumit, kurang efisien, dan sulit dikembangkan ketika jumlah catatan semakin banyak. Fitur seperti query berdasarkan updated_at atau dirty juga menjadi sulit dilakukan.

2. Kapan cache-first cukup, dan kapan Anda membutuhkan strategi lain (misalnya network-first untuk data harga real-time)?
-> Cache-first cukup ketika aplikasi lebih mengutamakan ketersediaan data daripada data yang harus selalu paling baru. Contohnya pada aplikasi Offline Notes. Pengguna tetap dapat melihat catatan dari database lokal walaupun tidak memiliki koneksi internet. Data kemudian dapat diperbarui di background ketika koneksi tersedia.

3. Bagaimana dirty flag berubah menjadi antrean sync tanpa memblokir UI? Kapan antrean terpisah (tabel outbox) menjadi perlu?
-> Pada aplikasi ini, ketika catatan dibuat atau diubah secara offline, catatan disimpan terlebih dahulu ke SQLite dengan:

dirty = 1

Kemudian UI tetap menggunakan data lokal sehingga tidak perlu menunggu server. Ketika koneksi kembali tersedia, aplikasi mencari catatan dengan dirty = 1, menjalankan proses sinkronisasi di asynchronous operation, lalu mengubahnya menjadi:

dirty = 0

4. Bagian mana dari rekomendasi AI yang Anda tolak, dan mengapa?
-> Saya tidak menolak penggunaan SharedPreferences dan SQLite secara keseluruhan karena hasil implementasi menunjukkan bahwa keduanya sesuai dengan kebutuhan aplikasi.

Bagian yang saya koreksi adalah anggapan bahwa semua storage dapat digunakan secara setara untuk data catatan. SharedPreferences memang dapat menyimpan data dalam bentuk string atau JSON, tetapi tidak tepat digunakan untuk daftar catatan yang membutuhkan operasi CRUD dan query.