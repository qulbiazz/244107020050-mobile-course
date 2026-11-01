# Uji kirim pertama dari Firebase Console
1. Buka Firebase Console -> Messaging -> buat campaign notifikasi percobaan.
2. Masukkan title dan body, targetkan aplikasi Android Anda.
3. Kirim saat aplikasi dalam state background: banner sistem harus muncul. Klik banner: aplikasi terbuka.
5. Catat hasilnya sebagai bukti screenshots/fcm-console-test.png.
[!hasil screenshots](screenshots/fcm-console-test.png)
[!hasil screenshots](screenshots/02-foreground-notification.png)
[!hasil screenshots](screenshots/03-background-notification.png)
[!hasil screenshots](screenshots/04-terminated-notification.png)
[!hasil screenshots](screenshots/05-topic-notification.png)

# Checklist verifikasi mandiri
1. Token hanya di flutter_secure_storage, tidak di SharedPreferences/log/screenshot penuh.✅
2. 401 memicu refresh sekali lalu retry; refresh mati memaksa login ulang.✅
3. Ketiga app state teruji dengan tabel bukti; klik masuk ke rute yang benar.✅
4. Topik untuk broadcast, token untuk pesan personal.✅
5. flutter analyze bersih dan semua test lulus.
# Refleksi
1. Mengapa refresh token tidak boleh disimpan di SharedPreferences? Apa risikonya bila bocor?
SharedPreferences digunakan untuk penyimpanan data sederhana dan bukan dirancang sebagai tempat penyimpanan rahasia. Refresh token memiliki umur yang lebih panjang dan dapat digunakan untuk mendapatkan access token baru. Jika refresh token bocor, pihak lain berpotensi mempertahankan akses ke akun sampai token tersebut tidak berlaku atau dicabut.

Karena itu, project menggunakan flutter_secure_storage untuk menyimpan access token dan refresh token.

2. Apa yang rusak bila onTokenRefresh diabaikan selama satu semester perkuliahan?
FCM token dapat berubah. Jika aplikasi tidak mengirim token baru ke backend, backend dapat terus menggunakan token lama sehingga notification tidak lagi sampai ke perangkat tersebut.

Karena itu project menggunakan:
FirebaseMessaging.instance.onTokenRefresh.listen(...)
untuk mendeteksi token baru dan mengirimkannya kembali ke endpoint device.

3. Kapan memakai topik dan kapan memakai token perangkat? Beri contoh pesan kampus untuk masing-masing.
Topic digunakan untuk broadcast.
Contoh:
Topic:
pengumuman-kampus
Pesan:
Besok perkuliahan dilaksanakan secara daring.
Pesan tersebut dapat diterima oleh seluruh perangkat yang subscribe.
Sedangkan token perangkat digunakan untuk pesan yang ditujukan kepada perangkat/user tertentu.
Contoh:
Notifikasi personal:
Nilai UTS Anda telah tersedia.
Untuk informasi personal seperti nilai atau tagihan, token perangkat lebih sesuai daripada topic.

4. Bagian mana dari draf AI yang Anda tolak atau perbaiki, dan mengapa?
Bagian yang perlu diperiksa dan diperbaiki adalah lifecycle notification dan keamanan token. Implementasi akhir menggunakan background handler top-level, @pragma('vm:entry-point'), foreground local notification, onMessageOpenedApp, getInitialMessage, parsing data.route, serta onTokenRefresh.

Selain itu, token tidak seharusnya dicetak secara penuh pada log atau dimasukkan ke screenshot dokumentasi.

---

# Praktikum 10 — Integrasi Fitur AI

## Fitur yang diintegrasikan

Campus Notify menyediakan Asisten Kampus dengan streaming jawaban AI,
pemindaian OCR lokal dari kamera/galeri, input suara offline Bahasa Indonesia,
dan deskripsi gambar setelah pemeriksaan privasi serta persetujuan pengguna.
Inisialisasi Firebase/FCM berjalan setelah layar aplikasi tampil; jika push
notification gagal disiapkan, aplikasi tetap dapat digunakan dan menampilkan
peringatan beserta opsi untuk mencoba lagi.

### Persiapan

1. Jalankan `flutter pub get`.
2. Sediakan Gemini API key melalui mekanisme aman aplikasi:
   `AiService.saveApiKey(key)`. Jangan menaruh key di source code, README,
   log, atau screenshot.
3. Buka Asisten Kampus dari ikon chat di halaman utama. Input AI hanya untuk
   informasi umum; jangan gunakan NIK, nomor telepon, alamat, atau data sensitif.

## Bukti mesin hijau

Jalankan dari root proyek (folder yang berisi `pubspec.yaml`):

```powershell
flutter analyze
flutter test
```

Hasil verifikasi terakhir:

| Perintah | Hasil |
|---|---|
| `flutter analyze` | Lulus — No issues found |
| `flutter test` | Lulus — 30 test |
| `flutter build apk --debug` | Lulus |

## Risiko dan mitigasi

| Risiko | Mitigasi |
|---|---|
| Data pribadi terkirim ke AI | Prompt teks diperiksa sebelum request. OCR dan deteksi wajah berjalan lokal; gambar dengan teks pribadi atau wajah ditahan. Unggah gambar memerlukan konfirmasi. |
| Biaya AI meningkat | Maksimal 20 request per akun per hari pada perangkat; cache lokal berlaku 24 jam dan cache hit tidak memanggil API. |
| API key atau prompt bocor lewat cache | API key disimpan menggunakan `flutter_secure_storage`; cache hanya menyimpan hash request dan jawaban terbatas, bukan prompt. Cache per akun dibersihkan saat logout. |
| API gagal atau kuota habis | Tampilkan pesan dan fallback ke pengumuman kampus lokal yang relevan; tersedia tombol coba lagi. |
| Jawaban tidak relevan | Validasi jawaban terhadap prompt; bila tidak lolos, tampilkan fallback lokal dan jangan simpan jawaban itu di cache. |

> Batas 20 request ditegakkan di penyimpanan lokal perangkat. Produksi perlu
> menerapkan kuota otoritatif lintas perangkat di backend.

## Refleksi

1. **Fitur AI dan alasan:** Asisten chat dipilih karena cocok untuk pertanyaan
   umum kampus; OCR lokal membantu membaca pengumuman tanpa mengunggah dokumen.
   Input suara memudahkan aksesibilitas dan input cepat.
2. **Privasi:** NIK, nomor telepon, alamat, dan pola sensitif ditolak sebelum
   request teks. OCR serta pengenalan wajah dijalankan di perangkat. Audio
   dikenali offline. Gambar hanya diunggah setelah konfirmasi dan pemeriksaan.
3. **Fallback:** saat AI error, kuota tercapai, atau jawaban tidak relevan, chat
   menampilkan pengumuman lokal yang cocok dan opsi mencoba AI kembali.
4. **Pelajaran UX:** pengguna perlu tahu dengan jelas kapan data diproses lokal
   dan kapan akan meninggalkan perangkat; minta persetujuan tepat sebelum
   unggah dan tampilkan jalur offline yang tetap berguna.

Log prompt sistem, user prompt, dan output awal AI ada di
[`docs/ai-log.md`](docs/ai-log.md). Bukti visual disimpan di
[`screenshots/`](screenshots/).


# WEEK 7 CLEAN ARCHITECTUR

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

# Dokumentasi AI Challenge — Campus Notify

Folder ini berisi dokumentasi evaluasi AI Challenge untuk penerapan Clean Architecture pada aplikasi Campus Notify.

## Isi Dokumentasi

- `AI_CHALLENGE.md`: prompt AI, usulan struktur folder, pemetaan file, dan wiring Riverpod.
- `DECISION_TABLE.md`: perbandingan usulan AI dan keputusan teknis final.
- `VERIFICATION.md`: perintah grep dan hasil verifikasi arsitektur.

## Checklist Sebelum Demo

- [✓] Repository interface berada di domain.
- [✓] Repository implementation berada di data.
- [✓] Domain tidak mengimpor Flutter, Dio, SQLite, atau Firebase.
- [✓] Entity tidak menangani serialisasi API.
- [✓] UI tidak memanggil Dio secara langsung.
- [✓] Wiring dependency menggunakan Riverpod.
- [✓] Keputusan mengenai use case didokumentasikan.
- [✓] Hasil tiga grep dicatat berdasarkan output aktual.
- [✓] `flutter analyze` telah dijalankan.
- [✓] Hasil `flutter test` dicatat secara jujur.
[!hasil screenshots](screenshots/week7_flutter-analyze.png)

[!hasil screenshots](screenshots/)
[!hasil screenshots](screenshots/week7_flutter-analyze.png)
[!hasil screenshots](screenshots/week7_flutter-analyze.png)

## Praktikum 3 — Profiling Flutter DevTools

Profiling dilakukan pada Android Emulator dalam `--profile` mode. Sesi
Performance menunjukkan 53 FPS rata-rata; pengukuran frame singkat setelah
interaksi chat mencatat 34 frame dengan 10 janky frames (29.41%). Snapshot
memori proses mencatat PSS 201,412 KB dan RSS 351,228 KB. Karena pengukuran
dilakukan di emulator dan mencakup interaksi UI, hasil ini bersifat eksploratif,
bukan baseline produksi.

Laporan metode, hasil CPU sampling, batasan pengukuran, dan bukti:
[`docs/flutter-devtools-profiling.md`](docs/flutter-devtools-profiling.md).

## Praktikum 7 — Optimasi Performa

Perubahan pada daftar pengumuman mempersempit cakupan rebuild, menambahkan
`select` untuk status empty-state, memisahkan repaint kontrol pencarian, dan
meniadakan keep-alive baris stateless. Baseline dan post-optimasi tersedia di
[`docs/performance-report.md`](docs/performance-report.md). Verifikasi setelah
perubahan: `flutter analyze` lulus (`No issues found`) dan `flutter test` lulus
(30 test). Metrik emulator belum membuktikan peningkatan jank; laporan
mendokumentasikan temuan, refleksi, dan keterbatasan pengukuran.
