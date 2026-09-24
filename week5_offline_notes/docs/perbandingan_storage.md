# Perbandingan Storage

## Tabel Perbandingan Final

| Kriteria | SharedPreferences | Hive | sqflite (SQLite) | Drift |
|---|---|---|---|---|
| Kompleksitas query | Sangat rendah | Rendah | Tinggi/fleksibel | Tinggi |
| Relasi antar data | Tidak cocok | Terbatas | Mendukung | Mendukung |
| Reactive Stream | Tidak | Terbatas | Tidak bawaan | Ya |
| Type-safety | Rendah | Cukup | Bergantung pada implementasi | Tinggi |
| Boilerplate | Sangat rendah | Rendah | Sedang | Tinggi |
| Testing | Mudah | Mudah | Baik | Baik |
| Cocok untuk preferensi | Ya | Ya | Tidak diperlukan | Tidak diperlukan |
| Cocok untuk notes | Tidak disarankan | Bisa | Ya | Ya |
| Dukungan query SQL | Tidak | Tidak | Ya | Abstraksi SQL |
| Cocok untuk 1000+ notes | Tidak | Bisa | Ya | Ya |

## Keputusan Final

### SharedPreferences untuk preferensi

SharedPreferences dipilih untuk menyimpan preferensi sederhana seperti:

- status dark mode
- waktu terakhir aplikasi dibuka

Data tersebut berbentuk key-value dan tidak membutuhkan query kompleks
maupun relasi antar data.

### SQLite/sqflite untuk catatan

SQLite melalui package sqflite dipilih untuk menyimpan catatan karena
catatan merupakan data koleksi yang dapat terus bertambah.

Database dapat melakukan:

- INSERT
- SELECT
- UPDATE
- DELETE
- sorting berdasarkan `updated_at`
- filtering berdasarkan `dirty`
- perhitungan jumlah data yang belum tersinkronisasi

Selain itu, struktur database dapat dikembangkan untuk kebutuhan
sinkronisasi.

## Kesimpulan

Kombinasi SharedPreferences + SQLite dipilih karena masing-masing storage
digunakan sesuai karakteristik datanya.

SharedPreferences digunakan untuk data preferensi sederhana, sedangkan
SQLite digunakan untuk data utama aplikasi yang memiliki banyak record
dan membutuhkan operasi database.

Keputusan ini juga sesuai dengan implementasi aplikasi Offline Notes
yang menggunakan SharedPreferences untuk preferensi dan SQLite untuk
notes serta cache posts.