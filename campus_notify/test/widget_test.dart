import 'package:campus_notify/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Campus Notify dapat dibuat', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CampusNotifyApp());

    await tester.pump();

    expect(find.byType(CampusNotifyApp), findsOneWidget);
  });
}