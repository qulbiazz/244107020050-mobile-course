# Mid-Semester Review Checklist

## 1. Arsitektur dan Struktur Kode
- [✓] Struktur kode menggunakan pendekatan feature-first.
- [✓] Feature `auth` dan `notes` memiliki pemisahan layer yang sesuai.
- [✓] Domain entity tidak bergantung pada Flutter, Dio, SQLite, atau Firebase.
- [✓] Entity tidak menangani serialisasi data secara langsung.
- [✓] Wiring Riverpod dan dependency berada pada layer yang sesuai.
- [✓] Tiga pemeriksaan grep Minggu 7 sudah dijalankan dan hasilnya sesuai dengan aturan arsitektur.
- [✓] Hasil pemeriksaan dicatat di `docs/VERIFICATION.md`.

## 2. Pemeriksaan Otomatis
- [✓] `flutter analyze` berhasil tanpa masalah.
- [✓] `flutter test` berhasil untuk seluruh test.
- [✓] CI GitHub Actions berjalan dan seluruh pemeriksaan wajib berhasil.

## 3. Git dan Pull Request
- [✓] Perubahan fitur dibuat dalam branch terpisah.
- [✓] Commit memiliki pesan yang jelas dan sesuai perubahan.
- [✓] Minimal satu PR kecil per pasangan sudah di-merge melalui proses review.
- [✓] Semua komentar review sudah ditindaklanjuti.

## 4. Dokumentasi
- [✓] README menjelaskan tujuan dan fitur aplikasi.
- [✓] README memiliki peta struktur project.
- [✓] README memiliki petunjuk instalasi dan menjalankan aplikasi.
- [✓] README menyertakan screenshot aplikasi.
- [✓] README mencantumkan status paruh semester.
- [✓] README mencantumkan peta issue dan PR.

## 5. Validasi Akhir
- [✓] Aplikasi berjalan sesuai kondisi akhir Minggu 7.
- [✓] Tidak ada regresi fungsi setelah perubahan.
- [✓] Bukti pemeriksaan, pengujian, dan review tersedia.

## Status Mid Review
- Status: Belum diverifikasi
- Tanggal pemeriksaan: —
- Catatan atau kendala: —


## DOKUEMENTASI
- [Screenshots](../week8_docs/screenshots/grep_test.png)
- [Screenshots](../week8_docs/screenshots/flutter_analyze_dan_flutter_test.png)
