import 'package:campus_notify/core/monitoring/telemetry_service.dart';
import 'package:campus_notify/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TelemetryService - Zero PII & Sanitization Test', () {
    final telemetry = TelemetryService.instance;

    test('sanitizeParameters mempertahankan parameter non-sensitif', () {
      final input = {
        'screen_name': 'home',
        'category': 'ui_performance',
        'count': 10,
        'app_version': '1.2.0',
      };

      final result = telemetry.sanitizeParameters(input);

      expect(result, isNotNull);
      expect(result!['screen_name'], 'home');
      expect(result['category'], 'ui_performance');
      expect(result['count'], 10);
      expect(result['app_version'], '1.2.0');
    });

    test('sanitizeParameters menyamarkan data pribadi / PII sensitif', () {
      final input = {
        'screen_name': 'login',
        'user_token': 'secret-jwt-token-xyz',
        'password_hash': 'mypassword123',
        'user_email': 'mahasiswa@polinema.ac.id',
        'nik_number': '3507123456780001',
        'phone_number': '08123456789',
      };

      final result = telemetry.sanitizeParameters(input);

      expect(result, isNotNull);
      expect(result!['screen_name'], 'login');
      expect(result['user_token'], '[REDACTED_SENSITIVE]');
      expect(result['password_hash'], '[REDACTED_SENSITIVE]');
      expect(result['user_email'], '[REDACTED_SENSITIVE]');
      expect(result['nik_number'], '[REDACTED_SENSITIVE]');
      expect(result['phone_number'], '[REDACTED_SENSITIVE]');
    });

    test(
      'logBetaFeedbackSent dan recordNonFatalError aman saat offline/test',
      () async {
        // Tidak boleh throw error ketika Firebase belum diinisialisasi
        await expectLater(
          telemetry.logBetaFeedbackSent(
            screenName: 'home',
            category: 'tester_review',
          ),
          completes,
        );

        await expectLater(
          telemetry.recordNonFatalError(
            error: Exception('Test exception'),
            reason: 'Unit test execution',
          ),
          completes,
        );
      },
    );
  });

  group('HomePage - Beta Testing Dialog UI Test', () {
    testWidgets(
      'menampilkan dialog Beta Testing & Telemetry saat tombol ditekan',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: HomePage())),
        );
        await tester.pumpAndSettle();

        final betaButton = find.byKey(const Key('beta-telemetry-button'));
        expect(betaButton, findsOneWidget);

        await tester.tap(betaButton);
        await tester.pumpAndSettle();

        expect(find.text('Beta Testing & Telemetry'), findsOneWidget);
        expect(find.text('Kirim Event Feedback Beta'), findsOneWidget);
        expect(find.text('Kirim Error Non-Fatal'), findsOneWidget);
        expect(find.text('Simulasi Fatal Crash'), findsOneWidget);

        // Uji tekan tombol Kirim Event Feedback Beta
        await tester.tap(find.text('Kirim Event Feedback Beta'));
        await tester.pumpAndSettle();

        expect(
          find.text(
            "Event 'beta_feedback_sent' dicatat ke Firebase Analytics.",
          ),
          findsOneWidget,
        );
      },
    );
  });
}
