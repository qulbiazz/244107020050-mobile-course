import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Layanan Telemetry dan Monitoring terpusat untuk Campus Notify.
/// Mengintegrasikan Firebase Crashlytics dan Firebase Analytics
/// dengan perlindungan privasi data pengguna (zero-PII policy).
class TelemetryService {
  TelemetryService._();

  static final TelemetryService instance = TelemetryService._();

  bool _isInitialized = false;

  /// Daftar kata kunci sensitif yang tidak boleh dikirim ke monitoring.
  static const List<String> sensitiveKeys = [
    'password',
    'token',
    'secret',
    'auth',
    'bearer',
    'email',
    'nik',
    'phone',
    'telepon',
    'ktp',
    'nim',
    'credit_card',
  ];

  /// Menginisialisasi Firebase Crashlytics and Platform error handlers.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (Firebase.apps.isEmpty) {
        debugPrint('[TelemetryService] Firebase belum diinisialisasi.');
        return;
      }

      // Mengaktifkan pengumpulan Crashlytics
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

      // Tangani unhandled Flutter framework errors (fatal error)
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

      // Tangani unhandled asynchronous platform errors (fatal error)
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      // Set atribut rilis dasar non-sensitif
      await FirebaseCrashlytics.instance.setCustomKey('environment', 'beta');
      await FirebaseCrashlytics.instance.setCustomKey('app_version', '1.2.0');
      await FirebaseCrashlytics.instance.setCustomKey('build_number', 3);

      _isInitialized = true;
      debugPrint(
        '[TelemetryService] Crashlytics & Analytics monitoring aktif.',
      );
    } catch (e, st) {
      debugPrint('[TelemetryService] Gagal menginisialisasi telemetry: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  /// Memeriksa dan membersihkan parameter agar bebas dari PII / data sensitif.
  Map<String, Object>? sanitizeParameters(Map<String, Object>? parameters) {
    if (parameters == null) return null;

    final sanitized = <String, Object>{};
    for (final entry in parameters.entries) {
      final keyLower = entry.key.toLowerCase();
      final isSensitive = sensitiveKeys.any((s) => keyLower.contains(s));

      if (isSensitive) {
        debugPrint(
          '[TelemetryService] PERINGATAN: Parameter "${entry.key}" disaring karena terindikasi data sensitif.',
        );
        sanitized[entry.key] = '[REDACTED_SENSITIVE]';
      } else {
        sanitized[entry.key] = entry.value;
      }
    }
    return sanitized;
  }

  /// Mencatat event Analytics non-sensitif.
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    final cleanParams = sanitizeParameters(parameters);
    debugPrint('[TelemetryService] Log Event: $name, parameters: $cleanParams');

    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAnalytics.instance.logEvent(
          name: name,
          parameters: cleanParams,
        );
      }
    } catch (e) {
      debugPrint('[TelemetryService] Gagal mencatat event $name: $e');
    }
  }

  /// Mencatat event pengiriman feedback beta.
  Future<void> logBetaFeedbackSent({
    required String screenName,
    String category = 'general',
  }) async {
    await logEvent(
      name: 'beta_feedback_sent',
      parameters: {'screen_name': screenName, 'category': category},
    );
  }

  /// Mencatat event fitur beta dibuka.
  Future<void> logBetaFeatureAccessed({required String featureName}) async {
    await logEvent(
      name: 'beta_feature_accessed',
      parameters: {'feature_name': featureName},
    );
  }

  /// Mengirim non-fatal error buatan untuk verifikasi Crashlytics.
  Future<void> recordNonFatalError({
    required dynamic error,
    StackTrace? stackTrace,
    String? reason,
  }) async {
    debugPrint(
      '[TelemetryService] Record Non-Fatal Error: $error (Reason: $reason)',
    );
    try {
      if (Firebase.apps.isNotEmpty) {
        await FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace ?? StackTrace.current,
          fatal: false,
          reason: reason,
        );
      }
    } catch (e) {
      debugPrint('[TelemetryService] Gagal merekam non-fatal error: $e');
    }
  }

  /// Memicu crash fatal buatan untuk pengujian Crashlytics (hanya pada build uji).
  void triggerTestFatalCrash() {
    debugPrint(
      '[TelemetryService] Memicu Crashlytics test crash (Fatal Simulation)...',
    );
    if (Firebase.apps.isNotEmpty) {
      FirebaseCrashlytics.instance.crash();
    } else {
      throw StateError('Simulasi fatal crash pengujian beta telemetry.');
    }
  }
}
