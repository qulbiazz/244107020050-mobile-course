import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;

class AiService {
  AiService({http.Client? client}) : _client = client ?? http.Client();

  static const requestsPerUserPerDay = 20;
  static const _cacheLifetime = Duration(hours: 24);
  static const _maxCachedResponses = 20;
  static const _maxCachedResponseLength = 2000;
  static const systemPrompt =
      'Anda adalah Asisten Kampus untuk pertanyaan informasi umum. '
      'Gunakan bahasa Indonesia yang jelas dan ringkas. Jangan meminta, '
      'mengulang, atau menebak NIK, nomor telepon, alamat, kata sandi, '
      'identitas, maupun data pribadi. Jangan mengarang jadwal atau kebijakan '
      'kampus; jika informasi tidak tersedia, nyatakan keterbatasan dengan jelas.';
  static final _apiUrl = Uri.https(
    'generativelanguage.googleapis.com',
    '/v1beta/models/gemini-2.5-flash:streamGenerateContent',
    {'alt': 'sse'},
  );

  static final _sensitivePatterns = [
    RegExp(r'(?<!\d)(?:\d[\s.-]?){15}\d(?!\d)'),
    RegExp(r'(?<!\d)(?:\d[\s().-]*){8,}(?!\d)'),
    RegExp(r'(?<!\d)(?:\+?62|0)[\s().-]*8(?:[\s().-]*\d){7,12}(?!\d)'),
    RegExp(r'\b[\w.+-]+@[\w-]+(?:\.[\w-]+)+\b'),
    RegExp(
      r'\b(?:nik|ktp|nomor\s*(?:hp|ponsel|telepon)|no\.?\s*hp|alamat(?:\s+(?:rumah|lengkap|saya))?|(?:jalan|jl\.?|gang|gg\.?)\s+[a-z0-9]+|rt\s*[/.-]?\s*rw|kelurahan|kecamatan|kode\s*pos|password|kata\s*sandi|pin|token|rekening|kartu\s*kredit|cvv)\b',
      caseSensitive: false,
    ),
  ];

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final http.Client _client;
  static Future<void> _quotaWriteQueue = Future<void>.value();

  static bool containsSensitiveData(String text) =>
      _sensitivePatterns.any((pattern) => pattern.hasMatch(text));

  static bool shouldKeepImageOnDevice(String recognizedText) =>
      recognizedText.trim().isNotEmpty;

  static bool containsSensitiveImageText(String recognizedText) =>
      recognizedText.trim().isEmpty || containsSensitiveData(recognizedText);

  static bool isUsefulResponse(String response, {String? question}) {
    final normalized = response.trim().toLowerCase();
    if (normalized.length < 12) return false;
    if (RegExp(
      r'\b(?:saya tidak tahu|saya tidak dapat membantu|saya tidak bisa membantu|tidak relevan|i do not know|i cannot help)\b',
    ).hasMatch(normalized)) {
      return false;
    }

    if (question == null) return true;
    final questionTerms =
        RegExp(r'[a-z0-9]+')
            .allMatches(question.toLowerCase())
            .map((match) => match[0]!)
            .where(
              (term) => term.length > 3 && !_responseStopWords.contains(term),
            )
            .toSet();
    if (questionTerms.length < 2) return true;

    final responseTerms =
        RegExp(
          r'[a-z0-9]+',
        ).allMatches(normalized).map((match) => match[0]!).toSet();
    return questionTerms.any(responseTerms.contains);
  }

  static const _responseStopWords = {
    'adalah',
    'anda',
    'atau',
    'bagaimana',
    'dapat',
    'dengan',
    'dalam',
    'untuk',
    'yang',
  };

  Future<String> recognizeText(File imageFile) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(
        InputImage.fromFilePath(imageFile.path),
      );
      return result.text.trim();
    } finally {
      await recognizer.close();
    }
  }

  Future<String> describeImage(File imageFile) async {
    final recognizedText = await recognizeText(imageFile);
    if (shouldKeepImageOnDevice(recognizedText)) {
      throw const AiServiceException(
        'Gambar mengandung teks. Untuk menjaga privasi, gunakan hasil OCR lokal; gambar tidak diunggah ke AI.',
      );
    }

    await _ensureNoFaces(imageFile);
    return _sendImageRequest(
      imageFile,
      'Deskripsikan objek non-pribadi dalam gambar secara singkat. '
      'Jangan menebak identitas seseorang.',
    );
  }

  Future<String> extractTextWithAi(File imageFile) async {
    final recognizedText = await recognizeText(imageFile);
    if (containsSensitiveImageText(recognizedText)) {
      throw const AiServiceException(
        'Teks pada gambar mengandung atau mungkin mengandung data pribadi. '
        'Gunakan hasil OCR lokal; gambar tidak diunggah ke AI.',
      );
    }

    await _ensureNoFaces(imageFile);
    return _sendImageRequest(
      imageFile,
      'Ekstrak teks yang terbaca dari gambar. Jangan sertakan atau menebak '
      'data identitas, nomor telepon, alamat, maupun informasi pribadi.',
    );
  }

  Future<void> _ensureNoFaces(File imageFile) async {
    final faceDetector = FaceDetector(
      options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
    );
    try {
      final faces = await faceDetector.processImage(
        InputImage.fromFilePath(imageFile.path),
      );
      if (faces.isNotEmpty) {
        throw const AiServiceException(
          'Wajah terdeteksi. Gambar tidak diunggah untuk menjaga privasi.',
        );
      }
    } finally {
      await faceDetector.close();
    }
  }

  Future<String> _sendImageRequest(File imageFile, String prompt) async {
    final mimeType = _imageMimeType(imageFile.path);
    final imageBytes = await imageFile.readAsBytes();
    final encodedImage = base64Encode(imageBytes);
    final cacheKey =
        sha256.convert([
          ...utf8.encode(systemPrompt),
          ...utf8.encode(prompt),
          ...imageBytes,
        ]).toString();
    return _requestStream([
      {'text': prompt},
      {
        'inline_data': {'mime_type': mimeType, 'data': encodedImage},
      },
    ], cacheKey: cacheKey).join();
  }

  Future<String> ask(String question) => askStream(question).join();

  Stream<String> askStream(String question) async* {
    if (containsSensitiveData(question)) {
      throw const AiServiceException(
        'Pesan terdeteksi berisi data pribadi. Hapus data tersebut sebelum mengirim.',
      );
    }

    final cacheKey =
        sha256
            .convert(
              utf8.encode('$systemPrompt\n${question.trim().toLowerCase()}'),
            )
            .toString();
    yield* _requestStream(
      [
        {'text': question},
      ],
      cacheKey: cacheKey,
      question: question,
    );
  }

  Stream<String> _requestStream(
    List<Map<String, Object>> parts, {
    required String cacheKey,
    String? question,
  }) async* {
    final userId = await _storage.read(key: 'ai_quota_user_id');
    if (userId == null || userId.isEmpty) {
      throw const AiServiceException(
        'Identitas akun tidak tersedia. Silakan masuk kembali.',
      );
    }

    final userCacheKey = sha256
        .convert(utf8.encode(userId))
        .toString()
        .substring(0, 24);
    final cachedResponse = await _readCachedResponse(userCacheKey, cacheKey);
    if (cachedResponse != null) {
      yield cachedResponse;
      return;
    }

    final apiKey = await _storage.read(key: 'ai_api_key');
    if (apiKey == null || apiKey.isEmpty) {
      throw const AiServiceException(
        'API key tidak tersedia. Silakan atur di pengaturan.',
      );
    }

    await _consumeDailyRequest(userCacheKey);
    final request =
        http.Request('POST', _apiUrl)
          ..headers.addAll({
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          })
          ..body = jsonEncode({
            'system_instruction': {
              'parts': [
                {'text': systemPrompt},
              ],
            },
            'contents': [
              {'parts': parts},
            ],
          });

    final response = await _client
        .send(request)
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      await response.stream.drain<void>();
      throw AiServiceException(
        'Gagal memanggil layanan AI (HTTP ${response.statusCode}).',
      );
    }

    var receivedText = false;
    final completeResponse = StringBuffer();
    await for (final line in response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .timeout(const Duration(seconds: 45))) {
      if (!line.startsWith('data:')) continue;

      final payload = line.substring(5).trim();
      if (payload.isEmpty) continue;
      if (payload == '[DONE]') break;

      final event = jsonDecode(payload);
      if (event is! Map<String, dynamic>) {
        throw const AiServiceException('Respons AI tidak valid.');
      }

      final candidates = event['candidates'];
      if (candidates is! List) continue;

      for (final candidate in candidates) {
        if (candidate is! Map<String, dynamic>) continue;
        final content = candidate['content'];
        if (content is! Map<String, dynamic>) continue;
        final parts = content['parts'];
        if (parts is! List) continue;

        for (final part in parts) {
          if (part is! Map<String, dynamic>) continue;
          final text = part['text'];
          if (text is String && text.isNotEmpty) {
            receivedText = true;
            completeResponse.write(text);
            yield text;
          }
        }
      }
    }

    if (!receivedText) {
      throw const AiServiceException('Layanan AI tidak memberikan jawaban.');
    }

    final responseText = completeResponse.toString();
    if (question != null &&
        !isUsefulResponse(responseText, question: question)) {
      throw const AiServiceException(
        'Jawaban AI tidak cukup relevan. Beralih ke informasi lokal.',
      );
    }
    if (isUsefulResponse(responseText, question: question) &&
        responseText.length <= _maxCachedResponseLength &&
        !containsSensitiveData(responseText)) {
      await _writeCachedResponse(userCacheKey, cacheKey, responseText);
    }
  }

  Future<String?> _readCachedResponse(String userKey, String requestKey) async {
    final cache = await _readCache(userKey);
    final entry = cache[requestKey];
    if (entry is! Map<String, dynamic>) return null;

    final expiresAt = entry['expiresAt'];
    final response = entry['response'];
    if (expiresAt is! int ||
        expiresAt <= DateTime.now().millisecondsSinceEpoch ||
        response is! String) {
      cache.remove(requestKey);
      await _writeCache(userKey, cache);
      return null;
    }
    return response;
  }

  Future<void> _writeCachedResponse(
    String userKey,
    String requestKey,
    String response,
  ) async {
    final cache = await _readCache(userKey);
    cache[requestKey] = {
      'response': response,
      'expiresAt': DateTime.now().add(_cacheLifetime).millisecondsSinceEpoch,
    };
    if (cache.length > _maxCachedResponses) {
      final oldestKey = cache.keys.first;
      cache.remove(oldestKey);
    }
    await _writeCache(userKey, cache);
  }

  Future<Map<String, dynamic>> _readCache(String userKey) async {
    final serialized = await _storage.read(key: 'ai_cache_$userKey');
    if (serialized == null) return {};
    final decoded = jsonDecode(serialized);
    if (decoded is! Map<String, dynamic>) {
      throw const AiServiceException('Cache AI lokal tidak valid.');
    }
    return decoded;
  }

  Future<void> _writeCache(String userKey, Map<String, dynamic> cache) async {
    await _storage.write(key: 'ai_cache_$userKey', value: jsonEncode(cache));
  }

  Future<void> _consumeDailyRequest(String userKey) async {
    final previous = _quotaWriteQueue;
    final completion = Completer<void>();
    _quotaWriteQueue = completion.future;
    await previous;
    try {
      final now = DateTime.now();
      final date =
          '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';
      final storageKey = 'ai_requests_${userKey}_$date';
      final current = int.tryParse(await _storage.read(key: storageKey) ?? '0');
      if (current == null || current >= requestsPerUserPerDay) {
        throw const AiServiceException(
          'Batas 20 request AI harian tercapai. Coba lagi besok atau gunakan data lokal.',
        );
      }
      await _storage.write(key: storageKey, value: '${current + 1}');
    } finally {
      completion.complete();
    }
  }

  String _imageMimeType(String path) {
    final extension = path.split('.').last.toLowerCase();
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
  }

  Future<void> saveApiKey(String key) async {
    await _storage.write(key: 'ai_api_key', value: key);
  }

  void close() {
    _client.close();
  }
}

class AiServiceException implements Exception {
  const AiServiceException(this.message);

  final String message;
}
