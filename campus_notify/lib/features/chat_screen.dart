import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text_platform_interface/speech_to_text_platform_interface.dart'
    as stt_platform;

import '../ai/ai_service.dart';
import 'announcements/presentation/providers/announcement_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  final _speech = stt.SpeechToText();
  final _messages = <_ChatMessage>[];
  late final AiService _aiService;
  bool _isLoading = false;
  bool _speechReady = false;
  bool _offlineSpeechReady = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _aiService = AiService();
    unawaited(_initializeSpeech());
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    unawaited(_speech.stop());
    _aiService.close();
    super.dispose();
  }

  Future<void> _initializeSpeech() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }

    final ready = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        setState(() => _isListening = status == 'listening');
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengenalan suara tidak tersedia.')),
        );
      },
    );
    final offlineReady =
        ready &&
        await stt_platform.SpeechToTextPlatform.instance.hasOnDeviceSupport(
          localeId: 'id_ID',
        );
    if (mounted) {
      setState(() {
        _speechReady = ready;
        _offlineSpeechReady = offlineReady;
      });
    }
  }

  Future<void> _toggleSpeechRecognition() async {
    if (_isListening) {
      await _speech.stop();
      return;
    }

    if (!_speechReady || !_offlineSpeechReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pengenalan suara Bahasa Indonesia offline tidak tersedia di perangkat ini.',
          ),
        ),
      );
      return;
    }

    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        localeId: 'id_ID',
        listenFor: const Duration(seconds: 45),
        pauseFor: const Duration(seconds: 4),
        listenMode: stt.ListenMode.dictation,
        onDevice: true,
      ),
      onResult: (result) {
        if (!mounted) return;
        _textController.value = TextEditingValue(
          text: result.recognizedWords,
          selection: TextSelection.collapsed(
            offset: result.recognizedWords.length,
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isLoading) return;
    final image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (image == null || !mounted) return;

    setState(() => _isLoading = true);
    int? pendingResponseIndex;
    try {
      final imageFile = File(image.path);
      final text = await _aiService.recognizeText(imageFile);
      if (!mounted) return;

      if (text.isNotEmpty) {
        if (AiService.containsSensitiveImageText(text)) {
          _showLocalOcrResult(text);
          return;
        }

        final shouldExtract = await _confirmImageUpload(
          title: 'Ekstrak teks dengan AI?',
          message:
              'Pemeriksaan OCR lokal tidak mendeteksi pola data pribadi. '
              'Pastikan gambar tidak berisi NIK, nomor telepon, alamat, atau '
              'informasi sensitif sebelum mengunggahnya.',
          actionLabel: 'Ekstrak',
        );
        if (!mounted) return;
        if (!shouldExtract) {
          _showLocalOcrResult(text);
          return;
        }

        pendingResponseIndex = _appendImageRequest('Ekstrak teks dari gambar.');
        final extractedText = await _aiService.extractTextWithAi(imageFile);
        if (!mounted) return;
        _replaceMessage(
          pendingResponseIndex,
          _ChatMessage(isUser: false, text: extractedText),
        );
        return;
      }

      final shouldDescribe = await _confirmImageUpload(
        title: 'Deskripsikan gambar dengan AI?',
        message:
            'Tidak ada teks yang terdeteksi pada gambar. Pastikan gambar '
            'tidak memuat wajah, identitas, atau informasi pribadi sebelum '
            'gambar dikirim ke layanan AI.',
        actionLabel: 'Lanjutkan',
      );
      if (!shouldDescribe || !mounted) return;

      pendingResponseIndex = _appendImageRequest('Deskripsikan gambar saya.');
      final description = await _aiService.describeImage(imageFile);
      if (!mounted) return;
      _replaceMessage(
        pendingResponseIndex,
        _ChatMessage(isUser: false, text: description),
      );
    } on AiServiceException catch (error) {
      if (!mounted) return;
      if (pendingResponseIndex != null) {
        _replaceMessage(
          pendingResponseIndex,
          _ChatMessage(isUser: false, text: error.message),
        );
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } on Exception {
      if (!mounted) return;
      if (pendingResponseIndex != null) {
        _replaceMessage(
          pendingResponseIndex,
          const _ChatMessage(
            isUser: false,
            text: 'Gambar gagal diproses. Coba lagi.',
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gambar gagal diproses. Coba lagi.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _confirmImageUpload({
    required String title,
    required String message,
    required String actionLabel,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(title),
                content: Text(message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Batal'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(actionLabel),
                  ),
                ],
              ),
        ) ??
        false;
  }

  void _showLocalOcrResult(String text) {
    setState(() {
      _messages.add(
        const _ChatMessage(
          isUser: true,
          text: 'Gambar diproses secara lokal (tidak diunggah).',
        ),
      );
      _messages.add(
        _ChatMessage(isUser: false, text: 'Hasil OCR lokal:\n\n$text'),
      );
    });
    _scrollToBottom();
  }

  int _appendImageRequest(String prompt) {
    final responseIndex = _messages.length + 1;
    setState(() {
      _messages.add(_ChatMessage(isUser: true, text: prompt));
      _messages.add(const _ChatMessage(isUser: false, text: ''));
    });
    _scrollToBottom();
    return responseIndex;
  }

  void _replaceMessage(int index, _ChatMessage message) {
    setState(() => _messages[index] = message);
    _scrollToBottom();
  }

  Future<void> _showImagePicker() async {
    await showModalBottomSheet<void>(
      context: context,
      builder:
          (context) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: const Text('Ambil foto'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Pilih dari galeri'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _sendMessage() async {
    final prompt = _textController.text.trim();
    if (_isLoading || prompt.isEmpty) return;

    if (AiService.containsSensitiveData(prompt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Hapus NIK, nomor telepon, alamat, atau data pribadi lainnya sebelum mengirim.',
          ),
        ),
      );
      return;
    }

    _textController.clear();
    final responseIndex = _messages.length + 1;
    setState(() {
      _messages.add(_ChatMessage(isUser: true, text: prompt));
      _messages.add(const _ChatMessage(isUser: false, text: ''));
    });
    _scrollToBottom();

    await _requestAnswer(prompt, responseIndex);
  }

  Future<void> _retryAnswer(String prompt, int responseIndex) async {
    if (_isLoading) return;
    setState(() {
      _messages[responseIndex] = const _ChatMessage(isUser: false, text: '');
    });
    await _requestAnswer(prompt, responseIndex);
  }

  Future<void> _requestAnswer(String prompt, int responseIndex) async {
    setState(() => _isLoading = true);
    final response = StringBuffer();
    try {
      await for (final chunk in _aiService.askStream(prompt)) {
        if (!mounted) return;
        response.write(chunk);
        setState(() {
          _messages[responseIndex] = _ChatMessage(
            isUser: false,
            text: response.toString(),
          );
        });
        _scrollToBottom();
      }
      final completeResponse = response.toString();
      if (!AiService.isUsefulResponse(completeResponse, question: prompt)) {
        _replaceMessage(
          responseIndex,
          _ChatMessage(
            isUser: false,
            text: _localFallback(prompt),
            retryPrompt: prompt,
          ),
        );
      }
    } on AiServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _messages[responseIndex] = _ChatMessage(
          isUser: false,
          text: '${error.message}\n\n${_localFallback(prompt)}',
          retryPrompt: prompt,
        );
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _messages[responseIndex] = _ChatMessage(
          isUser: false,
          text: 'Layanan AI sedang bermasalah.\n\n${_localFallback(prompt)}',
          retryPrompt: prompt,
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _localFallback(String query) {
    final announcements = ref.read(announcementProvider);
    final queryTerms =
        RegExp(r'[a-z0-9]+')
            .allMatches(query.toLowerCase())
            .map((match) => match[0]!)
            .where(
              (term) => term.length > 2 && !_fallbackStopWords.contains(term),
            )
            .toSet();

    final matches =
        announcements
            .map((announcement) {
              final content =
                  '${announcement.title} ${announcement.content}'.toLowerCase();
              final score =
                  queryTerms.where((term) => content.contains(term)).length;
              return (announcement: announcement, score: score);
            })
            .where((match) => match.score > 0)
            .toList()
          ..sort((first, second) => second.score.compareTo(first.score));

    if (matches.isEmpty) {
      return announcements.isEmpty
          ? 'Mode offline: belum ada pengumuman lokal yang tersedia. '
              'Periksa koneksi lalu coba lagi.'
          : 'Mode offline: tidak ditemukan pengumuman lokal yang cocok. '
              'Periksa koneksi lalu coba lagi.';
    }

    final selected = matches
        .take(3)
        .map((match) {
          final announcement = match.announcement;
          return '• ${announcement.title}\n${announcement.content}';
        })
        .join('\n\n');
    return 'Mode offline — informasi dari pengumuman lokal:\n\n$selected';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asisten Kampus')),
      body: Column(
        children: [
          const _PrivacyNotice(),
          Expanded(
            child:
                _messages.isEmpty
                    ? const _EmptyChat()
                    : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return _MessageBubble(
                          message: message,
                          isStreaming:
                              _isLoading &&
                              !message.isUser &&
                              index == _messages.length - 1,
                          onRetry:
                              message.retryPrompt == null
                                  ? null
                                  : () =>
                                      _retryAnswer(message.retryPrompt!, index),
                        );
                      },
                    ),
          ),
          _MessageComposer(
            controller: _textController,
            isLoading: _isLoading,
            isListening: _isListening,
            onSend: _sendMessage,
            onPickImage: _showImagePicker,
            onToggleSpeech: _toggleSpeechRecognition,
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.isUser,
    required this.text,
    this.retryPrompt,
  });

  final bool isUser;
  final String text;
  final String? retryPrompt;
}

const _fallbackStopWords = {
  'apa',
  'bagaimana',
  'dengan',
  'dari',
  'dan',
  'di',
  'ke',
  'kampus',
  'saya',
  'tolong',
  'untuk',
  'yang',
};

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.secondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: const Row(
        children: [
          Icon(Icons.lock_outline, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Jangan kirim data pribadi. OCR dan suara diproses di perangkat. '
              'Gambar hanya diunggah setelah konfirmasi; cache lokal berlaku '
              '24 jam dan batas AI 20 request/hari per akun di perangkat ini.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48),
            SizedBox(height: 12),
            Text(
              'Ada yang bisa dibantu?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6),
            Text(
              'Tanyakan informasi umum seputar kegiatan dan layanan kampus.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isStreaming,
    this.onRetry,
  });

  final _ChatMessage message;
  final bool isStreaming;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final alignment =
        message.isUser ? Alignment.centerRight : Alignment.centerLeft;
    final backgroundColor =
        message.isUser ? colorScheme.primary : colorScheme.surfaceContainerHigh;
    final foregroundColor =
        message.isUser ? colorScheme.onPrimary : colorScheme.onSurface;

    return Align(
      alignment: alignment,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child:
            isStreaming && message.text.isEmpty
                ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: foregroundColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Sedang menjawab...',
                      style: TextStyle(color: foregroundColor),
                    ),
                  ],
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.text,
                      style: TextStyle(color: foregroundColor),
                    ),
                    if (onRetry != null)
                      TextButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Coba AI lagi'),
                        style: TextButton.styleFrom(
                          foregroundColor: foregroundColor,
                        ),
                      ),
                  ],
                ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.isLoading,
    required this.isListening,
    required this.onSend,
    required this.onPickImage,
    required this.onToggleSpeech,
  });

  final TextEditingController controller;
  final bool isLoading;
  final bool isListening;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final VoidCallback onToggleSpeech;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              tooltip: 'Pilih gambar',
              onPressed: isLoading ? null : onPickImage,
              icon: const Icon(Icons.add_photo_alternate_outlined),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: !isLoading,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: const InputDecoration(
                  hintText: 'Tulis pesan...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: isListening ? 'Berhenti merekam' : 'Input suara',
              onPressed: isLoading ? null : onToggleSpeech,
              icon: Icon(isListening ? Icons.stop_circle : Icons.mic_none),
            ),
            IconButton.filled(
              tooltip: isLoading ? 'Menunggu jawaban' : 'Kirim pesan',
              onPressed: isLoading ? null : onSend,
              icon:
                  isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
