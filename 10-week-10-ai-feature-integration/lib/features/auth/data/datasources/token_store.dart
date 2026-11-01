import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStore {
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const quotaUserIdKey = 'ai_quota_user_id';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> save({
    required String access,
    required String refresh,
    String? quotaUserId,
  }) async {
    await _storage.write(key: _accessKey, value: access);

    await _storage.write(key: _refreshKey, value: refresh);
    if (quotaUserId != null) {
      await _storage.write(key: quotaUserIdKey, value: quotaUserId);
    } else if (await _storage.read(key: quotaUserIdKey) == null) {
      await _storage.write(
        key: quotaUserIdKey,
        value: sha256.convert(utf8.encode(access)).toString(),
      );
    }
  }

  Future<String?> readQuotaUserId() => _storage.read(key: quotaUserIdKey);

  Future<String?> readAccess() async {
    return _storage.read(key: _accessKey);
  }

  Future<String?> readRefresh() async {
    return _storage.read(key: _refreshKey);
  }

  Future<void> clear() async {
    final quotaUserId = await readQuotaUserId();
    if (quotaUserId != null && quotaUserId.isNotEmpty) {
      final cacheUserKey = sha256
          .convert(utf8.encode(quotaUserId))
          .toString()
          .substring(0, 24);
      await _storage.delete(key: 'ai_cache_$cacheUserKey');
    }
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: quotaUserIdKey);
  }
}
