import 'package:campus_notify/features/auth/data/datasources/token_store.dart';
import 'package:campus_notify/features/auth/data/repositories/auth_repository.dart';
import 'package:dio/dio.dart';

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
          // Bukan 401, teruskan error.
          if (error.response?.statusCode != 401) {
            return handler.next(error);
          }

          final request = error.requestOptions;

          // Jangan refresh request yang sama lebih dari sekali.
          if (request.extra['retried'] == true) {
            return handler.next(error);
          }

          request.extra['retried'] = true;

          try {
            final refreshToken = await tokenStore.readRefresh();

            // Refresh token tidak tersedia.
            if (refreshToken == null || refreshToken.isEmpty) {
              await tokenStore.clear();
              return handler.next(error);
            }

            // Minta access token baru.
            final newAccessToken =
                await authRepository.refresh(refreshToken);

            // Simpan access token baru dan pertahankan refresh token.
            await tokenStore.save(
              access: newAccessToken,
              refresh: refreshToken,
            );

            // Gunakan access token baru.
            request.headers['Authorization'] =
                'Bearer $newAccessToken';

            // Ulangi request sebelumnya.
            final response = await dio.fetch(request);

            return handler.resolve(response);
          } catch (_) {
            // Refresh gagal, hapus token.
            await tokenStore.clear();

            return handler.next(error);
          }
        },
      ),
    );
  }
}