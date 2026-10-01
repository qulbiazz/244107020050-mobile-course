import 'package:dio/dio.dart';

class ApiErrors {
  static String messageFromDioException(
    DioException exception,
  ) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi ke server timeout. Silakan coba lagi.';

      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa koneksi internet.';

      case DioExceptionType.badResponse:
        final statusCode =
            exception.response?.statusCode;

        switch (statusCode) {
          case 401:
            return 'Sesi login telah berakhir. Silakan login kembali.';

          case 403:
            return 'Anda tidak memiliki akses untuk melakukan tindakan ini.';

          case 404:
            return 'Data yang diminta tidak ditemukan.';

          case 500:
            return 'Terjadi kesalahan pada server. Silakan coba lagi nanti.';

          default:
            return 'Terjadi kesalahan pada server.';
        }

      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan.';

      case DioExceptionType.badCertificate:
        return 'Sertifikat server tidak valid.';

      case DioExceptionType.unknown:
        return 'Terjadi kesalahan. Silakan coba lagi.';
      case DioExceptionType.transformTimeout:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }
}