import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/monitoring/telemetry_service.dart';
import '../features/announcements/domain/entities/announcement.dart';
import '../features/announcements/presentation/providers/announcement_provider.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../routes.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _showBetaTestingDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.science_outlined, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text('Beta Testing & Telemetry'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Versi: 1.2.0 (Build 3) - Beta Candidate\nTrack: Internal Testing\n\n'
                    'Pemicu telemetry ke Firebase Console:',
                    style: TextStyle(fontSize: 13),
                  ),
                  const Divider(height: 24),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(
                      Icons.analytics_outlined,
                      color: Colors.blue,
                    ),
                    title: const Text('Kirim Event Feedback Beta'),
                    subtitle: const Text(
                      'Event: beta_feedback_sent (Non-sensitif)',
                    ),
                    onTap: () async {
                      Navigator.pop(dialogContext);
                      await TelemetryService.instance.logBetaFeedbackSent(
                        screenName: 'home',
                        category: 'internal_tester_feedback',
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Event 'beta_feedback_sent' dicatat ke Firebase Analytics.",
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(
                      Icons.report_problem_outlined,
                      color: Colors.orange,
                    ),
                    title: const Text('Kirim Error Non-Fatal'),
                    subtitle: const Text(
                      'Uji laporan Firebase Crashlytics tanpa force close',
                    ),
                    onTap: () async {
                      Navigator.pop(dialogContext);
                      await TelemetryService.instance.recordNonFatalError(
                        error: StateError(
                          'Simulasi non-fatal error pengujian beta v1.2.0',
                        ),
                        reason:
                            'Verifikasi pipeline Crashlytics tester internal',
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Non-fatal error uji dikirim ke Crashlytics.',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: const Icon(
                      Icons.dangerous_outlined,
                      color: Colors.red,
                    ),
                    title: const Text('Simulasi Fatal Crash'),
                    subtitle: const Text(
                      'Uji penanganan crash fatal Crashlytics',
                    ),
                    onTap: () {
                      Navigator.pop(dialogContext);
                      showDialog<void>(
                        context: context,
                        builder:
                            (confirmContext) => AlertDialog(
                              title: const Text('Konfirmasi Simulasi Crash'),
                              content: const Text(
                                'Aplikasi akan dipaksa crash untuk memverifikasi pelaporan fatal Crashlytics. Lanjutkan?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed:
                                      () => Navigator.pop(confirmContext),
                                  child: const Text('Batal'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(confirmContext);
                                    TelemetryService.instance
                                        .triggerTestFatalCrash();
                                  },
                                  child: const Text(
                                    'Crash Sekarang',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Tutup'),
              ),
            ],
          ),
    );
  }

  Future<void> _showAddAnnouncementDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final announcement = await showDialog<Announcement>(
      context: context,
      builder: (_) => const _AddAnnouncementDialog(),
    );

    if (announcement == null || !context.mounted) return;

    ref.read(announcementProvider.notifier).add(announcement);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengumuman berhasil ditambahkan')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Notify'),
        actions: [
          IconButton(
            key: const Key('beta-telemetry-button'),
            tooltip: 'Beta Feedback & Telemetry',
            onPressed: () => _showBetaTestingDialog(context),
            icon: const Icon(Icons.bug_report_outlined),
          ),
          IconButton(
            tooltip: 'Asisten Kampus',
            onPressed: () => context.push(AppRoutes.chat),
            icon: const Icon(Icons.chat_outlined),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () {
              ref.read(authStateProvider.notifier).logout();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: const _AnnouncementList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAnnouncementDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Pengumuman'),
      ),
    );
  }
}

class _AnnouncementList extends StatelessWidget {
  const _AnnouncementList();

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      RepaintBoundary(child: _AnnouncementSearchField()),
      Expanded(child: _AnnouncementResults()),
    ],
  );
}

class _AnnouncementSearchField extends ConsumerStatefulWidget {
  const _AnnouncementSearchField();

  @override
  ConsumerState<_AnnouncementSearchField> createState() =>
      _AnnouncementSearchFieldState();
}

class _AnnouncementSearchFieldState
    extends ConsumerState<_AnnouncementSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(announcementSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(announcementSearchQueryProvider, (previous, query) {
      if (_controller.text == query) return;

      _controller.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    });

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        key: const Key('announcement-search-field'),
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'Cari pengumuman berdasarkan judul',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged:
            ref.read(announcementSearchQueryProvider.notifier).updateQuery,
      ),
    );
  }
}

class _AnnouncementResults extends ConsumerWidget {
  const _AnnouncementResults();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcements = ref.watch(filteredAnnouncementsProvider);
    final hasNoAnnouncements = ref.watch(
      announcementProvider.select((items) => items.isEmpty),
    );
    final isQueryEmpty = ref.watch(
      announcementSearchQueryProvider.select((query) => query.trim().isEmpty),
    );

    if (hasNoAnnouncements && isQueryEmpty) {
      return const _NoAnnouncements();
    }
    if (announcements.isEmpty) {
      return const Center(child: Text('Pengumuman tidak ditemukan'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: announcements.length,
      addAutomaticKeepAlives: false,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder:
          (context, index) =>
              _AnnouncementCard(announcement: announcements[index]),
    );
  }
}

class _NoAnnouncements extends StatelessWidget {
  const _NoAnnouncements();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada pengumuman',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tekan tombol + untuk menambahkan pengumuman.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.campaign_outlined)),
        title: Text(
          announcement.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(_formatDate(announcement.createdAt)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _openDetails(context),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  void _openDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _AnnouncementDetailPage(announcement: announcement),
      ),
    );
  }
}

class _AnnouncementDetailPage extends StatelessWidget {
  const _AnnouncementDetailPage({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pengumuman')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              announcement.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text('Dibuat pada ${_formatDate(announcement.createdAt)}'),
            const Divider(height: 32),
            Text(announcement.content, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}

class _AddAnnouncementDialog extends StatefulWidget {
  const _AddAnnouncementDialog();

  @override
  State<_AddAnnouncementDialog> createState() => _AddAnnouncementDialogState();
}

class _AddAnnouncementDialogState extends State<_AddAnnouncementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Judul pengumuman',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Judul wajib diisi';
        }
        return null;
      },
    );
  }

  Widget _buildContentField() {
    return TextFormField(
      controller: _contentController,
      maxLines: 4,
      decoration: const InputDecoration(
        labelText: 'Isi pengumuman',
        alignLabelWithHint: true,
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Isi pengumuman wajib diisi';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Pengumuman'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTitleField(),
              const SizedBox(height: 16),
              _buildContentField(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;

            final now = DateTime.now();
            Navigator.pop(
              context,
              Announcement(
                id: now.microsecondsSinceEpoch.toString(),
                title: _titleController.text.trim(),
                content: _contentController.text.trim(),
                createdAt: now,
              ),
            );
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
