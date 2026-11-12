import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/features/announcements/domain/entities/announcement.dart';
import 'package:campus_notify/features/announcements/domain/usecases/search_announcements.dart';

void main() {
  group('Announcement Entity Validation', () {
    test('membuat announcement berhasil jika data valid', () {
      final announcement = Announcement(
        id: 'ann-1',
        title: 'Seminar Nasional Teknologi',
        content: 'Seminar akan diselenggarakan di Gedung Serbaguna.',
        createdAt: DateTime(2026, 11, 10),
      );

      expect(announcement.id, 'ann-1');
      expect(announcement.title, 'Seminar Nasional Teknologi');
      expect(announcement.content, 'Seminar akan diselenggarakan di Gedung Serbaguna.');
    });

    test('menghapus spasi di awal dan akhir pada judul dan konten (edge case: trimming)', () {
      final announcement = Announcement(
        id: 'ann-2',
        title: '   Jadwal KRS Semester Genap   ',
        content: '   Pengisian KRS dibuka mulai tanggal 1.   ',
        createdAt: DateTime(2026, 11, 10),
      );

      expect(announcement.title, 'Jadwal KRS Semester Genap');
      expect(announcement.content, 'Pengisian KRS dibuka mulai tanggal 1.');
    });

    test('menolak judul kosong dengan ArgumentError (failure case)', () {
      expect(
        () => Announcement(
          id: 'ann-err-1',
          title: '',
          content: 'Konten pengumuman',
          createdAt: DateTime(2026, 11, 10),
        ),
        throwsArgumentError,
      );
    });

    test('menolak judul yang hanya berisi whitespace dengan ArgumentError (failure case)', () {
      expect(
        () => Announcement(
          id: 'ann-err-2',
          title: '   \t \n  ',
          content: 'Konten pengumuman',
          createdAt: DateTime(2026, 11, 10),
        ),
        throwsArgumentError,
      );
    });

    test('menolak konten pengumuman kosong dengan ArgumentError (failure case)', () {
      expect(
        () => Announcement(
          id: 'ann-err-3',
          title: 'Judul Valid',
          content: '',
          createdAt: DateTime(2026, 11, 10),
        ),
        throwsArgumentError,
      );
    });

    test('menolak konten pengumuman yang hanya berisi whitespace dengan ArgumentError (failure case)', () {
      expect(
        () => Announcement(
          id: 'ann-err-4',
          title: 'Judul Valid',
          content: '     ',
          createdAt: DateTime(2026, 11, 10),
        ),
        throwsArgumentError,
      );
    });
  });

  group('SearchAnnouncements Business Rules', () {
    final search = const SearchAnnouncements();
    final sampleAnnouncements = [
      Announcement(
        id: '1',
        title: 'Pengumuman Beasiswa Prestasi',
        content: 'Pendaftaran dibuka untuk mahasiswa berprestasi.',
        createdAt: DateTime(2026, 11, 1),
      ),
      Announcement(
        id: '2',
        title: 'Jadwal Ujian Akhir Semester',
        content: 'UAS akan dilaksanakan secara luring.',
        createdAt: DateTime(2026, 11, 2),
      ),
    ];

    test('mengembalikan pengumuman yang mengandung substring judul', () {
      final results = search(sampleAnnouncements, 'Beasiswa');
      expect(results.length, 1);
      expect(results.first.id, '1');
    });

    test('pencarian tidak peka terhadap huruf besar-kecil (case-insensitive)', () {
      final results = search(sampleAnnouncements, 'uJiAn');
      expect(results.length, 1);
      expect(results.first.id, '2');
    });

    test('query kosong atau hanya spasi mengembalikan seluruh daftar pengumuman (edge case)', () {
      final resultsEmpty = search(sampleAnnouncements, '');
      expect(resultsEmpty.length, 2);

      final resultsSpaces = search(sampleAnnouncements, '   ');
      expect(resultsSpaces.length, 2);
    });

    test('query yang tidak cocok menghasilkan daftar kosong (failure case)', () {
      final results = search(sampleAnnouncements, 'Pesta Wisuda Virtual');
      expect(results, isEmpty);
    });
  });
}
