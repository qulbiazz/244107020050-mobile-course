import 'package:campus_notify/features/announcements/presentation/providers/announcement_provider.dart';
import 'package:campus_notify/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notify/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final announcements = [
    Announcement(
      id: '1',
      title: 'Jadwal Ujian Tengah Semester',
      content: 'Ujian dimulai pekan depan.',
      createdAt: DateTime(2026, 10, 25),
    ),
    Announcement(
      id: '2',
      title: 'Perubahan Ruang Kuliah',
      content: 'Jadwal ujian telah diperbarui.',
      createdAt: DateTime(2026, 10, 24),
    ),
  ];

  Future<void> pumpHomePage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          announcementProvider.overrideWith(
            () => _TestAnnouncementNotifier(announcements),
          ),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );
  }

  testWidgets(
    'pencarian menampilkan judul yang cocok tanpa membedakan kapital',
    (tester) async {
      await pumpHomePage(tester);

      await tester.enterText(
        find.byKey(const Key('announcement-search-field')),
        'UJIAN',
      );
      await tester.pump();

      expect(find.text('Jadwal Ujian Tengah Semester'), findsOneWidget);
      expect(find.text('Perubahan Ruang Kuliah'), findsNothing);
    },
  );

  testWidgets('pencarian tanpa hasil menampilkan empty state', (tester) async {
    await pumpHomePage(tester);

    await tester.enterText(
      find.byKey(const Key('announcement-search-field')),
      'beasiswa',
    );
    await tester.pump();

    expect(find.text('Pengumuman tidak ditemukan'), findsOneWidget);
  });

  testWidgets('menghapus kata kunci menampilkan kembali semua pengumuman', (
    tester,
  ) async {
    await pumpHomePage(tester);

    final searchField = find.byKey(const Key('announcement-search-field'));
    await tester.enterText(searchField, 'UJIAN');
    await tester.pump();
    await tester.enterText(searchField, '');
    await tester.pump();

    expect(find.text('Jadwal Ujian Tengah Semester'), findsOneWidget);
    expect(find.text('Perubahan Ruang Kuliah'), findsOneWidget);
  });

  testWidgets('membuat ulang halaman menyelaraskan query dan kolom pencarian', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          announcementProvider.overrideWith(
            () => _TestAnnouncementNotifier(announcements),
          ),
        ],
        child: const MaterialApp(home: _SearchPageLifecycleHarness()),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('announcement-search-field')),
      'UJIAN',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('remove-home-page')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('restore-home-page')));
    await tester.pump();

    final searchField = tester.widget<TextField>(
      find.byKey(const Key('announcement-search-field')),
    );
    expect(searchField.controller?.text, 'UJIAN');
    expect(find.text('Jadwal Ujian Tengah Semester'), findsOneWidget);
    expect(find.text('Perubahan Ruang Kuliah'), findsNothing);
  });

  testWidgets('menambahkan pengumuman menutup form dan memperbarui daftar', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(child: const MaterialApp(home: HomePage())),
    );

    await tester.tap(find.text('Tambah Pengumuman'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Judul pengumuman'),
      'Pengumuman Baru',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Isi pengumuman'),
      'Isi pengumuman baru.',
    );
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Tambah Pengumuman'), findsOneWidget);
    expect(find.text('Pengumuman Baru'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _TestAnnouncementNotifier extends AnnouncementNotifier {
  _TestAnnouncementNotifier(this._announcements);

  final List<Announcement> _announcements;

  @override
  List<Announcement> build() => _announcements;
}

class _SearchPageLifecycleHarness extends StatefulWidget {
  const _SearchPageLifecycleHarness();

  @override
  State<_SearchPageLifecycleHarness> createState() =>
      _SearchPageLifecycleHarnessState();
}

class _SearchPageLifecycleHarnessState
    extends State<_SearchPageLifecycleHarness> {
  bool _showHomePage = true;

  @override
  Widget build(BuildContext context) {
    if (!_showHomePage) {
      return Scaffold(
        body: Center(
          child: TextButton(
            key: const Key('restore-home-page'),
            onPressed: () => setState(() => _showHomePage = true),
            child: const Text('Buka daftar'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            key: const Key('remove-home-page'),
            onPressed: () => setState(() => _showHomePage = false),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: const HomePage(),
    );
  }
}
