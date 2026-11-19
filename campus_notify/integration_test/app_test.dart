import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:campus_notify/features/auth/data/datasources/token_store.dart';
import 'package:campus_notify/features/auth/presentation/providers/auth_provider.dart';
import 'package:campus_notify/main.dart';
import 'package:campus_notify/pages/home_page.dart';

class InMemoryTokenStore implements TokenStore {
  String? _access;
  String? _refresh;
  String? _quotaUserId;

  @override
  Future<void> save({
    required String access,
    required String refresh,
    String? quotaUserId,
  }) async {
    _access = access;
    _refresh = refresh;
    _quotaUserId = quotaUserId;
  }

  @override
  Future<String?> readAccess() async => _access;

  @override
  Future<String?> readRefresh() async => _refresh;

  @override
  Future<String?> readQuotaUserId() async => _quotaUserId;

  @override
  Future<void> clear() async {
    _access = null;
    _refresh = null;
    _quotaUserId = null;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Alur utama end-to-end: Login -> Beranda -> Tambah Pengumuman -> Pencarian -> Detail -> Logout',
    (tester) async {
      final fakeTokenStore = InMemoryTokenStore();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [tokenStoreProvider.overrideWithValue(fakeTokenStore)],
          child: const CampusNotifyApp(enablePushNotifications: false),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verifikasi halaman login tampil saat awal buka
      expect(find.text('Campus Notify'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);

      // 2. Input kredensial login yang valid
      final emailFinder = find.widgetWithText(TextField, 'Email');
      final passwordFinder = find.widgetWithText(TextField, 'Password');

      await tester.enterText(emailFinder, 'mahasiswa@kampus.ac.id');
      await tester.pumpAndSettle();

      await tester.enterText(passwordFinder, 'password123');
      await tester.pumpAndSettle();

      // 3. Tekan tombol Login
      final loginButtonFinder = find.widgetWithText(ElevatedButton, 'Login');
      await tester.tap(loginButtonFinder);

      // Tunggu simulasi login (Future.delayed 500ms) dan transisi navigasi
      await tester.pumpAndSettle(const Duration(milliseconds: 800));

      // 4. Verifikasi berhasil masuk ke HomePage
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.text('Belum ada pengumuman'), findsOneWidget);

      // 5. Buka dialog tambah pengumuman
      final fabFinder = find.text('Tambah Pengumuman');
      expect(fabFinder, findsOneWidget);
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      // 6. Isi formulir pengumuman
      final titleFieldFinder = find.widgetWithText(
        TextFormField,
        'Judul pengumuman',
      );
      final contentFieldFinder = find.widgetWithText(
        TextFormField,
        'Isi pengumuman',
      );

      await tester.enterText(
        titleFieldFinder,
        'Jadwal Kuliah Pengganti Mobile',
      );
      await tester.enterText(
        contentFieldFinder,
        'Kuliah pengganti dilaksanakan pada hari Sabtu pukul 08.00 WIB.',
      );
      await tester.pumpAndSettle();

      // 7. Simpan pengumuman
      final saveButtonFinder = find.text('Simpan');
      await tester.tap(saveButtonFinder);
      await tester.pumpAndSettle();

      // Verifikasi dialog tertutup dan pengumuman baru muncul di daftar
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Jadwal Kuliah Pengganti Mobile'), findsOneWidget);

      // 8. Uji interaksi pencarian
      final searchFieldFinder = find.byKey(
        const Key('announcement-search-field'),
      );
      await tester.enterText(searchFieldFinder, 'Pengganti');
      await tester.pumpAndSettle();

      expect(find.text('Jadwal Kuliah Pengganti Mobile'), findsOneWidget);

      // 9. Buka halaman detail pengumuman
      await tester.tap(find.text('Jadwal Kuliah Pengganti Mobile'));
      await tester.pumpAndSettle();

      expect(find.text('Detail Pengumuman'), findsOneWidget);
      expect(
        find.text(
          'Kuliah pengganti dilaksanakan pada hari Sabtu pukul 08.00 WIB.',
        ),
        findsOneWidget,
      );

      // 10. Navigasi kembali ke halaman utama
      final backButtonFinder = find.byType(BackButton);
      expect(backButtonFinder, findsOneWidget);
      await tester.tap(backButtonFinder);
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);

      // 11. Uji aksi Logout
      final logoutButtonFinder = find.byTooltip('Logout');
      expect(logoutButtonFinder, findsOneWidget);
      await tester.tap(logoutButtonFinder);
      await tester.pumpAndSettle();

      // Verifikasi kembali ke halaman login
      expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
    },
  );
}
