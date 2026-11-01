# WEEK 7 — Dokumentasi AI Challenge: Campus Notify

Dokumentasi ini berisi hasil evaluasi penerapan **Clean Architecture** pada aplikasi Campus Notify, meliputi usulan AI, keputusan arsitektur, serta verifikasi struktur kode menggunakan perintah `grep`, `flutter analyze`, dan `flutter test`.

## 1. Isi Dokumentasi

| File | Deskripsi |
|---|---|
| `AI_CHALLENGE.md` | Prompt AI, usulan struktur folder, pemetaan file, dan wiring Riverpod. |
| `DECISION_TABLE.md` | Perbandingan usulan AI dengan keputusan teknis final. |
| `VERIFICATION.md` | Perintah grep dan hasil verifikasi arsitektur. |

## 2. Checklist Verifikasi

- [x] Interface repository berada di domain.
- [x] Implementasi repository berada di data.
- [x] Domain tidak mengimpor Flutter, Dio, SQLite, atau Firebase.
- [x] Entity tidak menangani serialisasi API.
- [x] UI tidak memanggil Dio secara langsung.
- [x] Dependency injection menggunakan Riverpod.
- [x] Keputusan penggunaan use case telah didokumentasikan.
- [x] Hasil tiga perintah grep telah dicatat berdasarkan output aktual.
- [x] `flutter analyze` telah dijalankan.
- [x] Hasil `flutter test` telah dicatat sesuai hasil pengujian.

## 3. Dokumentasi dan Hasil Pengujian

### Screenshot

- [Hasil Flutter Analyze](screenshots/week7_flutter-analyze.png)
- [Struktur Folder Project](screenshots/week7_struktur-folder.png)
- [Tampilan Aplikasi Android](screenshots/week7_tampilan-android.png)

### Dokumen Pendukung

- [AI Challenge](docs/AI_CHALLENGE.md)
- [Decision Table](docs/DECISION_TABLE.md)
- [Verification](docs/VERIFICATION.md)

## 4. Refleksi AI Challenge

### 4.1 Mengapa interface repository harus berada di domain, bukan di data? Apa yang rusak bila dibalik?

Interface repository berada di domain agar aturan bisnis tidak bergantung pada teknologi penyimpanan data. Jika diletakkan di data, domain berisiko bergantung pada implementasi teknis sehingga lebih sulit diuji dan dikembangkan.

### 4.2 Kapan use case benar-benar dibutuhkan, dan kapan repository langsung ke notifier sudah cukup?

Use case dibutuhkan ketika terdapat aturan bisnis kompleks atau proses yang melibatkan beberapa repository. Untuk operasi CRUD sederhana, notifier dapat langsung memanggil repository agar kode lebih praktis.

### 4.3 Apa biaya over-engineering berupa use case untuk setiap CRUD satu baris bagi tim kecil? Kapan biayanya sepadan?

Biayanya meliputi bertambahnya jumlah file, alur kode yang lebih panjang, dan pemeliharaan yang lebih rumit. Use case sepadan jika logika bisnis kompleks, digunakan berulang, atau membutuhkan pengujian terpisah.

### 4.4 Bagian mana dari usulan AI yang ditolak atau disederhanakan, dan mengapa?

Penggunaan use case untuk setiap operasi CRUD sederhana disederhanakan menjadi pemanggilan repository langsung melalui notifier. Tujuannya menghindari kompleksitas yang tidak diperlukan, sedangkan pemisahan domain dan data serta penggunaan Riverpod tetap dipertahankan.

## 5. Kesimpulan

Penerapan Clean Architecture pada Campus Notify bertujuan memisahkan tanggung jawab setiap layer agar kode lebih terstruktur, mudah diuji, dan mudah dikembangkan. Usulan AI dievaluasi berdasarkan kebutuhan proyek, sehingga abstraksi yang tidak memberikan manfaat nyata dapat disederhanakan tanpa mengabaikan prinsip arsitektur utama.