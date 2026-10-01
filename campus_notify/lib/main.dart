import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'messaging/push_service.dart';
import 'pages/announcement_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) {
          return const LoginPage();
        },
      ),

      GoRoute(
        path: '/',
        builder: (context, state) {
          return const HomePage();
        },
      ),

      GoRoute(
        path: '/pengumuman/:id',
        builder: (context, state) {
          return AnnouncementPage(
            id: state.pathParameters['id'] ?? '',
          );
        },
      ),
    ],
  );
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase
  await Firebase.initializeApp();

  // 2. Background FCM handler
  registerBackgroundHandler();

  // 3. Local notification
  await initLocalNotifications();

  // 4. Permission
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

  // 5. Ambil FCM Token
  final token =
      await FirebaseMessaging.instance.getToken();

  debugPrint('FCM TOKEN: $token');

  // 6. Subscribe topic
  await FirebaseMessaging.instance
      .subscribeToTopic('pengumuman-kampus');

  debugPrint(
    'Subscribed to topic: pengumuman-kampus',
  );

  runApp(
    const ProviderScope(
      child: CampusNotifyApp(),
    ),
  );
}

class CampusNotifyApp extends ConsumerStatefulWidget {
  const CampusNotifyApp({super.key});

  @override
  ConsumerState<CampusNotifyApp> createState() =>
      _CampusNotifyAppState();
}

class _CampusNotifyAppState
    extends ConsumerState<CampusNotifyApp> {

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = ref.read(routerProvider);

      // Foreground + background click
      listenForeground((route) {
        router.go(route);
      });

      // Terminated
      handleTerminated((route) {
        router.go(route);
      });

      // Jika local notification diklik
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