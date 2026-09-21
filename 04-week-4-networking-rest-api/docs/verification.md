# Verification Checklist

Tanggal verifikasi: 2026-09-21

- [✓] UI tidak memanggil Dio secara langsung. Data diakses melalui provider dan repository.
- [✓] State loading, error dengan retry, empty, dan success tersedia pada alur daftar post.
- [✓] Pagination menambah halaman saat mendekati akhir, mengabaikan request saat loading, dan menampilkan pesan saat semua data termuat.
- [✓] `flutter analyze` berhasil dengan `No issues found!`.
- [✓] `flutter test test/comment_test.dart` berhasil.
- [✓] Test model, repository, provider, dan error message pada `test/post_test.dart` berhasil.