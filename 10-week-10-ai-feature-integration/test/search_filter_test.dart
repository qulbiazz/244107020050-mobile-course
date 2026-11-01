import 'package:campus_notify/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notify/features/announcements/domain/usecases/search_announcements.dart';
import 'package:campus_notify/features/announcements/presentation/providers/announcement_provider.dart';
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
      content: 'Ruang kuliah dipindahkan.',
      createdAt: DateTime(2026, 10, 24),
    ),
  ];

  const searchAnnouncements = SearchAnnouncements();

  group('SearchAnnouncements', () {
    test('mengembalikan pengumuman dengan judul yang cocok', () {
      final result = searchAnnouncements(announcements, 'ujian');

      expect(result.map((announcement) => announcement.id), ['1']);
    });

    test('pencarian tidak membedakan huruf besar dan kecil', () {
      final result = searchAnnouncements(announcements, 'KULIAH');

      expect(result.map((announcement) => announcement.id), ['2']);
    });

    test('query kosong mengembalikan seluruh pengumuman', () {
      final result = searchAnnouncements(announcements, '  ');

      expect(result, announcements);
    });

    test('query tanpa hasil mengembalikan daftar kosong', () {
      final result = searchAnnouncements(announcements, 'beasiswa');

      expect(result, isEmpty);
    });
  });

  testWidgets('empty state menampilkan pesan saat pencarian tanpa hasil', (
    tester,
  ) async {
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

    await tester.enterText(
      find.byKey(const Key('announcement-search-field')),
      'beasiswa',
    );
    await tester.pump();

    expect(find.text('Pengumuman tidak ditemukan'), findsOneWidget);
  });
}

class _TestAnnouncementNotifier extends AnnouncementNotifier {
  _TestAnnouncementNotifier(this._announcements);

  final List<Announcement> _announcements;

  @override
  List<Announcement> build() => _announcements;
}
