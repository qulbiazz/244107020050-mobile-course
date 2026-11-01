import '../entities/announcement.dart';

class SearchAnnouncements {
  const SearchAnnouncements();

  List<Announcement> call(List<Announcement> announcements, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return announcements;

    return announcements
        .where(
          (announcement) =>
              announcement.title.toLowerCase().contains(normalizedQuery),
        )
        .toList();
  }
}
