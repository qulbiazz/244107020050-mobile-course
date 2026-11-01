import 'dart:convert';

import 'package:crypto/crypto.dart';

class AuthSession {
  const AuthSession({
    required this.access,
    required this.refresh,
    required this.quotaUserId,
  });

  final String access;
  final String refresh;
  final String quotaUserId;
}

class AuthRepository {
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (!email.contains('@') || password.length < 6) {
      throw Exception('Email atau kata sandi tidak valid');
    }

    return AuthSession(
      access: 'mock-access-for-$email',
      refresh: 'mock-refresh-for-$email',
      quotaUserId:
          sha256.convert(utf8.encode(email.trim().toLowerCase())).toString(),
    );
  }

  Future<String> refresh(String refreshToken) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (refreshToken.isEmpty) {
      throw Exception('Refresh token hilang');
    }

    return 'mock-access-renewed-${DateTime.now().millisecondsSinceEpoch}';
  }
}
