import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

Dio createDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json'},
      contentType: 'application/json',
    ),
  );

  dio.interceptors.add(
    LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: false,
      responseHeader: false,
      responseBody: false,
      logPrint: (obj) => debugPrint(obj.toString()),
    ),
  );

  return dio;
}