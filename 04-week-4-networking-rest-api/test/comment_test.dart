import 'package:flutter_test/flutter_test.dart';
import 'package:networking_rest_api/data/models/comment.dart';

void main() {
  test('Comment.fromJson memakai default saat field hilang', () {
    // Map kosong mensimulasikan respons JSON dengan semua field tidak tersedia.
    final comment = Comment.fromJson({});

    // Nilai default memastikan UI tidak crash karena cast null.
    expect(comment.postId, 0);
    expect(comment.id, 0);
    expect(comment.name, '');
    expect(comment.email, '');
    expect(comment.body, '');
  });
}
