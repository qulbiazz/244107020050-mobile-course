import 'package:campus_notify/main.dart';
import 'package:campus_notify/routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Campus Notify dapat dibuat', (tester) async {
    final testRouter = GoRouter(
      initialLocation: AppRoutes.login,
      routes: [
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const Scaffold(
            body: Text('Halaman Login'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          routerProvider.overrideWith((ref) => testRouter),
        ],
        child: const CampusNotifyApp(),
      ),
    );

    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Halaman Login'), findsOneWidget);
  });
}