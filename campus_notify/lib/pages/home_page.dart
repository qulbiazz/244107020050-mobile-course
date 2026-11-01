import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/announcements/domain/entities/announcement.dart';
import '../features/announcements/presentation/providers/announcement_provider.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../routes.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

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

class _AnnouncementList extends ConsumerWidget {
  const _AnnouncementList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcements = ref.watch(announcementProvider);
    final query = ref.watch(announcementSearchQueryProvider);
    final filteredAnnouncements = ref.watch(filteredAnnouncementsProvider);

    return Column(
      children: [
        _AnnouncementSearchField(
          query: query,
          onChanged:
              ref.read(announcementSearchQueryProvider.notifier).updateQuery,
        ),
        Expanded(
          child: _AnnouncementResults(
            announcements: filteredAnnouncements,
            hasNoAnnouncements: announcements.isEmpty,
            query: query,
          ),
        ),
      ],
    );
  }
}

class _AnnouncementSearchField extends StatefulWidget {
  const _AnnouncementSearchField({
    required this.query,
    required this.onChanged,
  });

  final String query;
  final ValueChanged<String> onChanged;

  @override
  State<_AnnouncementSearchField> createState() =>
      _AnnouncementSearchFieldState();
}

class _AnnouncementSearchFieldState extends State<_AnnouncementSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant _AnnouncementSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text != widget.query) {
      _controller.value = TextEditingValue(
        text: widget.query,
        selection: TextSelection.collapsed(offset: widget.query.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        onChanged: widget.onChanged,
      ),
    );
  }
}

class _AnnouncementResults extends StatelessWidget {
  const _AnnouncementResults({
    required this.announcements,
    required this.hasNoAnnouncements,
    required this.query,
  });

  final List<Announcement> announcements;
  final bool hasNoAnnouncements;
  final String query;

  @override
  Widget build(BuildContext context) {
    if (hasNoAnnouncements && query.trim().isEmpty) {
      return const _NoAnnouncements();
    }
    if (announcements.isEmpty) {
      return const Center(child: Text('Pengumuman tidak ditemukan'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: announcements.length,
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
