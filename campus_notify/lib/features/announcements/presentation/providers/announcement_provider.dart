import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/announcement.dart';
import '../../domain/usecases/search_announcements.dart';

class AnnouncementNotifier extends Notifier<List<Announcement>> {
  @override
  List<Announcement> build() => [];

  void add(Announcement announcement) {
    state = [announcement, ...state];
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
