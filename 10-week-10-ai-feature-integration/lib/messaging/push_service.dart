import 'package:campus_notify/routes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin _local =
    FlutterLocalNotificationsPlugin();

String? pendingDeepLink;

// ======================================================
// ROUTE PARSER
// ======================================================

String routeFromMessage(Map<String, dynamic> data) {
  final route = data['route']?.toString() ?? '/';

  if (route.isEmpty || route == '/') {
    return AppRoutes.home;
  }

  return route.startsWith('/') ? route : '/$route';
}

// ======================================================
// BACKGROUND FCM HANDLER
// ======================================================

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  debugPrint('BACKGROUND MESSAGE: ${message.messageId}');

  debugPrint('BACKGROUND DATA: ${message.data}');
}

void registerBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

// ======================================================
// LOCAL NOTIFICATION
// ======================================================

Future<void> initLocalNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

  const iosSettings = DarwinInitializationSettings();

  const initializationSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await _local.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (response) {
      final payload = response.payload;

      debugPrint('LOCAL NOTIFICATION CLICKED: $payload');

      if (payload != null && payload.isNotEmpty) {
        pendingDeepLink = payload;
      }
    },
  );

  // Android 13+
  final androidPlugin =
      _local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

  await androidPlugin?.requestNotificationsPermission();

  // Notification channel
  const channel = AndroidNotificationChannel(
    'pengumuman',
    'Pengumuman Kampus',
    description: 'Notifikasi pengumuman kampus',
    importance: Importance.high,
  );

  await androidPlugin?.createNotificationChannel(channel);
}

// ======================================================
// FCM TOKEN LIFECYCLE
// ======================================================

Future<void> initFcmToken() async {
  // ----------------------------------------------
  // TOKEN SAAT INI
  // ----------------------------------------------

  final token = await FirebaseMessaging.instance.getToken();

  if (token != null) {
    debugPrint('FCM TOKEN: ${maskToken(token)}');

    await sendTokenToBackend(token);
  }

  // ----------------------------------------------
  // TOKEN REFRESH
  // ----------------------------------------------

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    debugPrint('FCM TOKEN REFRESH: ${maskToken(newToken)}');

    await sendTokenToBackend(newToken);
  });
}

// ======================================================
// TOKEN MASKING
// ======================================================

String maskToken(String token) {
  if (token.length <= 12) {
    return '***';
  }

  return '${token.substring(0, 12)}...';
}

// ======================================================
// SEND TOKEN TO BACKEND
// ======================================================

Future<void> sendTokenToBackend(String token) async {
  /*
   * Untuk sementara masih simulasi.
   *
   * Jika backend sudah tersedia, ubah menjadi:
   *
   * await dio.post(
   *   '/devices',
   *   data: {
   *     'fcm_token': token,
   *     'platform': 'android',
   *   },
   * );
   */

  debugPrint('FCM TOKEN SENT TO BACKEND: ${maskToken(token)}');
}

// ======================================================
// TOPIC
// ======================================================

Future<void> subscribeToAnnouncementTopic() async {
  await FirebaseMessaging.instance.subscribeToTopic('pengumuman-kampus');

  debugPrint('SUBSCRIBED TO TOPIC: pengumuman-kampus');
}

Future<void> unsubscribeFromAnnouncementTopic() async {
  await FirebaseMessaging.instance.unsubscribeFromTopic('pengumuman-kampus');

  debugPrint('UNSUBSCRIBED FROM TOPIC: pengumuman-kampus');
}

// ======================================================
// FOREGROUND + BACKGROUND CLICK
// ======================================================

void listenForeground(void Function(String route) go) {
  // ==================================================
  // FOREGROUND
  // ==================================================

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    debugPrint('FOREGROUND MESSAGE: ${message.messageId}');

    debugPrint('FOREGROUND DATA: ${message.data}');

    final route = routeFromMessage(message.data);

    final title = message.notification?.title ?? 'Pengumuman';

    final body = message.notification?.body ?? 'Ada pengumuman baru';

    const androidDetails = AndroidNotificationDetails(
      'pengumuman',
      'Pengumuman Kampus',
      channelDescription: 'Notifikasi pengumuman kampus',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    await _local.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(android: androidDetails),
      payload: route,
    );
  });

  // ==================================================
  // BACKGROUND -> USER CLICK NOTIFICATION
  // ==================================================

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('BACKGROUND NOTIFICATION CLICKED');

    debugPrint('CLICKED DATA: ${message.data}');

    final route = routeFromMessage(message.data);

    debugPrint('NAVIGATE TO: $route');

    go(route);
  });
}

// ======================================================
// TERMINATED
// ======================================================

Future<void> handleTerminated(void Function(String route) go) async {
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();

  if (initialMessage != null) {
    debugPrint('TERMINATED NOTIFICATION CLICKED');

    debugPrint('TERMINATED DATA: ${initialMessage.data}');

    final route = routeFromMessage(initialMessage.data);

    debugPrint('NAVIGATE TO: $route');

    go(route);
  }

  // ==================================================
  // LOCAL NOTIFICATION DEEP LINK
  // ==================================================

  if (pendingDeepLink != null) {
    final route = pendingDeepLink!;

    pendingDeepLink = null;

    debugPrint('OPENING PENDING DEEP LINK: $route');

    go(route);
  }
}

// ======================================================
// CHECK LOCAL NOTIFICATION DEEP LINK
// ======================================================

void checkPendingDeepLink(void Function(String route) go) {
  if (pendingDeepLink == null) {
    return;
  }

  final route = pendingDeepLink!;

  pendingDeepLink = null;

  debugPrint('OPENING PENDING DEEP LINK: $route');

  go(route);
}
