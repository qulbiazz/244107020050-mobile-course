class AppRoutes {
  static const login = '/login';
  static const home = '/';
  static const chat = '/chat';
  static const announcement = '/pengumuman/:id';

  static String announcementDetail(String id) {
    return '/pengumuman/$id';
  }
}
