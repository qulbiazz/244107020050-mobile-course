import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notify/features/announcements/domain/repositories/announcement_repository.dart';
import 'package:campus_notify/features/announcements/presentation/providers/announcement_provider.dart';

class FakeSuccessAnnouncementRepository implements AnnouncementRepository {
  FakeSuccessAnnouncementRepository([List<Announcement>? initial])
    : _items =
          initial != null ? List<Announcement>.from(initial) : <Announcement>[];

  final List<Announcement> _items;

  @override
  Future<List<Announcement>> getAnnouncements() async {
    return List<Announcement>.unmodifiable(_items);
  }

  @override
  Future<void> addAnnouncement(Announcement announcement) async {
    _items.insert(0, announcement);
  }
}

class FakeErrorAnnouncementRepository implements AnnouncementRepository {
  @override
  Future<List<Announcement>> getAnnouncements() async {
    throw Exception('Gagal memuat pengumuman: Server offline');
  }

  @override
  Future<void> addAnnouncement(Announcement announcement) async {
    throw Exception('Gagal menyimpan pengumuman: Koneksi terputus');
  }
}

void main() {
  group('FakeSuccessAnnouncementRepository (Skenario Sukses)', () {
    test('mengembalikan daftar pengumuman awal', () async {
      final initialData = [
        Announcement(
          id: '1',
          title: 'Pengumuman Kuliah',
          content: 'Kuliah ditiadakan hari ini.',
          createdAt: DateTime(2026, 11, 10),
        ),
      ];
      final repo = FakeSuccessAnnouncementRepository(initialData);

      final result = await repo.getAnnouncements();

      expect(result.length, 1);
      expect(result.first.title, 'Pengumuman Kuliah');
    });

    test('berhasil menambahkan pengumuman baru ke repositori', () async {
      final repo = FakeSuccessAnnouncementRepository();
      final newAnnouncement = Announcement(
        id: '2',
        title: 'Pengumuman Lomba',
        content: 'Pendaftaran lomba dibuka.',
        createdAt: DateTime(2026, 11, 11),
      );

      await repo.addAnnouncement(newAnnouncement);
      final items = await repo.getAnnouncements();

      expect(items.length, 1);
      expect(items.first.id, '2');
      expect(items.first.title, 'Pengumuman Lomba');
    });
  });

  group('FakeErrorAnnouncementRepository (Skenario Error / Kegagalan)', () {
    test(
      'getAnnouncements melemparkan Exception saat server offline',
      () async {
        final repo = FakeErrorAnnouncementRepository();

        expect(
          () async => await repo.getAnnouncements(),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Gagal memuat pengumuman: Server offline'),
            ),
          ),
        );
      },
    );

    test(
      'addAnnouncement melemparkan Exception saat koneksi terputus',
      () async {
        final repo = FakeErrorAnnouncementRepository();
        final item = Announcement(
          id: '99',
          title: 'Pengumuman Darurat',
          content: 'Server sedang mengalami gangguan.',
          createdAt: DateTime(2026, 11, 12),
        );

        expect(
          () async => await repo.addAnnouncement(item),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Gagal menyimpan pengumuman: Koneksi terputus'),
            ),
          ),
        );
      },
    );
  });

  group('Provider dengan Fake Repository', () {
    test('loadFromRepository memperbarui state notifier saat sukses', () async {
      final sample = [
        Announcement(
          id: 'test-1',
          title: 'Judul Percobaan',
          content: 'Konten percobaan',
          createdAt: DateTime(2026, 11, 12),
        ),
      ];
      final successRepo = FakeSuccessAnnouncementRepository(sample);

      final container = ProviderContainer(
        overrides: [
          announcementRepositoryProvider.overrideWithValue(successRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(announcementProvider.notifier);
      await notifier.loadFromRepository();

      final state = container.read(announcementProvider);
      expect(state.length, 1);
      expect(state.first.title, 'Judul Percobaan');
    });

    test(
      'loadFromRepository melempar error saat repository mengalami kegagalan',
      () async {
        final errorRepo = FakeErrorAnnouncementRepository();

        final container = ProviderContainer(
          overrides: [
            announcementRepositoryProvider.overrideWithValue(errorRepo),
          ],
        );
        addTearDown(container.dispose);

        final notifier = container.read(announcementProvider.notifier);

        expect(
          () async => await notifier.loadFromRepository(),
          throwsA(isA<Exception>()),
        );
      },
    );
  });
}
