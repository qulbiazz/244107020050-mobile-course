import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:week3_todo/main.dart';

void main() {
  testWidgets('StatsPage menampilkan loading saat pertama kali dibuka',
      (WidgetTester tester) async {
    // Menjalankan aplikasi dengan ProviderScope
    // agar Riverpod dapat digunakan.
    await tester.pumpWidget(
      const ProviderScope(
        child: StatsApp(),
      ),
    );

    // Pada awal proses, data membutuhkan waktu 2 detik.
    // Maka UI seharusnya menampilkan CircularProgressIndicator.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}