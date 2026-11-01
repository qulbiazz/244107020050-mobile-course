import 'package:campus_notify/ai/ai_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiService.containsSensitiveData', () {
    test('blocks NIK values', () {
      expect(AiService.containsSensitiveData('NIK 1234567890123456'), isTrue);
    });

    test('blocks phone numbers', () {
      expect(AiService.containsSensitiveData('Hubungi 081234567890'), isTrue);
    });

    test('blocks address details and email addresses', () {
      expect(
        AiService.containsSensitiveData('Alamat rumah di Jalan Melati'),
        isTrue,
      );
      expect(AiService.containsSensitiveData('nama@example.com'), isTrue);
    });

    test('allows anonymous campus questions', () {
      expect(
        AiService.containsSensitiveData(
          'Bagaimana cara melihat pengumuman kampus?',
        ),
        isFalse,
      );
    });
  });

  group('AiService.containsSensitiveImageText', () {
    test('keeps images without recognized text on device', () {
      expect(AiService.containsSensitiveImageText(''), isTrue);
    });

    test('blocks recognized text containing personal data', () {
      expect(
        AiService.containsSensitiveImageText('NIK 1234567890123456'),
        isTrue,
      );
    });

    test('allows recognized text without detected personal data', () {
      expect(
        AiService.containsSensitiveImageText(
          'Pengumuman seminar kampus hari Senin',
        ),
        isFalse,
      );
    });
  });

  group('AI response and request safeguards', () {
    test('limits daily requests to a finite local budget', () {
      expect(AiService.requestsPerUserPerDay, 20);
    });

    test('rejects empty or non-informative responses', () {
      expect(AiService.isUsefulResponse(''), isFalse);
      expect(AiService.isUsefulResponse('Saya tidak tahu.'), isFalse);
      expect(
        AiService.isUsefulResponse(
          'Panduan kegiatan kampus dapat dilihat melalui pengumuman resmi.',
        ),
        isTrue,
      );
    });

    test('rejects responses with no meaningful overlap with the question', () {
      expect(
        AiService.isUsefulResponse(
          'Jadwal kegiatan olahraga berlangsung setiap hari Sabtu.',
          question: 'Bagaimana cara membayar biaya kuliah?',
        ),
        isFalse,
      );
    });
  });
}
