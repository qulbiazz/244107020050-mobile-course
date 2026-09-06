import 'package:flutter_test/flutter_test.dart';

import 'package:responsive_dashboard/main.dart';

void main() {
  testWidgets('Academic Overview tampil dengan benar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const AcademicOverviewApp());

    // Mengecek judul halaman
    expect(find.text('Academic Overview'), findsOneWidget);

    // Mengecek informasi profil
    expect(find.text('Qulbi Khutsi Azzumi'), findsOneWidget);
    expect(find.text('244107020050'), findsOneWidget);
    expect(find.text('D-IV Teknik Informatika'), findsNWidgets(2));

    // Mengecek empat kartu akademik
    expect(find.text('Assignments'), findsOneWidget);
    expect(find.text('Attendance'), findsOneWidget);
    expect(find.text('GPA'), findsOneWidget);
    expect(find.text('Current Week'), findsOneWidget);
  });
}