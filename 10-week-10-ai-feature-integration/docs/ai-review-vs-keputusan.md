# AI Review vs Keputusan

> **Status bukti:** Dokumen ini disusun dari potongan kode dan log yang tersedia di percakapan, bukan dari checkout repository atau keseluruhan diff PR. Karena itu, hasil `flutter analyze`, hasil `flutter test` terbaru, dan keluaran AI eksternal tidak boleh dianggap sudah diverifikasi. Bagian yang memerlukan bukti lokal ditandai secara eksplisit.

## 1. Prompt AI yang digunakan

```text
Review PR Flutter ini sebagai senior Flutter dev.
Konteks: feature-first Clean Architecture (presentation -> domain <- data),
Riverpod, GoRouter, SQLite + Dio.
Fokus: kebenaran, arsitektur, dan test. Abaikan style.
Berikan 5 temuan teratas + level (blocker/saran)
+ alasan + usulan potongan kode perbaikan.
```

## 2. Keluaran review awal

Berikut ringkasan review awal berdasarkan bukti yang tersedia. Ini adalah ringkasan review untuk tugas ini, **bukan salinan verbatim dari keluaran AI lain**.

### Temuan 1 — Widget test gagal karena Firebase belum diinisialisasi
- **Level:** Saran (menjadi blocker untuk pipeline yang mewajibkan semua test lulus).
- **Bukti:** Log test `Campus Notify dapat dibuat` menunjukkan `FirebaseException [core/no-app] No Firebase App '[DEFAULT]' has been created`. Stack trace mengarah ke `FirebaseMessaging.instance`, `handleTerminated` di `messaging/push_service.dart:228`, lalu `_CampusNotifyAppState.initState` di `main.dart:118`.
- **Dampak:** Widget test gagal saat `CampusNotifyApp` dibuat langsung, karena jalur test tidak menjalankan `main()` yang menginisialisasi Firebase.
- **Keputusan:** Diterima.
- **Perbaikan yang disarankan:** Buat push notification dapat dinonaktifkan saat widget test, atau inisialisasi Firebase dengan konfigurasi test yang valid. Opsi yang lebih sederhana untuk widget test UI adalah dependency/configuration flag.

Contoh:

```dart
class CampusNotifyApp extends ConsumerStatefulWidget {
  const CampusNotifyApp({
    super.key,
    this.enablePushNotifications = true,
  });

  final bool enablePushNotifications;

  @override
  ConsumerState<CampusNotifyApp> createState() => _CampusNotifyAppState();
}
```

Lalu pada `initState`:

```dart
@override
void initState() {
  super.initState();

  if (!widget.enablePushNotifications) return;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    final router = ref.read(routerProvider);

    listenForeground((route) => router.go(route));
    handleTerminated((route) => router.go(route));
    checkPendingDeepLink((route) => router.go(route));
  });
}
```

Pada test:

```dart
await tester.pumpWidget(
  ProviderScope(
    child: const CampusNotifyApp(enablePushNotifications: false),
  ),
);
```

> Pastikan `ProviderScope` dan import mengikuti struktur test yang sebenarnya. Setelah perubahan, jalankan ulang test; jangan menganggap masalah selesai sebelum hasil aktual menunjukkan lulus.

### Temuan 2 — Inisialisasi listener push berada pada lifecycle widget dan menyulitkan pengujian
- **Level:** Saran.
- **Bukti:** Berdasarkan stack trace dan potongan `main.dart` yang tersedia, `CampusNotifyApp.initState` menjadwalkan `listenForeground`, `handleTerminated`, dan `checkPendingDeepLink`; salah satunya mengakses `FirebaseMessaging.instance`.
- **Alasan:** Membuat widget UI ikut memulai integrasi FCM membuat widget test bergantung pada setup Firebase. Ini merupakan masalah testability dan coupling pada batas UI–infrastruktur.
- **Keputusan:** Diterima sebagian. Perlu konfigurasi/injeksi agar push bisa dimatikan atau diganti pada test. Memindahkan seluruh listener ke service terpisah bisa menjadi refactor lanjutan, tetapi tidak wajib untuk memperbaiki test ini.
- **Bukti tambahan yang masih diperlukan:** Periksa apakah listener memiliki mekanisme unsubscribe/dispose dan apakah callback dapat terdaftar berulang. Jangan menyimpulkan ada memory leak sebelum implementasi service diperiksa.

### Temuan 3 — Risiko listener terdaftar lebih dari sekali atau tidak dibersihkan
- **Level:** Saran, belum terverifikasi.
- **Bukti saat ini:** Belum ada bukti langsung bahwa listener didaftarkan berulang atau tidak dibersihkan.
- **Keputusan:** Belum diterima sebagai bug. Periksa implementasi `listenForeground`, `handleTerminated`, dan `checkPendingDeepLink`, termasuk apakah fungsi mengembalikan subscription dan apakah subscription dibatalkan saat lifecycle berakhir.
- **Alasan:** Ini baru hipotesis sampai kode service menunjukkan subscription yang perlu dibatalkan tetapi tidak dibatalkan.

### Temuan 4 — Batas dependency Clean Architecture harus diverifikasi
- **Level:** Saran, belum terverifikasi.
- **Aturan keputusan:** Folder `domain` tidak boleh mengimpor Flutter, Firebase, Dio, atau SQLite. Domain boleh berisi entity, kontrak repository, dan use case yang tidak bergantung pada detail infrastruktur.
- **Keputusan:** Belum bisa menyatakan ada pelanggaran tanpa hasil pencarian pada repository aktual.
- **Perintah verifikasi PowerShell** (jalankan dari root project):

```powershell
Get-ChildItem lib -Recurse -Directory |
  Where-Object { $_.FullName -match '\\domain$' } |
  ForEach-Object {
    Get-ChildItem $_.FullName -Filter *.dart -Recurse |
      Select-String -Pattern 'package:flutter|package:firebase_|package:dio|package:sqflite|package:sqlite'
  }
```

- **Cara membaca hasil:** Jika ada baris, periksa file dan import tersebut. Jika tidak ada hasil, catat sebagai “tidak ditemukan import langsung yang cocok pada folder domain yang dipindai”; jangan menyimpulkan seluruh arsitektur pasti benar hanya dari grep.

### Temuan 5 — Hasil analisis statis dan test harus menjadi bukti keputusan
- **Level:** Saran.
- **Alasan:** Review kode saja tidak membuktikan bahwa perubahan tetap dapat dianalisis dan semua test lulus.
- **Keputusan:** Diterima sebagai langkah verifikasi wajib, bukan sebagai bug kode yang sudah terbukti.
- **Status:** Belum ada keluaran terbaru `flutter analyze` dan `flutter test` yang tersedia dalam bukti saat dokumen ini disusun.

## 3. Tabel keputusan

| No. | Usulan/temuan | Bukti | Keputusan akhir | Alasan teknis |
|---|---|---|---|---|
| 1 | Widget test gagal karena Firebase default app belum dibuat | Log error `core/no-app`, stack trace ke `FirebaseMessaging.instance` dan `handleTerminated` | **Terima** | Test membuat widget tanpa menjalankan inisialisasi Firebase yang dilakukan jalur `main()` |
| 2 | Push listener perlu dipisahkan/dikonfigurasi agar UI bisa diuji tanpa FCM | Listener dipanggil dari `CampusNotifyApp.initState`; test menyentuh FCM | **Terima sebagian** | Konfigurasi/injeksi test diperlukan; refactor service penuh tidak otomatis wajib |
| 3 | Listener mungkin tidak dibersihkan atau terdaftar berulang | Belum ada bukti implementasi subscription | **Tunda / jangan klaim bug** | Perlu inspeksi kode service dan lifecycle |
| 4 | Domain mungkin mengimpor detail framework/infrastruktur | Hasil grep repository belum dilampirkan | **Tunda / perlu verifikasi** | Jangan menyatakan pelanggaran tanpa path dan baris import yang nyata |
| 5 | Jalankan `flutter analyze` dan `flutter test` | Log lama menunjukkan widget test gagal; hasil terbaru belum tersedia | **Terima sebagai pemeriksaan wajib** | Hasil harus direkam setelah perubahan, tidak boleh diasumsikan |

## 4. Contoh usulan yang ditolak karena melanggar arsitektur

> **Catatan:** Ini contoh usulan yang ditolak untuk menunjukkan penerapan checklist dependency rule. Jangan menyatakan bahwa AI eksternal benar-benar memberikan usulan ini kecuali memang muncul dalam keluaran AI yang Anda simpan.

**Usulan:** Memindahkan `Firebase.initializeApp()` ke entity atau use case di folder `domain`.

**Keputusan:** **Tolak.**

**Alasan teknis:**
1. Firebase adalah detail infrastruktur, bukan aturan bisnis.
2. Domain tidak boleh bergantung pada Firebase SDK.
3. Memasukkan inisialisasi Firebase ke domain membalik arah dependency dan membuat unit test domain membutuhkan konfigurasi infrastruktur.
4. Inisialisasi Firebase seharusnya berada di composition root/startup aplikasi; interaksi FCM dibungkus pada service/data layer sesuai arsitektur project.

## 5. Bukti test dan analyze

### Bukti yang tersedia

| Pemeriksaan | Hasil yang diketahui | Interpretasi |
|---|---|---|
| `flutter test test/widget_test.dart` | Log yang dibagikan sebelumnya gagal dengan `FirebaseException [core/no-app]` pada test `Campus Notify dapat dibuat` | Kegagalan widget test terkonfirmasi dari log yang dibagikan |
| `flutter analyze` | Belum ada output terbaru yang tersedia | **Belum diverifikasi** |
| `flutter test` setelah perbaikan | Belum ada output terbaru yang tersedia | **Belum diverifikasi** |
| `git diff --check` | Belum ada output | **Belum diverifikasi** |

### Perintah yang perlu dijalankan dari root project

```powershell
git diff --check
flutter analyze
flutter test
```

Salin output terminal aktual ke dokumen ini. Jika sebuah perintah gagal, simpan error lengkap dan catat apakah error sudah ada sebelum perubahan atau muncul sesudahnya.

### Template catatan hasil aktual

```text
Tanggal/waktu:
Branch:
Commit:
Perintah:
Exit code:
Ringkasan output:
Temuan yang didukung oleh output:
```

## 6. Checklist akhir

- [x] Prompt review dicatat.
- [x] Satu kegagalan nyata didukung log error.
- [x] Ada keputusan menerima dan menerima sebagian dengan alasan teknis.
- [x] Ada contoh penolakan yang menjelaskan dependency rule.
- [ ] Tempelkan keluaran AI asli secara verbatim, jika prompt dijalankan di alat AI lain.
- [ ] Verifikasi minimal dua temuan yang benar terhadap diff/kode aktual; jangan menghitung dua deskripsi dari akar masalah yang sama sebagai dua bug independen.
- [ ] Verifikasi dan catat hasil grep domain.
- [ ] Jalankan dan tempelkan hasil terbaru `git diff --check`, `flutter analyze`, dan `flutter test`.
- [ ] Pastikan contoh penolakan benar-benar cocok dengan usulan AI asli, atau tandai sebagai contoh hipotetis seperti di atas.

## 7. Kesimpulan sementara

Bukti yang tersedia cukup untuk menyimpulkan bahwa widget test mengalami masalah karena kode startup push notification mengakses Firebase sebelum default app tersedia pada konteks test. Bukti tersebut juga mendukung perbaikan testability melalui konfigurasi push notification yang dapat dinonaktifkan atau dependency yang dapat diinjeksi.

Namun, dokumen ini **belum boleh diklaim sebagai audit final yang sepenuhnya terverifikasi** sampai diff PR, keluaran AI asli, pemeriksaan domain, dan hasil test/analyze terbaru dilampirkan. Menandai bagian tersebut sebagai belum diverifikasi lebih akurat daripada mengarang hasil.
