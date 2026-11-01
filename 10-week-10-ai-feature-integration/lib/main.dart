import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/chat_screen.dart';
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
      final isLoginPage = state.matchedLocation == AppRoutes.login;

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
        path: AppRoutes.chat,
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: AppRoutes.announcement,
        builder:
            (context, state) =>
                AnnouncementPage(id: state.pathParameters['id'] ?? ''),
      ),
    ],
  );

  // Evaluasi ulang redirect saat status autentikasi berubah.
  ref.listen<AsyncValue<bool>>(authStateProvider, (previous, next) {
    router.refresh();
  });

  ref.onDispose(router.dispose);

  return router;
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: CampusNotifyApp()));
}

class CampusNotifyApp extends ConsumerStatefulWidget {
  const CampusNotifyApp({super.key, this.enablePushNotifications = true});

  final bool enablePushNotifications;

  @override
  ConsumerState<CampusNotifyApp> createState() => _CampusNotifyAppState();
}

class _CampusNotifyAppState extends ConsumerState<CampusNotifyApp> {
  String? _pushInitializationError;
  bool _pushSetupInProgress = false;

  @override
  void initState() {
    super.initState();

    if (!widget.enablePushNotifications) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initializePushNotifications();
    });
  }

  Future<void> _initializePushNotifications() async {
    if (_pushSetupInProgress) return;
    setState(() => _pushSetupInProgress = true);

    try {
      await Firebase.initializeApp();
      registerBackgroundHandler();
      await initLocalNotifications();

      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('NOTIFICATION PERMISSION: ${settings.authorizationStatus}');

      final token = await FirebaseMessaging.instance.getToken();
      debugPrint(
        token == null ? 'FCM token unavailable' : 'FCM token initialized',
      );
      await FirebaseMessaging.instance.subscribeToTopic('pengumuman-kampus');
      debugPrint('Subscribed to topic: pengumuman-kampus');

      if (!mounted) return;
      final router = ref.read(routerProvider);
      listenForeground((route) {
        router.go(route);
      });
      await handleTerminated((route) {
        router.go(route);
      });
      checkPendingDeepLink((route) {
        router.go(route);
      });

      setState(() => _pushInitializationError = null);
    } catch (error, stackTrace) {
      debugPrint('Push notification initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        setState(() {
          _pushInitializationError =
              'Notifikasi push tidak tersedia. Aplikasi tetap dapat digunakan.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _pushSetupInProgress = false);
      } else {
        _pushSetupInProgress = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Campus Notify',
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        final error = _pushInitializationError;
        if (error == null) return child ?? const SizedBox.shrink();

        return Column(
          children: [
            MaterialBanner(
              content: Text(error),
              leading: const Icon(Icons.notifications_off_outlined),
              actions: [
                TextButton(
                  onPressed:
                      _pushSetupInProgress
                          ? null
                          : _initializePushNotifications,
                  child: Text(
                    _pushSetupInProgress ? 'Memeriksa...' : 'Coba lagi',
                  ),
                ),
              ],
            ),
            Expanded(child: child ?? const SizedBox.shrink()),
          ],
        );
      },
    );
  }
}
