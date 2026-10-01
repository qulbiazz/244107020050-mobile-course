import 'package:campus_notify/data/token_store.dart';
import 'package:dio/dio.dart';

import 'auth_repository.dart';
// import '../storage/token_store.dart';

class ApiClient {
  final Dio dio;
  final TokenStore tokenStore;
  final AuthRepository authRepository;

  ApiClient({
    required this.dio,
    required this.tokenStore,
    required this.authRepository,
  }) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final accessToken = await tokenStore.readAccess();

          if (accessToken != null && accessToken.isNotEmpty) {
            options.headers['Authorization'] =
                'Bearer $accessToken';
          }

          handler.next(options);
        },

        onError: (error, handler) async {
          // Bukan 401 → teruskan error
          if (error.response?.statusCode != 401) {
            return handler.next(error);
          }

          final request = error.requestOptions;

          // Jangan refresh request yang sama lebih dari sekali
          if (request.extra['retried'] == true) {
            return handler.next(error);
          }

          request.extra['retried'] = true;

          try {
            final refreshToken =
                await tokenStore.readRefresh();

            // Refresh token tidak ada
            if (refreshToken == null ||
                refreshToken.isEmpty) {
              await tokenStore.clear();
              return handler.next(error);
            }

            // Minta access token baru
            final session =
                await authRepository.refresh(refreshToken);

            // Simpan token baru
            await tokenStore.save(
              access: session.access,
              refresh: session.refresh,
            );

            // Gunakan access token baru
            request.headers['Authorization'] =
                'Bearer ${session.access}';

            // Ulangi request sebelumnya
            final response = await dio.fetch(request);

            return handler.resolve(response);
          } catch (_) {
            // Refresh gagal → logout
            await tokenStore.clear();

            return handler.next(error);
          }
        },
      ),
    );
  }
}

extension on String {
  get access => null;

  get refresh => null;
}