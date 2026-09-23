import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';

import '../local/db.dart';
import '../local/post.dart';

class PostRepository {
  final Dio _dio = Dio();

  Future<Database> _openDb() async {
    return openNotesDb();
  }

  // ============================================================
  // BACA CACHE
  // ============================================================

  Future<List<Post>> readCachedPosts() async {
    final db = await _openDb();

    final rows = await db.query(
      'cached_posts',
      orderBy: 'id ASC',
    );

    return rows.map((row) {
      final payload = jsonDecode(
        row['payload'] as String,
      );

      return Post.fromJson(
        payload as Map<String, dynamic>,
      );
    }).toList();
  }

  // ============================================================
  // REFRESH DARI API
  // ============================================================

  Future<void> refreshPostsInBackground({
    required void Function() onRefreshComplete,
    bool forceOffline = false,
  }) async {
    if (forceOffline) {
      print('Force offline aktif. Tidak mengambil API.');
      return;
    }

    try {
      print('Mengambil data posts dari API...');

      final response = await _dio.get(
        'https://jsonplaceholder.typicode.com/posts',
      );

      final List<dynamic> data = response.data;

      final db = await _openDb();

      final batch = db.batch();

      for (final item in data) {
        final post = Post.fromJson(
          item as Map<String, dynamic>,
        );

        batch.insert(
          'cached_posts',
          {
            'id': post.id,
            'payload': jsonEncode(post.toJson()),
            'cached_at':
                DateTime.now().toIso8601String(),
          },
          conflictAlgorithm:
              ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);

      print(
        '${data.length} posts berhasil disimpan ke cache.',
      );

      onRefreshComplete();
    } catch (e) {
      print('Gagal refresh posts: $e');
    }
  }

  // ============================================================
  // CACHE-FIRST
  // ============================================================

  Future<List<Post>> loadPostsCacheFirst({
    required void Function() onRefreshComplete,
    bool forceOffline = false,
  }) async {
    // 1. Baca cache terlebih dahulu
    final cached = await readCachedPosts();

    // Jika belum ada cache dan tidak offline,
    // ambil data dari internet di background.
    //
    // Setelah berhasil, provider akan di-invalidate.
    if (cached.isEmpty && !forceOffline) {
      refreshPostsInBackground(
        onRefreshComplete: onRefreshComplete,
        forceOffline: forceOffline,
      );
    }

    // 2. Cache langsung dikembalikan
    return cached;
  }
}