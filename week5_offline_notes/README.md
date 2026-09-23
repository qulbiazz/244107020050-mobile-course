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