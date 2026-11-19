import '../../domain/entities/announcement.dart';
import '../../domain/repositories/announcement_repository.dart';

class InMemoryAnnouncementRepository implements AnnouncementRepository {
  InMemoryAnnouncementRepository([List<Announcement>? initial])
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
