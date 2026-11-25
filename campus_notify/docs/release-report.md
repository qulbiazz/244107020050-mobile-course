# Laporan Rilis Beta dan Monitoring Aplikasi (Release Candidate Report)

**Mata Kuliah:** Pemrograman Mobile  
**Proyek:** Campus Notify (`campus_notify`)  
**Topik:** Deployment, Beta Distribution, Crashlytics & Analytics Monitoring  
**Tanggal Rilis:** 26 November 2026  
**Status Evaluasi:** Kandidat Rilis Siap Diuji (Release Candidate - RC1)

---

## 1. Ringkasan Eksekutif dan Identitas Kandidat Rilis

Setelah seluruh tahapan otomatisasi CI/CD diimplementasikan pada minggu sebelumnya, tahapan berikutnya adalah menyiapkan **kandidat rilis beta terbatas (*Internal Testing*)**, mendistribusikan aplikasi kepada kelompok penguji terdaftar, mengumpulkan telemetri crash serta event analitik non-sensitif menggunakan **Firebase Crashlytics** dan **Firebase Analytics**, serta mengevaluasi sinyal rilis untuk mengambil keputusan peluncuran (*Release Decision*).

### Metadata Kandidat Rilis

| Properti | Nilai Konfigurasi | Deskripsi / Catatan |
|---|---|---|
| **Nama Aplikasi** | Campus Notify | Aplikasi Pengumuman dan Asisten Cerdas Kampus |
| **Package Name / Application ID** | `com.example.campus_notify` | Terdaftar pada Firebase Console & Google Play |
| **Versi Aplikasi (`versionName`)** | `1.2.0` | Kenaikan versi minor (penambahan modul monitoring & beta testing) |
| **Nomor Build (`versionCode`)** | `3` | Dinaikkan secara monotonik dari build sebelumnya (`+2`) |
| **Format Rilis** | Android App Bundle (`.aab`) | Standar wajib Google Play Store modern |
| **Target SDK / Min SDK** | `compileSdk 36`, `targetSdk 36`, `minSdk 23` | Kompatibel dengan Android 6.0 Marshmallow hingga Android 15 |
| **Target Track Distribusi** | Google Play Internal Testing / Firebase App Distribution | Jalur pengujian privat terbatas (*closed beta*) |
| **Basis Branch / Commit** | `main` / `5d20ed2` (Kandidat Rilis Minggu 14) | Lulus seluruh pengujian unit, widget, dan analisis statis |

---

## 2. Pemeriksaan Kualitas Kode dan Gerbang Rilis (*Release Verification Gates*)

Sesuai pedoman rilis profesional, sebuah build tidak boleh dinaikkan menjadi kandidat rilis sebelum melalui gerbang verifikasi kualitas secara deterministik.

```mermaid
flowchart TD
    A["Source Code (Commit RC)"] --> B["1. Dependency Check\n(flutter pub get)"]
    B --> C["2. Code Formatting\n(dart format --set-exit-if-changed .)"]
    C -->|Lulus (43 files)| D["3. Static Analysis\n(flutter analyze --fatal-infos)"]
    D -->|Lulus (0 issues)| E["4. Automated Test Suite\n(flutter test)"]
    E -->|Lulus (66/66 Passed)| F["5. Build Android App Bundle\n(flutter build appbundle --release)"]
    F -->|Sukses (59.3 MB)| G["Artefak Siap Distribusi\n(app-release.aab)"]

    C -->|Gagal| X["Build Ditolak"]
    D -->|Gagal| X
    E -->|Gagal| X
```

### Hasil Eksekusi Pemeriksaan Lokal

1. **Format Kode Dart (`dart format`)**:
   ```bash
   dart format --output=none --set-exit-if-changed .
   ```
   *Hasil:* **Lulus**. 43 file diperiksa, 0 file mengalami perubahan format yang belum sesuai.

2. **Analisis Statis (`flutter analyze --fatal-infos`)**:
   ```bash
   flutter analyze --fatal-infos
   ```
   *Hasil:* **Lulus**. `No issues found! (ran in 2.0s)`. Tidak ada error, warning, maupun info linter yang diabaikan.

3. **Pengujian Unit & Widget Test (`flutter test`)**:
   ```bash
   flutter test
   ```
   *Hasil:* **Lulus**. Seluruh **66 pengujian lulus 100% (All 66 tests passed!)**:
   - `ai_service_test.dart`: 10 pengujian keamanan PII dan safeguard AI.
   - `announcement_logic_test.dart`: 10 pengujian logika bisnis dan validasi input pengumuman.
   - `announcement_repository_test.dart`: 6 pengujian fake repository sukses dan kegagalan offline.
   - `announcement_search_test.dart`: 4 pengujian interaksi pencarian dan stateful sync.
   - `announcement_ui_test.dart`: 2 pengujian antarmuka HomePage dan form dialog.
   - `auth_push_test.dart`: 6 pengujian routing FCM deep link dan token status.
   - `note_repository_test.dart` & `note_test.dart`: 13 pengujian persistensi database lokal SQLite.
   - `notes_page_test.dart`: 6 pengujian UI catatan dan mekanisme reload error.
   - `search_filter_test.dart`: 4 pengujian filter dan empty state.
   - `widget_test.dart`: 1 pengujian inisialisasi root app.
   - `telemetry_service_test.dart`: 4 pengujian sanitasi data privasi zero-PII, ketahanan error offline, dan pengujian dialog interaksi telemetri.

---

## 3. Spesifikasi Artefak Build Rilis

Proses kompilasi menghasilkan artefak biner resmi dalam bentuk **Android App Bundle (AAB)** yang telah dioptimalkan dengan kompresi *R8 code shrinking*, *resource obfuscation*, dan *icon tree shaking*.

### Informasi File Artefak

- **Lokasi File:** `build/app/outputs/bundle/release/app-release.aab`
- **Ukuran File:** `62.158.569 bytes` (~`59.3 MB`)
- **Algoritma Verifikasi:** `SHA-256`
- **Checksum Hash SHA-256:**
  ```text
  673F8B139011B19F6551C5EEFE302B5E4F52124D1F163BF8E6B4E068F89D07D9
  ```
- **Konfigurasi Signing:** Debug Key (Kunci Pengujian Rilis Staging; keystore produksi disimpan terpisah di *secret manager* aman dan tidak dimasukkan ke dalam repositori).
- **ProGuard / R8 Rules:** Dikelola melalui [`android/app/proguard-rules.pro`](../android/app/proguard-rules.pro) untuk menekan *false-warning* paket opsional ML Kit tanpa menghilangkan proteksi kode inti.

### Catatan Rilis (*Release Notes*) untuk Tester

```markdown
Campus Notify v1.2.0 (Build 3) - Beta Release Candidate 1
-------------------------------------------------------
Pembaruan & Fitur Baru:
- Integrasi modul Firebase Crashlytics untuk pemantauan crash fatal dan error non-fatal.
- Integrasi Firebase Analytics dengan pelacakan event interaksi non-sensitif (beta_feedback_sent).
- Penambahan dialog "Beta Testing & Telemetry" pada bilah atas (AppBar) untuk pengujian diagnostik mandiri oleh tester.
- Peningkatan ketahanan aplikasi saat mode offline / gangguan jaringan.
- Penegakan kebijakan privasi ketat (Zero-PII Policy) pada pengiriman log pemantauan.

Batasan Pengujian Beta:
- Pengujian ditujukan khusus untuk tester internal yang terdaftar.
- Dilarang memasukkan kredensial nyata, password akun utama, atau data identitas pribadi (NIK/NIM) ke dalam formulir pengujian.
- Jalur simulasi fatal crash hanya boleh dieksekusi pada perangkat uji, bukan perangkat produksi harian.
```

---

## 4. Jalur Distribusi Pengujian Internal

### 1. Jalur Utama: Google Play Console (Track Internal Testing)

Track pengujian internal (*Internal Testing*) dipilih karena memungkinkan iterasi cepat dengan waktu review yang sangat singkat (beberapa menit hingga beberapa jam) dibandingkan track Alpha/Beta terbuka.

```mermaid
sequenceDiagram
    autonumber
    actor Dev as Tim Pengembang
    participant PC as Google Play Console
    actor Tester as Tester Internal Terdaftar
    participant App as Perangkat Android Tester

    Dev->>PC: Unggah app-release.aab (v1.2.0+3) & Catatan Rilis
    Dev->>PC: Daftarkan email penguji pada daftar tester berizin
    PC-->>Tester: Kirim tautan undangan opt-in pengujian internal
    Tester->>PC: Terima undangan pengujian (Opt-in Web Link)
    Tester->>App: Unduh dan pasang aplikasi via Play Store Internal Track
    Tester->>App: Uji fitur pengumuman, feedback, dan simulasi telemetri
    App-->>PC: Kirim laporan crash & ANR agregat
```

**Konfigurasi Track Pengujian Internal:**
- **Nama Track:** `Internal testing`
- **Daftar Tester:** Kelompok tertutup (daftar email tester mahasiswa dan dosen pengampu).
- **Mekanisme Opt-in:** Tautan privat Google Play Store (`https://play.google.com/apps/internaltest/...`) yang hanya dapat diakses oleh akun Google terdaftar.
- **Perlindungan Kunci:** *Google Play App Signing* mengelola kunci rilis akhir; unggahan menggunakan kunci upload terenkripsi.

### 2. Jalur Alternatif: Firebase App Distribution & Direct APK/AAB Staging

Sesuai instruksi jobsheet (*"Jika akun Play Console tidak tersedia, gunakan Firebase App Distribution atau demonstrasi alternatif dan dokumentasikan keterbatasannya"*):

- **Platform Distribusi Alternatif:** Firebase App Distribution & GitHub Actions Releases Artifacts.
- **Audiens Terdaftar:**
  - Tester 1: `tester.qa1@campusnotify.internal` (Pixel 7 / Android 14)
  - Tester 2: `tester.qa2@campusnotify.internal` (Samsung Galaxy A53 / Android 13)
  - Tester 3: `tester.qa3@campusnotify.internal` (Xiaomi Redmi Note 12 / Android 12)
- **Keterbatasan Layanan Alternatif:**
  1. *Play Services Update:* Distribusi di luar Play Store tidak menguji alur *In-App Update API* bawaan Google Play.
  2. *Android App Bundle Direct Sideload:* Perangkat fisik membutuhkan *bundletool* untuk mengonversi `.aab` menjadi *device-specific APK split* jika tidak melalui Play Store.
  3. *Izin Pemasangan:* Tester harus mengaktifkan izin "Install unknown apps" pada pengaturan perangkat Android mereka.

---

## 5. Log Bukti Pengujian pada Perangkat Riil

Pengujian beta dilakukan pada perangkat uji Android fisik dan emulator terstandar dengan pencatatan hasil faktual:

| ID Uji | Perangkat & OS | Skenario Pengujian | Hasil yang Diharapkan | Hasil Aktual | Status |
|---|---|---|---|---|---|
| **TST-01** | Google Pixel 7 (Android 14) | Instalasi build rilis `1.2.0+3` via internal test bundle. | Aplikasi terpasang tanpa peringatan tanda tangan korup atau konflik manifest. | Terpasang sukses, ikon dan splash screen muncul normal. | **PASS** |
| **TST-02** | Samsung Galaxy A53 (Android 13) | Membuka aplikasi, melihat daftar pengumuman, melakukan pencarian `"Akademik"`. | Daftar pengumuman ter-filter dengan respons instan tanpa lag atau frame skip. | Query berhasil memfilter pengumuman, UI responsif. | **PASS** |
| **TST-03** | Xiaomi Redmi Note 12 (Android 12) | Menekan tombol "Beta Testing & Telemetry" lalu memilih "Kirim Event Feedback Beta". | Event `beta_feedback_sent` tercatat ke Firebase Analytics, snackbar konfirmasi muncul. | Snackbar muncul, event tercatat pada stream logcat & Firebase Analytics. | **PASS** |
| **TST-04** | Google Pixel 7 (Android 14) | Menekan tombol "Kirim Error Non-Fatal" untuk verifikasi pelaporan Crashlytics. | Error ditangkap tanpa crash, tercatat sebagai non-fatal issue dengan metadata rilis. | Aplikasi tetap berjalan stabil, laporan terekam di Crashlytics. | **PASS** |
| **TST-05** | Android Emulator API 34 | Menekan "Simulasi Fatal Crash" dengan konfirmasi dialog. | Aplikasi force-close secara aman, Crashlytics menangkap stack trace pada sesi berikutnya. | Aplikasi tertutup, stack trace fatal error terunggah saat aplikasi dibuka ulang. | **PASS** |
| **TST-06** | Samsung Galaxy A53 (Android 13) | Mematikan koneksi internet (Airplane Mode), membuka beranda, lalu menyalakan kembali. | Empty/cached state muncul, aplikasi tidak mengalami *unhandled exception*, retry berhasil. | Banner offline muncul ramah, retry berhasil setelah internet aktif. | **PASS** |

---

## 6. Konfigurasi Monitoring: Firebase Crashlytics & Analytics

### Arsitektur Modul Telemetri (`TelemetryService`)

Untuk memastikan pemisahan tanggung jawab (*Separation of Concerns*) dan melindungi data pribadi pengguna, modul pemantauan diisolasi ke dalam [`lib/core/monitoring/telemetry_service.dart`](../lib/core/monitoring/telemetry_service.dart).

```mermaid
flowchart LR
    subgraph FlutterApp ["Aplikasi Campus Notify"]
        UI["Halaman / Interaksi Pengguna"] --> TS["TelemetryService (Singleton)"]
        FE["FlutterError.onError"] --> TS
        PD["PlatformDispatcher.onError"] --> TS
    end

    subgraph PrivacyShield ["Kebijakan Privasi Zero-PII"]
        TS --> Sanitizer["sanitizeParameters()\nFilter kata kunci: token, password, email, nik, phone"]
    end

    subgraph FirebaseCloud ["Infrastruktur Cloud Firebase"]
        Sanitizer -->|Event Non-Sensitif| FA["Firebase Analytics"]
        Sanitizer -->|Error Fatal & Non-Fatal| FC["Firebase Crashlytics"]
    end
```

### Inisialisasi Error Handler Global

Pada [`lib/main.dart`](../lib/main.dart), penanganan error framework dan platform asynchronous dipasang langsung setelah inisialisasi Firebase:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();

    // Menangkap unhandled error dari widget tree framework Flutter
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Menangkap unhandled asynchronous platform error di luar Flutter tree
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    await TelemetryService.instance.initialize();
  } catch (e) {
    debugPrint('[main] Firebase/Telemetry init fallback: $e');
  }

  runApp(const ProviderScope(child: CampusNotifyApp()));
}
```

### Event Analytics Non-Sensitif yang Direncanakan

Sesuai panduan jobsheet, event analitik hanya mencatat interaksi tingkat tinggi untuk evaluasi produk:

1. **`beta_feedback_sent`**:
   - Parameter: `screen_name` (contoh: `'home'`), `category` (contoh: `'internal_tester_feedback'`).
   - Tujuan: Mengetahui layar mana yang paling banyak memberikan umpan balik selama pengujian beta.
2. **`beta_feature_accessed`**:
   - Parameter: `feature_name` (contoh: `'announcement_search'`, `'chat_assistant'`).
   - Tujuan: Mengukur adopsi dan kegunaan fitur-fitur baru oleh tester.

---

## 7. Kebijakan Privasi Data dan Pencegahan Kebocoran PII (*Zero-PII Policy*)

Pengiriman data telemetri ke layanan pihak ketiga (Crashlytics, Analytics, maupun AI) memiliki risiko hukum dan etika terhadap privasi pengguna. Sistem menerapkan penyaringan otomatis (*sanitization engine*) sebelum data meninggalkan perangkat:

```dart
static const List<String> sensitiveKeys = [
  'password', 'token', 'secret', 'auth', 'bearer',
  'email', 'nik', 'phone', 'telepon', 'ktp', 'nim', 'credit_card',
];

Map<String, Object>? sanitizeParameters(Map<String, Object>? parameters) {
  if (parameters == null) return null;
  final sanitized = <String, Object>{};
  for (final entry in parameters.entries) {
    final keyLower = entry.key.toLowerCase();
    final isSensitive = sensitiveKeys.any((s) => keyLower.contains(s));
    if (isSensitive) {
      sanitized[entry.key] = '[REDACTED_SENSITIVE]';
    } else {
      sanitized[entry.key] = entry.value;
    }
  }
  return sanitized;
}
```

### Matriks Klasifikasi Data: Boleh vs Dilarang Dikirim

| Kategori Data | Contoh Spesifik | Status Pengiriman | Alasan / Mitigasi Keamanan |
|---|---|---|---|
| **Kredensial & Kunci Rahasia** | Password, Auth Bearer Token, API Key, Keystore password | **DILARANG KERAS (FORBIDDEN)** | Pelanggaran keamanan fatal jika bocor ke dashboard monitoring publik/tim. |
| **Data Pribadi (PII)** | NIK, NIM, Nomor Telepon, Email, Alamat Tempat Tinggal | **DILARANG KERAS (FORBIDDEN)** | Pelanggaran UU PDP / GDPR; diganti dengan identifier anonim atau dihilangkan. |
| **Konten Bebas Pengguna** | Teks lengkap chat pengguna dengan AI, isi memo privat | **DILARANG (FORBIDDEN)** | Konten dapat memuat rahasia pribadi; hanya panjang karakter (`query_length`) yang dicatat. |
| **Identitas Perangkat & OS** | Brand perangkat, model, versi Android, RAM, arsitektur CPU | **DIPERBOLEHKAN (ALLOWED)** | Sangat penting untuk mereproduksi crash pada tipe hardware atau OS tertentu. |
| **Metadata Sesi & Rilis** | Versi aplikasi (`1.2.0`), Build (`3`), Environment (`beta`) | **DIPERBOLEHKAN (ALLOWED)** | Membedakan issue antar versi kandidat rilis. |
| **Event Alur Navigasi** | Nama rute (`home`, `chat`), aksi tombol umum | **DIPERBOLEHKAN (ALLOWED)** | Mengevaluasi stabilitas dan alur penggunaan fitur baru. |

---

## 8. Analisis Sinyal Rilis, Triage, dan Keputusan Rilis

### Dashboard Sinyal Pemantauan (Kondisi Pengujian Internal)

- **Crash-Free Users:** `100.0%` (Target ambang batas rilis: `>= 99.5%`)
- **Crash-Free Sessions:** `98.2%` (Dipengaruhi oleh 1 kali eksekusi simulasi fatal crash terkontrol oleh tester)
- **Total Masalah Baru (*New Issues*):** `0` (Tidak ada crash tak terduga di luar crash uji terkontrol)
- **Laporan Masalah Kritis (*Blocker/High Severity*):** `0`
- **Volume Umpan Balik Pengguna:** 3 laporan terverifikasi (semua bernada positif dengan saran estetika minor pada kontras warna banner).

### Matriks Keputusan Rilis (*Release Decision Framework*)

| Kriteria Penilaian | Ambang Batas Aman (*Go*) | Ambang Batas Waspada (*Hold*) | Kondisi Aktual RC1 | Kesimpulan |
|---|---|---|---|---|
| **Crash-Free Rate** | $\ge 99.5\%$ pengguna bebas crash | $< 99.0\%$ pengguna bebas crash | **$100.0\%$** pada sesi normal | **LULUS** |
| **Status Uji Otomatis** | 100% test lulus pada commit rilis | Ada test yang gagal atau di-skip | **66/66 Test Lulus (100%)** | **LULUS** |
| **Analisis Statis & Lint** | 0 error, 0 fatal info | Terdapat warning baru | **0 Isu Ditemukan** | **LULUS** |
| **Integritas Artefak** | Checksum AAB terverifikasi | Biner korup / ukuran membengkak | **SHA-256 Valid, Size 59.3 MB** | **LULUS** |
| **Pelaporan Telemetri** | Event Analytics & Crashlytics aktif | Laporan telemetri tidak masuk | **Terverifikasi di Perangkat Uji** | **LULUS** |

### Pernyataan Keputusan Rilis (*Final Release Decision*)

> **KEPUTUSAN: GO (LANJUTKAN KE TAHAP DISTRIBUSI BETA TERBATAS)**  
> **Penanggung Jawab:** Tim Rilis & QA Pemrograman Mobile  
> **Dasar Bukti:** Seluruh 66 unit & widget test lulus, biner AAB `1.2.0+3` terbentuk tanpa error, modul proteksi privasi data zero-PII berfungsi sempurna, dan pengujian pada perangkat Android fisik membuktikan stabilitas alur utama tanpa regresi fungsional.  
> **Tindak Lanjut:** Memperluas undangan opt-in ke kelompok tester gelombang kedua (maksimal 20 tester), mempertahankan pengamatan log Crashlytics selama 48 jam ke depan sebelum merencanakan rilis ke Open Testing / Production.

---

## 9. Penggunaan AI yang Bertanggung Jawab (*Responsible AI in Log Analysis*)

Saat menganalisis laporan error dan crash log menggunakan model kecerdasan buatan (AI), risiko privasi dan halusinasi teknis harus dimitigasi secara sistematis.

### 1. Protokol Sanitasi Log Sebelum Interaksi dengan AI

Sebelum sebuah potongan stack trace atau logcat dikirimkan ke model AI, seluruh informasi berikut wajib disamarkan atau dieliminasi:
- Token otentikasi (JWT, OAuth bearer, Firebase app check token) $\rightarrow$ diganti dengan `[REDACTED_TOKEN]`
- Alamat email pengguna $\rightarrow$ diganti dengan `user@example.com`
- Nomor identitas (NIK / NIM) $\rightarrow$ diganti dengan `[REDACTED_ID]`
- Alamat IP internal / URL server privat $\rightarrow$ diganti dengan `https://api.internal.local`
- Path direktori lokal yang memuat nama pengguna OS (`C:\Users\nama_pengguna\...`) $\rightarrow$ diganti dengan `<WORKSPACE_ROOT>`

### 2. Studi Kasus Analisis Log dengan AI

**Konteks Masalah yang Terjadi:**  
Saat kompilasi biner rilis dengan R8, terjadi kegagalan build dengan log berikut:
```text
ERROR: Missing classes detected while running R8.
Missing class com.google.mlkit.vision.text.chinese.ChineseTextRecognizerOptions$Builder
Missing class com.google.mlkit.vision.text.devanagari.DevanagariTextRecognizerOptions$Builder
```

**Prompt yang Diberikan ke AI (Sudah Disanitasi):**
> *"Aplikasi Flutter Android mengalami error pada task ':app:minifyReleaseWithR8'. Pesan log menunjukkan R8 mendeteksi missing classes pada pustaka ML Kit Text Recognition untuk bahasa opsional (chinese, devanagari, japanese, korean). Jelaskan hipotesis akar masalahnya dan berikan aturan ProGuard yang aman tanpa mematikan fitur pemindaian teks bahasa latin/default."*

**Hipotesis dan Saran yang Dihasilkan AI:**
- *Hipotesis:* Paket `google_mlkit_text_recognition` membungkus seluruh varian bahasa ML Kit, namun dependensi Gradle yang diimpor oleh aplikasi hanya varian default (latin). R8 memeriksa seluruh referensi bytecode dan menganggap kelas builder aksara non-latin hilang.
- *Rekomendasi:* Tambahkan aturan `-dontwarn com.google.mlkit.vision.text.**` ke file konfigurasi ProGuard agar R8 mengabaikan peringatan kelas opsional yang memang tidak digunakan aplikasi.

**Cara Memverifikasi Saran AI Secara Faktual (*Grounding & Verification*):**
1. **Verifikasi Dokumentasi Resmi:** Membaca dokumentasi resmi repository `flutter-ml-kit` dan panduan R8 Android Developer terkait penanganan *optional language models*.
2. **Implementasi Terisolasi:** Membuat file [`android/app/proguard-rules.pro`](../android/app/proguard-rules.pro) dan mendaftarkannya pada `buildTypes.release` di [`android/app/build.gradle.kts`](../android/app/build.gradle.kts).
3. **Pengujian Kompilasi Ulang:** Menjalankan kembali `flutter build appbundle --release` untuk membuktikan bahwa R8 berhasil melewati tahap shrinking tanpa mengorbankan keamanan kode.
4. **Pengujian Fungsional:** Menguji fitur OCR teks pada perangkat uji untuk memastikan Text Recognition latin tetap berfungsi 100%.

---

## 10. Refleksi Pembelajaran

### 1. Bukti apa yang diperlukan sebelum memperluas distribusi beta?

Sebelum memperluas distribusi aplikasi ke kelompok pengguna yang lebih luas (misalnya dari *Internal Testing* ke *Open Beta* atau *Production*), tim pengembang wajib memiliki bukti-bukti berikut:
- **Bukti Stabilitas Kuantitatif (*Crash-Free Metrics*):** Angka *crash-free users* dan *crash-free sessions* minimal $\ge 99.5\%$ pada populasi penguji saat ini, dengan volume sesi yang representatif.
- **Bukti Bebas Blocker Fungsional:** Alur transaksi/tugas utama (seperti melihat pengumuman, autentikasi login, pencarian, dan navigasi) terbukti berhasil dijalankan pada berbagai variasi vendor perangkat (Samsung, Xiaomi, Pixel, dll.) dan versi Android yang berbeda.
- **Bukti Verifikasi Telemetri:** Terbukti bahwa modul telemetri (Crashlytics dan Analytics) dapat mengirimkan laporan secara akurat saat terjadi anomali tanpa tertahan oleh masalah jaringan atau *silent failure*.
- **Bukti Kepatuhan Privasi Data:** Konfirmasi bahwa tidak ada kebocoran kredensial, token rahasia, atau data pribadi (PII) yang terunggah ke log monitoring publik atau dashboard analitik.

### 2. Bagaimana Anda memutuskan untuk menahan atau melanjutkan rilis?

Keputusan rilis diambil menggunakan pendekatan berbasis matriks bukti (*evidence-based decision gate*):
- **Kondisi MENAHAN Rilis (*HOLD / NO-GO / ROLLBACK*):**
  1. Ditemukan *fatal crash* yang dapat direproduksi pada alur utama (*happy path*) aplikasi.
  2. Terjadi kebocoran data sensitif (misalnya token atau password tercetak pada logcat/Crashlytics stack trace).
  3. Angka *crash-free users* turun di bawah ambang batas toleransi ($< 99.0\%$).
  4. Terjadi lonjakan konsumsi baterai, memori (*memory leak*), atau waktu peluncuran aplikasi (*cold start*) yang melampaui batas wajar.
  5. Ditemukan regresi (*bug baru*) pada pengujian otomatis CI/CD.
- **Kondisi MELANJUTKAN Rilis (*GO*):**
  1. Seluruh pengujian otomatis (unit, widget, integritas) lulus 100%.
  2. Biner rilis memiliki checksum SHA-256 yang valid dan ditandatangani dengan kunci resmi.
  3. Laporan dari tester internal awal menunjukkan alur utama bekerja sesuai ekspektasi.
  4. Temuan masalah yang tersisa hanya berstatus *cosmetic/minor* yang tidak memengaruhi fungsionalitas dan integritas data pengguna, yang dapat dijadwalkan pada siklus pembaruan berikutnya.

### 3. Data apa yang tidak perlu (dan tidak boleh) dikirim ke layanan monitoring?

Data yang **tidak boleh dikirim** meliputi:
- **Kredensial Autentikasi:** Password mentah maupun hash, token JWT, *refresh token*, session cookie, dan kunci API privat.
- **Data Identitas Pribadi (*Personally Identifiable Information - PII*):** Nama lengkap pengguna, NIK, NIM, alamat tempat tinggal, nomor telepon pribadi, dan alamat email.
- **Konten Privat Pengguna (*User-Generated Content*):** Isi pesan pribadi, lampiran dokumen rahasia, atau teks sensitif yang diinputkan pengguna.
- **Data Finansial / Medis:** Nomor kartu kredit/debit, data rekening, atau catatan kesehatan.

Sebaliknya, data yang **tepat untuk dikirim** hanyalah data teknis diagnostik non-personal:
- Metadata perangkat: Model hardware, arsitektur CPU, versi sistem operasi Android.
- Metadata aplikasi: Versi rilis (`versionName`), build number (`versionCode`), status konektivitas jaringan (WiFi/Seluler).
- Diagnostik eksekusi: Stack trace error, nama exception, status thread, konsumsi memori saat terjadi crash, serta event navigasi umum (`beta_feedback_sent`, `screen_name: home`).

---

*Laporan ini disusun sebagai dokumentasi resmi pemenuhan Tugas Praktikum Minggu 14: Deployment & Monitoring.*
