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
[!hasil screenshots](screenshots/flutter-analyze.png)
[!hasil screenshots](screenshots/flutter-test.png)

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