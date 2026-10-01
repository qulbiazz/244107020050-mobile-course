import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin _local =
    FlutterLocalNotificationsPlugin();

String? pendingDeepLink;

// ======================================================
// BACKGROUND FCM HANDLER
// ======================================================

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp();

  debugPrint(
    'Background message: ${message.messageId}',
  );

  debugPrint(
    'Background data: ${message.data}',
  );
}

void registerBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );
}

// ======================================================
// LOCAL NOTIFICATION
// ======================================================

Future<void> initLocalNotifications() async {
  const android = AndroidInitializationSettings(
    '@mipmap/ic_launcher',
  );

  const ios = DarwinInitializationSettings();

  await _local.initialize(
    const InitializationSettings(
      android: android,
      iOS: ios,
    ),
    onDidReceiveNotificationResponse: (response) {
      pendingDeepLink = response.payload;

      debugPrint(
        'Notification clicked: ${response.payload}',
      );
    },
  );

  final androidPlugin =
      _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  await androidPlugin?.requestNotificationsPermission();

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
  // Ambil token FCM saat ini
  final token =
      await FirebaseMessaging.instance.getToken();

  if (token != null) {
    await sendTokenToBackend(token);
  }

  // Pantau perubahan token
  FirebaseMessaging.instance.onTokenRefresh.listen(
    (newToken) async {
      debugPrint(
        'FCM TOKEN REFRESH: '
        '${newToken.substring(0, 12)}...',
      );

      await sendTokenToBackend(newToken);
    },
  );
}

// ======================================================
// KIRIM TOKEN KE BACKEND
// ======================================================

Future<void> sendTokenToBackend(String token) async {
  // Sementara masih simulasi.
  //
  // Jika backend sudah tersedia, bagian ini
  // dapat diganti dengan:
  //
  // await dio.post(
  //   '/devices',
  //   data: {
  //     'fcm_token': token,
  //     'platform': 'android',
  //   },
  // );

  debugPrint(
    'FCM TOKEN SENT TO BACKEND: '
    '${token.substring(0, 12)}...',
  );
}

// ======================================================
// FOREGROUND + BACKGROUND
// ======================================================

void listenForeground(
  void Function(String route) go,
) {
  // ----------------------------------------------
  // FOREGROUND
  // ----------------------------------------------

  FirebaseMessaging.onMessage.listen(
    (message) async {
      debugPrint(
        'FOREGROUND MESSAGE: ${message.messageId}',
      );

      debugPrint(
        'DATA: ${message.data}',
      );

      final route =
          message.data['route'] ?? '/';

      const androidDetails =
          AndroidNotificationDetails(
        'pengumuman',
        'Pengumuman Kampus',
        channelDescription:
            'Notifikasi pengumuman kampus',
        importance: Importance.high,
        priority: Priority.high,
      );

      await _local.show(
        message.hashCode,
        message.notification?.title ??
            'Pengumuman',
        message.notification?.body ??
            'Ada pengumuman baru',
        const NotificationDetails(
          android: androidDetails,
        ),
        payload: route,
      );
    },
  );

  // ----------------------------------------------
  // BACKGROUND
  // ----------------------------------------------

  FirebaseMessaging.onMessageOpenedApp.listen(
    (message) {
      debugPrint(
        'BACKGROUND NOTIFICATION CLICKED',
      );

      final route =
          message.data['route'] ?? '/';

      go(route);
    },
  );
}

// ======================================================
// TERMINATED
// ======================================================

Future<void> handleTerminated(
  void Function(String route) go,
) async {
  final initial =
      await FirebaseMessaging.instance.getInitialMessage();

  if (initial != null) {
    debugPrint(
      'TERMINATED NOTIFICATION CLICKED',
    );

    final route =
        initial.data['route'] ?? '/';

    go(route);
  }

  if (pendingDeepLink != null) {
    go(pendingDeepLink!);
    pendingDeepLink = null;
  }
}

// ======================================================
// LOCAL NOTIFICATION CLICK
// ======================================================

void checkPendingDeepLink(
  void Function(String route) go,
) {
  if (pendingDeepLink != null) {
    final route = pendingDeepLink!;

    pendingDeepLink = null;

    debugPrint(
      'OPENING PENDING DEEP LINK: $route',
    );

    go(route);
  }
}