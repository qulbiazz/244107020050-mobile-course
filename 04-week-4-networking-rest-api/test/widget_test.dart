import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:networking_rest_api/data/paged_posts.dart';
import 'package:networking_rest_api/main.dart';

class FakePagedPostsNotifier extends PagedPostsNotifier {
  @override
  PagedPostsState build() => const PagedPostsState(items: [], isLoading: false);
}

void main() {
  testWidgets('MyApp renders empty state shell without network', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [pagedPostsProvider.overrideWith(() => FakePagedPostsNotifier())],
        child: const MyApp(),
      ),
    );

    expect(find.text('Posts'), findsOneWidget);
    expect(find.text('Belum ada data.'), findsOneWidget);
  });
}
