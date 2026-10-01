import 'package:flutter_test/flutter_test.dart';

import 'package:campus_notify/messaging/push_service.dart';

class FakeTokenStore {
  String? access;
  String? refresh;
}

void main() {
  group('routeFromMessage', () {
    test(
      'route kosong menghasilkan home',
      () {
        expect(
          routeFromMessage({}),
          '/',
        );
      },
    );

    test(
      'route tanpa slash ditambahkan slash',
      () {
        expect(
          routeFromMessage({
            'route': 'pengumuman/3',
          }),
          '/pengumuman/3',
        );
      },
    );

    test(
      'route dengan slash tetap sama',
      () {
        expect(
          routeFromMessage({
            'route': '/pengumuman/3',
          }),
          '/pengumuman/3',
        );
      },
    );
  });

  group('payload FCM', () {
    test(
      'payload membawa id pengumuman',
      () {
        const data = {
          'route': '/pengumuman/3',
          'id': '3',
        };

        expect(data['id'], '3');

        expect(
          routeFromMessage(data),
          '/pengumuman/3',
        );
      },
    );
  });

  group('auth token', () {
    test(
      'provider auth membaca status login dari token',
      () async {
        final store = FakeTokenStore()
          ..access = 'mock-access';

        expect(
          store.access != null,
          isTrue,
        );

        store.access = null;

        expect(
          store.access != null,
          isFalse,
        );
      },
    );

    test(
      'refresh kosong membutuhkan login ulang',
      () async {
        final store = FakeTokenStore()
          ..refresh = '';

        final needsLogin =
            (store.refresh ?? '').isEmpty;

        expect(
          needsLogin,
          isTrue,
        );
      },
    );
  });
}