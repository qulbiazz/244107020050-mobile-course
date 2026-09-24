# AI Verification Checklist

## 1. Apakah AI menempatkan daftar catatan di SharedPreferences?

### Hasil
Tidak.

SharedPreferences digunakan untuk data sederhana berupa key-value,
seperti:

- `dark_mode`
- `last_opened_at`

Daftar catatan tidak disimpan di SharedPreferences.

### Alasan

Menyimpan daftar catatan dalam SharedPreferences akan membuat pengelolaan
koleksi menjadi kurang sesuai. Data harus diserialisasi menjadi string
atau JSON dan kemudian dibaca serta ditulis kembali ketika terjadi
perubahan.

SQLite lebih sesuai karena setiap catatan dapat disimpan sebagai record
tersendiri dan dapat dicari menggunakan query.

### Verifikasi pada implementasi

Preferensi:

```dart
prefs.getBool('dark_mode');
prefs.setBool('dark_mode', value);