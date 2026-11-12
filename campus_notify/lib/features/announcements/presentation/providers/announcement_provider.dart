import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/in_memory_announcement_repository.dart';
import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';
import '../../domain/usecases/search_announcements.dart';

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return InMemoryAnnouncementRepository();
});

class AnnouncementNotifier extends Notifier<List<Announcement>> {
  @override
  List<Announcement> build() => [];

  Future<void> loadFromRepository() async {
    final repository = ref.read(announcementRepositoryProvider);
    final items = await repository.getAnnouncements();
    state = items;
  }

  void add(Announcement announcement) {
    state = [announcement, ...state];
    ref.read(announcementRepositoryProvider).addAnnouncement(announcement);
  }
}

final announcementProvider =
    NotifierProvider<AnnouncementNotifier, List<Announcement>>(
      AnnouncementNotifier.new,
    );

class AnnouncementSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) {
    state = query;
  }
}

final announcementSearchQueryProvider =
    NotifierProvider<AnnouncementSearchNotifier, String>(
      AnnouncementSearchNotifier.new,
    );

final searchAnnouncementsProvider = Provider<SearchAnnouncements>(
  (ref) => const SearchAnnouncements(),
);

final filteredAnnouncementsProvider = Provider<List<Announcement>>((ref) {
  final announcements = ref.watch(announcementProvider);
  final query = ref.watch(announcementSearchQueryProvider);
  final searchAnnouncements = ref.watch(searchAnnouncementsProvider);

  return searchAnnouncements(announcements, query);
});
