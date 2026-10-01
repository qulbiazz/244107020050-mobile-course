# AI Challenge

## Prompt yang digunakan

Aplikasi Flutter Campus Notification App.

Stack:
- firebase_messaging
- flutter_local_notifications
- flutter_secure_storage
- go_router
- Riverpod

Buatkan PushService dengan:
- requestPermission + getToken + onTokenRefresh
- onMessage
- onMessageOpenedApp
- getInitialMessage
- subscribe/unsubscribe topic pengumuman-kampus
- background handler top-level dengan @pragma('vm:entry-point')

Tandai bagian yang berbeda untuk Android 13+ dan iOS,
serta bagian yang tidak boleh mengakses BuildContext.


## Output awal AI

[Tempel kode awal yang diberikan AI]

## Perbaikan manual

1. Background handler dipastikan top-level.
2. Ditambahkan @pragma('vm:entry-point').
3. Foreground notification ditampilkan menggunakan
   flutter_local_notifications.
4. Ditambahkan getInitialMessage().
5. Ditambahkan onMessageOpenedApp.
6. Ditambahkan routeFromMessage().
7. Ditambahkan onTokenRefresh().
8. Token tidak dicetak secara penuh pada log.
9. Topic pengumuman-kampus digunakan untuk broadcast.

## Alasan teknis

Perbaikan dilakukan agar lifecycle FCM dapat menangani
foreground, background, dan terminated state serta
menghindari akses BuildContext pada background isolate.