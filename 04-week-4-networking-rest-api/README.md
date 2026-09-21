# Uji tiga skenario error
1. Jalankan aplikasi dengan internet normal, amati loading lalu daftar 100 posts.
-> Aplikasi menampilkan loading, lalu berhasil menampilkan 100 posts dari JSONPlaceholder.

2. Matikan internet (mode pesawat), tekan refresh, amati pesan ramah + tombol Coba lagi. Nyalakan kembali internet, tekan Coba lagi.
-> Setelah menekan refresh, muncul pesan: Tidak dapat terhubung ke server. Periksa internet Anda. Tombol Coba lagi juga muncul. Setelah internet dinyalakan kembali dan tombol ditekan, daftar posts tampil lagi.

3. Sementara ubah baseUrl menjadi URL salah, amati pesan error koneksi. Kembalikan setelah uji.
-> baseUrl salah: Aplikasi menampilkan pesan error koneksi: Tidak dapat terhubung ke server. Periksa internet Anda.



# AI Verification Checklist
Sebelum kode AI diterima, verifikasi hal berikut dan catat temuan Anda di README:
1. Apakah UI memanggil Dio secara langsung (dilarang) atau lewat repository?
-> UI mengakses data melalui provider dan repository. UI tidak memanggil Dio secara langsung.


2. Apakah fromJson aman null, atau masih memakai cast langsung yang bisa crash?
-> `Post.fromJson` dan `Comment.fromJson` memakai cast nullable serta nilai default. Field yang hilang atau null tidak menyebabkan crash.


3. Apakah semua tipe DioExceptionType (timeout, connectionError, badResponse) dipetakan ke pesan pengguna?
-> Ya. Timeout, connection error, bad response 404, bad response 500, serta error jaringan lain dipetakan ke pesan yang ramah pengguna melalui `friendlyErrorMessage`.


4. Apakah baseUrl/timeout terpusat di satu client, bukan tersebar di tiap method?
-> `baseUrl` dan timeout default terpusat di `api_client.dart`. `CommentRepository` juga menetapkan timeout 10 detik secara eksplisit pada request komentar agar kontrak endpoint terlihat jelas; nilainya tetap konsisten dengan client.


5. Apakah test AI benar-benar menguji kasus field hilang, atau hanya happy path Tambahkan minimal 1 edge case sendiri.
-> Test `comment_test.dart` menguji edge case map JSON kosong. Test memverifikasi seluruh field memakai nilai default saat field hilang, bukan hanya happy path.


6. Jalankan flutter analyze dan flutter test, apakah hasil AI lolos tanpa warning?
-> `flutter analyze` berhasil tanpa masalah. Test `comment_test.dart` berhasil. `flutter test` masih gagal pada `widget_test.dart` lama karena test tersebut mengharapkan counter, sedangkan aplikasi sekarang menampilkan `PagedPostPage`; kegagalan ini tidak berasal dari comments layer.


# Checklist verifikasi mandiri
- [x] UI tidak memanggil Dio langsung; semua akses data lewat repository + provider.
- [x] Empat state tersedia: loading, error dengan retry, empty, dan success.
- [x] Pagination menambah data saat scroll, mencegah request ganda saat loading, dan menampilkan indikator akhir data.
- [x] `flutter analyze` selesai tanpa issue.
- [!] Test model/repository/provider lulus; `test/widget_test.dart` masih gagal karena merupakan test counter lama yang tidak sesuai dengan `PagedPostPage` saat ini.
- [x] Hasil verifikasi didokumentasikan pada [docs/verification.md](docs/verification.md).