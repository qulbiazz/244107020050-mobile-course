# Flutter DevTools Profiling

## Lingkungan

- Flutter 3.29.0 stable, Dart 3.7.0, DevTools 2.42.2
- Android Emulator `Medium_Phone_API_35`, Android 15 (API 35), x64
- Aplikasi dijalankan dengan `flutter run -d emulator-5554 --profile`

## Metode

1. Jalankan aplikasi dalam profile mode dan buka tab Performance serta Memory di DevTools.
2. Reset statistik frame Android, buka Asisten Kampus, lalu kirim pertanyaan umum
   `jadwal_kegiatan_kampus`. API key tidak tersedia sehingga aplikasi menampilkan
   fallback lokal; tidak ada jawaban AI atau data pribadi yang dikirim.
3. Ambil statistik frame dan memori proses melalui Android Debug Bridge:

   ```powershell
   adb shell dumpsys gfxinfo com.example.campus_notify reset
   # Lakukan interaksi singkat di aplikasi
   adb shell dumpsys gfxinfo com.example.campus_notify
   adb shell dumpsys meminfo com.example.campus_notify
   ```

## Hasil pengamatan

| Area | Hasil | Interpretasi |
|---|---|---|
| Performance DevTools | Chart sesi menampilkan rata-rata 53 FPS dan beberapa frame lambat | Riwayat mencakup startup serta interaksi selama sesi panjang; bukan pengukuran steady-state. |
| Frame setelah reset | 34 frame, 10 janky (29.41%); P50 38 ms, P90 53 ms, P95 65 ms, P99 73 ms; 1 missed VSync | Interval singkat ini mencakup fokus/input chat dan tampilan fallback. Angka tinggi adalah sinyal untuk pengukuran ulang, bukan baseline produksi. |
| Memory Android | Total PSS 201,412 KB (sekitar 197 MiB), RSS 351,228 KB (sekitar 343 MiB) setelah layar chat dibuka | Snapshot satu kali proses emulator; termasuk penggunaan native dan tidak mewakili seluruh perangkat atau kondisi rilis. |
| CPU sampling | VM mengembalikan 2,494 sampel selama kira-kira 229 detik | Rincian call tree/hot function tidak dapat diverifikasi dari tampilan CPU Profiler, jadi tidak digunakan untuk menyimpulkan fungsi yang lambat. |

Pengukuran Android dapat dipengaruhi emulator x64, keyboard, dialog izin mikrofon,
startup, dan proses grafis emulator. Karena itu, angka jank tidak membuktikan
bahwa satu fungsi tertentu adalah penyebabnya. Tidak ada perubahan kode yang dibuat
dari pengukuran ini.

## Bukti

- [Performance DevTools](../screenshots/devtools-performance.png)
- [Memory DevTools](../screenshots/devtools-memory.png)
- [Layar chat dan fallback lokal](../screenshots/profile-chat-response.png)

## Kesimpulan dan tindak lanjut

Grafik menunjukkan jank selama sesi, tetapi rekaman ini belum cukup terisolasi
untuk menunjuk sumber CPU atau memori tertentu. Ulangi profiling pada perangkat
fisik atau emulator yang stabil: reset statistik sebelum tiap skenario, ukur satu
alur UI berulang (misalnya membuka chat dan mengirim prompt tanpa PII), rekam
CPU Profiler untuk durasi singkat, dan bandingkan beberapa snapshot memori sebelum
dan sesudah navigasi. Optimasi baru sebaiknya dilakukan setelah flame chart atau
perbandingan snapshot mengidentifikasi pekerjaan yang konsisten mahal.
