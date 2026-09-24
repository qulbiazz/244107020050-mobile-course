# Output Awal AI

## Perbandingan Storage

| Kriteria | SharedPreferences | Hive | sqflite (SQLite) | Drift |
|---|---|---|---|---|
| Kompleksitas query | Sangat terbatas | Rendah | Tinggi dan fleksibel | Tinggi tetapi lebih terstruktur |
| Kebutuhan relasi | Tidak cocok | Terbatas | Sangat baik | Sangat baik |
| Reaktivitas / Stream | Tidak tersedia secara native | Terbatas | Tidak native | Sangat baik |
| Type-safety | Rendah | Cukup | Rendah pada raw SQL | Tinggi |
| Boilerplate | Sangat sedikit | Sedikit | Sedang | Lebih banyak |
| Kemudahan testing | Mudah | Mudah | Baik | Baik |
| Cocok untuk preferensi | Sangat cocok | Bisa | Overkill | Overkill |
| Cocok untuk banyak catatan | Tidak cocok | Bisa | Sangat cocok | Sangat cocok |

## Rekomendasi AI

Untuk preferensi aplikasi seperti dark mode, SharedPreferences sesuai
karena data yang disimpan sederhana berupa pasangan key-value.

Untuk data catatan, SQLite/sqflite atau Drift lebih sesuai karena catatan
merupakan koleksi data yang membutuhkan query, filtering, sorting, dan
dapat dikembangkan dengan relasi.

Jika aplikasi membutuhkan reactive query dan type-safety yang kuat, Drift
menjadi alternatif yang menarik. Namun, untuk aplikasi pembelajaran dengan
kebutuhan SQL yang relatif sederhana, sqflite lebih mudah digunakan dan
lebih langsung memahami konsep database SQLite.