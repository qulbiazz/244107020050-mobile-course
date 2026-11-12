import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/pages/home_page.dart';

void main() {
  group('Uji UI Fitur Pengumuman (HomePage)', () {
    testWidgets('1. Periksa tampilan awal saat belum ada data pengumuman', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Memverifikasi elemen-elemen tampilan awal (Empty State)
      expect(find.text('Campus Notify'), findsOneWidget);
      expect(find.text('Belum ada pengumuman'), findsOneWidget);
      expect(find.text('Tekan tombol + untuk menambahkan pengumuman.'), findsOneWidget);
      expect(find.byIcon(Icons.campaign_outlined), findsOneWidget);
      expect(find.byKey(const Key('announcement-search-field')), findsOneWidget);
      expect(find.text('Tambah Pengumuman'), findsOneWidget);
    });

    testWidgets('2. Periksa masukan tidak valid pada form dialog tambah pengumuman', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Buka dialog tambah pengumuman
      await tester.tap(find.text('Tambah Pengumuman'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Judul pengumuman'), findsOneWidget);
      expect(find.text('Isi pengumuman'), findsOneWidget);

      // Coba simpan saat input kosong (masukan tidak valid)
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      // Pesan validasi harus muncul
      expect(find.text('Judul wajib diisi'), findsOneWidget);
      expect(find.text('Isi pengumuman wajib diisi'), findsOneWidget);

      // Dialog harus tetap terbuka dan pengumuman tidak tersimpan
      expect(find.byType(AlertDialog), findsOneWidget);

      // Coba masukkan hanya spasi pada input
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Judul pengumuman'),
        '    ',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Isi pengumuman'),
        '    ',
      );
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      // Pesan validasi tetap muncul
      expect(find.text('Judul wajib diisi'), findsOneWidget);
      expect(find.text('Isi pengumuman wajib diisi'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('3. Periksa tindakan pengguna yang berhasil menambah pengumuman', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Buka dialog
      await tester.tap(find.text('Tambah Pengumuman'));
      await tester.pumpAndSettle();

      // Masukkan data valid
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Judul pengumuman'),
        'Pendaftaran Seminar Android',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Isi pengumuman'),
        'Seminar akan dilaksanakan hari Sabtu jam 09:00 WIB.',
      );

      // Klik tombol Simpan
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      // Dialog tertutup
      expect(find.byType(AlertDialog), findsNothing);

      // SnackBar konfirmasi berhasil muncul
      expect(find.text('Pengumuman berhasil ditambahkan'), findsOneWidget);

      // Kartu pengumuman muncul di daftar
      expect(find.text('Pendaftaran Seminar Android'), findsOneWidget);
    });
  });
}
