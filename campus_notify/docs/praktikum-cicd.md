# Laporan Praktikum Minggu 13: CI/CD Automation dengan GitHub Actions

**Mata Kuliah:** Pemrograman Mobile  
**Proyek:** Campus Notify (`campus_notify`)  
**Topik:** Otomatisasi Continuous Integration & Continuous Delivery (CI/CD)  
**Terakhir Diperbarui:** 19 November 2026  

---

## 1. Pendahuluan dan Tujuan Pembelajaran

Pemeriksaan manual terhadap kode aplikasi mobile rentan terhadap kelalaian manusia (*human error*), sulit direproduksi secara konsisten di berbagai mesin pengembang, serta memakan waktu. Melalui praktikum Minggu 13 ini, pipeline CI/CD diimplementasikan menggunakan **GitHub Actions** untuk menjalankan pengujian otomatis, analisis statis, format kode, serta pembangunan artefak aplikasi Android (**APK** dan **AAB**) secara deterministik.

### Tujuan Pembelajaran:
1. Menjelaskan alur CI/CD dari *commit* hingga terbentuknya artefak aplikasi yang siap diuji.
2. Mengonfigurasi file workflow GitHub Actions untuk *code formatting*, *static analysis*, *automated testing*, dan *Android release build*.
3. Mengunggah dan menyimpan APK/AAB sebagai artefak yang dapat diunduh dan ditinjau pada tab GitHub Actions.
4. Menerapkan strategi *semantic versioning* dan memahami batasan serta risiko penyimpanan *secret* / kredensial pada pipeline mobile.

---

## 2. Arsitektur dan Alur Kerja Pipeline CI/CD

Alur kerja otomatisasi dirancang mengikuti standar *gate verification* bertahap. Apabila salah satu tahap pemeriksaan gagal, pipeline akan langsung berhenti (*fail-fast*) dan membatalkan langkah build untuk menghemat kuota runner serta mencegah artefak cacat terdistribusi.

```mermaid
flowchart TD
    A["Developer Push / PR / Manual Dispatch"] --> B["GitHub Actions Runner (ubuntu-latest)"]
    B --> C["Checkout Source Code (actions/checkout@v4)"]
    C --> D["Setup Environment\n- Java 17 Temurin\n- Flutter Stable"]
    D --> E["Dependency Resolution\n(flutter pub get)"]
    
    subgraph VerificationGates ["Gerbang Verifikasi Kualitas Kode"]
        E --> F["Dart Code Formatting\n(dart format --set-exit-if-changed .)"]
        F -->|Lolos| G["Static Analysis\n(flutter analyze --fatal-infos)"]
        G -->|Lolos| H["Automated Unit & Widget Tests\n(flutter test --coverage)"]
    end
    
    subgraph BuildAndArtifacts ["Kompilasi & Publikasi Artefak"]
        H -->|Semua Test Lulus (62/62)| I["Build Release APK\n(flutter build apk --release)"]
        I --> J["Build Release App Bundle\n(flutter build appbundle --release)"]
        J --> K["Upload Artifacts (actions/upload-artifact@v4)\n- app-release.apk\n- app-release.aab"]
    end
    
    F -->|Gagal Format| X["Job Terminated (Fail)"]
    G -->|Gagal Analisis/Lint| X
    H -->|Test Gagal| X
    K --> L["Artefak Tersedia untuk Diunduh (Retention: 7 Hari)"]
```

### Penjelasan Komponen Workflow:
- **Event Trigger (`on`)**:
  - `push`: Memeriksa setiap commit baru yang masuk ke branch utama (`main`).
  - `pull_request`: Menguji kode pada branch usulan sebelum di-merge ke branch `main`.
  - `workflow_dispatch`: Memungkinkan eksekusi manual pipeline secara langsung dari antarmuka GitHub Actions.
- **Hak Akses Minimum (`permissions: contents: read`)**:
  - Mengikuti prinsip *least privilege*, runner hanya diberikan akses baca ke repositori untuk mengunduh kode, tanpa hak tulis yang tidak diperlukan.
- **Manajemen Konkurensi (`concurrency`)**:
  - `cancel-in-progress: true` secara otomatis membatalkan eksekusi pipeline lama apabila ada commit baru yang di-push pada branch yang sama, menghemat waktu eksekusi runner.

---

## 3. Konfigurasi File Workflow (`.github/workflows/flutter-ci.yml`)

Workflow CI/CD diatur melalui file [`.github/workflows/flutter-ci.yml`](../../.github/workflows/flutter-ci.yml):

```yaml
name: Flutter CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  test-and-build:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: campus_notify
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up Java 17
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'
          cache: 'gradle'

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Verify formatting
        run: dart format --output=none --set-exit-if-changed .

      - name: Static analysis
        run: flutter analyze --fatal-infos

      - name: Run unit & widget tests
        run: flutter test --coverage

      - name: Build Android APK
        run: flutter build apk --release

      - name: Build Android App Bundle (AAB)
        run: flutter build appbundle --release

      - name: Upload Android Build Artifacts
        uses: actions/upload-artifact@v4
        with:
          name: android-builds
          path: |
            campus_notify/build/app/outputs/flutter-apk/app-release.apk
            campus_notify/build/app/outputs/bundle/release/app-release.aab
          if-no-files-found: error
          retention-days: 7
```

### Detail Langkah (*Steps*):
1. **`actions/checkout@v4`**: Mengambil source code commit yang bersangkutan ke runner.
2. **`actions/setup-java@v4`**: Menyiapkan JDK 17 Temurin yang dibutuhkan oleh Android Gradle Plugin (AGP) versi 8.7.0 dan Java Desugaring pada project.
3. **`subosito/flutter-action@v2`**: Mengunduh dan mengonfigurasi Flutter SDK versi stabil (*stable channel*) dengan fitur cache untuk mempercepat run berikutnya.
4. **`flutter pub get`**: Mengunduh dan menautkan seluruh dependensi dari `pubspec.lock`.
5. **`dart format --output=none --set-exit-if-changed .`**: Memverifikasi kesesuaian indentasi dan gaya penulisan kode sesuai standar resmi Dart. Jika ada file yang tidak rapi, pipeline berhenti dengan kode keluar non-nol.
6. **`flutter analyze --fatal-infos`**: Menjalankan linting dan analisis semantik kode. Parameter `--fatal-infos` memastikan bahwa *info*, *warning*, maupun *error* akan menggagalkan build.
7. **`flutter test --coverage`**: Menjalankan 62 unit dan widget test secara terisolasi sekaligus merekam laporan cakupan baris kode (`lcov.info`).
8. **`flutter build apk --release`**: Mengompilasi aplikasi ke dalam format APK (*Android Package*) yang siap dipasang secara langsung untuk pengujian internal (*sideloading*).
9. **`flutter build appbundle --release`**: Mengompilasi aplikasi ke dalam format AAB (*Android App Bundle*) yang optimal untuk distribusi rilis resmi Google Play Store.
10. **`actions/upload-artifact@v4`**: Mengemas dan menyimpan kedua berkas biner tersebut ke storage GitHub Actions selama 7 hari (*retention-days: 7*).

---

## 4. Temuan dan Perbaikan Lokal Sebelum Push

Sesuai instruksi Codelab Bagian 3.2, perintah pipeline dijalankan secara lokal terlebih dahulu untuk menemukan kegagalan tersembunyi:

### A. Masalah Import pada Integration Test
Saat `flutter analyze --fatal-infos` dieksekusi pertama kali, ditemukan error fatal:
```text
error - Undefined name 'IntegrationTestWidgetsFlutterBinding' - integration_test\notes_flow_test.dart:32:3 - undefined_identifier
```
**Penyebab:** Berkas `integration_test/notes_flow_test.dart` belum mengimpor dependensi `package:integration_test/integration_test.dart`.  
**Perbaikan:** Menambahkan impor `package:integration_test/integration_test.dart` pada bagian atas file sehingga `IntegrationTestWidgetsFlutterBinding.ensureInitialized()` dapat dikenali.

### B. Standardisasi Format Kode Dart
Saat `dart format --output=none --set-exit-if-changed .` dijalankan, terdeteksi 9 file yang belum mengikuti format baku Dart (antara lain `ai_service.dart`, `announcement_logic_test.dart`, `note_repository_test.dart`, dll).  
**Perbaikan:** Menjalankan perintah `dart format lib test integration_test tool` untuk merapikan seluruh indentasi secara otomatis sebelum commit.

### C. Ringkasan Hasil Uji Lokal (Green Verification):
| Tahapan | Perintah | Status | Keterangan |
|---|---|---|---|
| Format | `dart format --output=none --set-exit-if-changed .` | **LULUS** | 41 file diperiksa, 0 perubahan |
| Analisis Statis | `flutter analyze --fatal-infos` | **LULUS** | 0 issues found |
| Pengujian Otomatis | `flutter test --coverage` | **LULUS** | 62 / 62 tests passed |

---

## 5. Strategi Versioning dan Git Tagging

Pengaturan versi aplikasi diatur pada file [`pubspec.yaml`](../pubspec.yaml):

```yaml
version: 1.1.0+2
```

### Penjelasan Semantic Versioning (`MAJOR.MINOR.PATCH+BUILD_NUMBER`):
- **Major (`1`)**: Perubahan besar arsitektur yang tidak kompatibel ke belakang (*breaking changes*).
- **Minor (`1`)**: Penambahan fitur baru yang tetap kompatibel ke belakang (pada pembaruan ini: penambahan pipeline otomatisasi CI/CD, perbaikan analisis tes, dan pembuatan rilis biner).
- **Patch (`0`)**: Perbaikan bug (*bugfix*) kecil tanpa menambah fungsionalitas baru.
- **Build Number (`+2`)**: Nomor urut build internal yang unik dan monoton bertambah. Di platform Android:
  - `versionName` diambil dari `1.1.0` (ditampilkan kepada pengguna di Google Play Store).
  - `versionCode` diambil dari angka build `2` (digunakan oleh Google Play untuk mendeteksi pembaruan biner).

### Rencana Versi Berikutnya:
- **`1.1.1+3`**: Diterapkan apabila terdapat perbaikan kecil (*patch*) pada bug tampilan atau logika pencarian.
- **`1.2.0+3`**: Diterapkan saat modul fitur baru (misal: sinkronisasi catatan offline atau filter kategori pengumuman) ditambahkan.

### Penggunaan Git Tag:
Untuk menghubungkan antara kode sumber yang diaudit, log eksekusi GitHub Actions, dan file biner yang dihasilkan, setiap rilis ditandai dengan Git Tag:
```bash
git tag -a v1.1.0 -m "Release version 1.1.0 with CI/CD automation pipeline"
git push origin v1.1.0
```

---

## 6. Batasan Rahasia, Secrets, dan Keamanan Pipeline

Aspek keamanan dalam eksekusi CI/CD mobile memiliki pertimbangan khusus:

1. **Prinsip *Zero-Secrets-in-Repository*:**
   - Berkas sensitif seperti Private Keystore (`.jks` / `.keystore`), password keystore, token akses Firebase/API privat, dan Service Account Key tidak boleh disimpan di repositori Git.
   - Kredensial sensitif disimpan pada **GitHub Actions Secrets** (contoh: `ANDROID_KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`).

2. **Perbedaan Secrets vs `--dart-define`:**
   - Nilai konfigurasi yang dioper melalui flag `--dart-define` (misalnya alamat endpoint API) dikompilasi langsung ke dalam biner kode mesin (*machine code* atau DEX/assets) aplikasi.
   - **Peringatan Keamanan:** Nilai `--dart-define` **BUKANLAH rahasia** karena dapat diekstraksi secara mudah menggunakan teknik *reverse engineering* (dekompilasi APK menggunakan JADX atau strings analysis). Gunakan hanya untuk konfigurasi lingkungan (*environment URL*), bukan API secret keys.

3. **Pemisahan Pipeline Pull Request vs Production Release:**
   - Pada workflow CI pengujian harian dan PR, aplikasi dibangun menggunakan **Debug Signing Config** bawaan untuk validasi integritas kompilasi.
   - Keystore produksi hanya boleh diinjeksikan pada workflow rilis khusus (*Release Workflow*) yang dipicu oleh Git Tag terverifikasi dan dibatasi pada branch terlindungi (*protected branch*).
   - Pull request yang berasal dari *fork* publik tidak diberikan akses ke GitHub Secrets repositori utama untuk mencegah eksfiltrasi kredensial oleh pihak luar melalui modifikasi skrip workflow.

---

## 7. Refleksi Praktikum

### 1. Masalah apa yang ditemukan otomatis sebelum perubahan di-merge?
- **Pencegahan Error Sintaks/Impor:** Analisis statis `flutter analyze --fatal-infos` langsung mendeteksi ketiadaan import `package:integration_test/integration_test.dart` pada file `notes_flow_test.dart`. Tanpa CI, kelalaian ini berisiko masuk ke branch utama dan merusak build rekan tim.
- **Konsistensi Gaya Kode:** `dart format --set-exit-if-changed` mendeteksi 9 file yang memiliki format spasi/indentasi yang tidak baku. Hal ini mencegah *diff noise* yang tidak perlu pada saat *code review*.
- **Regresi Logika Bisnis:** Jika ada perubahan di `Announcement` atau `Note` yang merusak aturan validasi (misal judul kosong diterima), 62 unit & widget test akan seketika menggagalkan pipeline sebelum kode sempat di-merge.

### 2. Informasi apa yang Anda butuhkan untuk menyelidiki build yang gagal?
- **Log Langkah Tertentu (*Step Logs*):** Meninjau bagian spesifik mana yang gagal (apakah tahap format, analisis, unit test, atau kompilasi Gradle).
- **Stack Trace & Error Output:** Pesan spesifik seperti nama baris, nama file, dan assertion yang gagal (misal `Expected: 'Pengumuman' Actual: ''`).
- **Informasi Lingkungan Runner:** Versi Flutter SDK (`flutter --version`), versi Java (`java -version`), serta status dependensi (`flutter doctor -v`).
- **Commit Hash & Diff Perubahan:** Memeriksa commit spesifik apa yang memicu kegagalan dan baris kode apa saja yang baru diubah pada pull request tersebut.

### 3. Bagian mana yang masih perlu persetujuan atau pemeriksaan manual sebelum rilis?
- **Penandatanganan Biner Produksi (*Production App Signing*):** Validasi integritas sertifikat rilis resmi sebelum diunggah ke Google Play Console.
- **Pengujian pada Perangkat Fisik (*Real Device Testing & UX Validation*):** Menilai responsivitas sentuhan, tampilan font pada berbagai kerapatan layar (*screen density*), konsumsi baterai, dan interaksi hardware nyata (seperti kamera ML Kit dan getaran notifikasi) yang tidak dapat digantikan sepenuhnya oleh unit test.
- **Tinjauan Kepatuhan Kebijakan (*Store Policy & Legal Review*):** Memastikan izin Android (*permissions* seperti kamera, notifikasi), dokumen kebijakan privasi (*privacy policy*), dan rincian perubahan (*release notes*) telah disetujui sebelum rilis publik.
