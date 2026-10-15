
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/announcements/presentation/pages/announcement_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'messaging/push_service.dart';
import 'pages/home_page.dart';
import 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.login,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);

      // Tunggu pemeriksaan token awal selesai.
      if (authState.isLoading) {
        return null;
      }

      final isLoggedIn = authState.asData?.value ?? false;
      final isLoginPage =
          state.matchedLocation == AppRoutes.login;

      // Pengguna belum login diarahkan ke halaman login.
      if (!isLoggedIn && !isLoginPage) {
        return AppRoutes.login;
      }

      // Pengguna yang sudah login diarahkan ke halaman utama.
      if (isLoggedIn && isLoginPage) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.announcement,
        builder: (context, state) => AnnouncementPage(
          id: state.pathParameters['id'] ?? '',
        ),
      ),
    ],
  );

  // Evaluasi ulang redirect saat status autentikasi berubah.
  ref.listen<AsyncValue<bool>>(
    authStateProvider,
    (previous, next) {
      router.refresh();
    },
  );

  ref.onDispose(router.dispose);

  return router;
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inisialisasi Firebase.
  await Firebase.initializeApp();

  // 2. Registrasi background handler FCM.
  registerBackgroundHandler();

  // 3. Inisialisasi local notification.
  await initLocalNotifications();

  // 4. Meminta izin notifikasi.
  final settings =
      await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  debugPrint(
    'NOTIFICATION PERMISSION: '
    '${settings.authorizationStatus}',
  );

  // 5. Mengambil FCM token.
  final token = await FirebaseMessaging.instance.getToken();
  debugPrint('FCM TOKEN: $token');

  // 6. Subscribe ke topic pengumuman.
  await FirebaseMessaging.instance
      .subscribeToTopic('pengumuman-kampus');

  debugPrint('Subscribed to topic: pengumuman-kampus');

  // 7. Menjalankan aplikasi.
  runApp(
    const ProviderScope(
      child: CampusNotifyApp(),
    ),
  );
}

class CampusNotifyApp extends ConsumerStatefulWidget {
  const CampusNotifyApp({
    super.key,
    this.enablePushNotifications = true,
  });

  final bool enablePushNotifications;

  @override
  ConsumerState<CampusNotifyApp> createState() =>
      _CampusNotifyAppState();
}

class _CampusNotifyAppState
    extends ConsumerState<CampusNotifyApp> {
  @override
  void initState() {
    super.initState();

    // Nonaktifkan listener saat widget test jika diperlukan.
    if (!widget.enablePushNotifications) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final router = ref.read(routerProvider);

      // Notifikasi ketika aplikasi berada di foreground.
      listenForeground((route) {
        router.go(route);
      });

      // Notifikasi yang diklik ketika aplikasi terminated.
      handleTerminated((route) {
        router.go(route);
      });

      // Deep link dari local notification.
      checkPendingDeepLink((route) {
        router.go(route);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Campus Notify',
      routerConfig: ref.watch(routerProvider),
    );
  }
}
