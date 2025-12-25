import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../logbook/application/logbook_providers.dart';
import '../application/portfolio_controller.dart';
import '../data/portfolio_repository.dart';

class ResearchListScreen extends ConsumerWidget {
  const ResearchListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(researchListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Research Projects')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed('researchNew'),
        child: const Icon(Icons.add),
      ),
      body: list.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No projects yet'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                tileColor: Colors.white.withValues(alpha: 0.04),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text(item.title),
                subtitle: Text('${item.status} • ${item.updatedAt.toLocal()}'),
                onTap: () => context.pushNamed(
                  'researchDetail',
                  pathParameters: {'id': item.id},
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class ResearchDetailScreen extends ConsumerWidget {
  const ResearchDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(researchDetailProvider(id));
    final signedCache = ref.watch(signedUrlCacheProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Research Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.pushNamed(
              'researchEdit',
              pathParameters: {'id': id},
            ),
          ),
        ],
      ),
      body: itemAsync.when(
        data: (item) => Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('Status: ${item.status}'),
              if (item.role != null && item.role!.isNotEmpty)
                Text('Role: ${item.role}'),
              if (item.summary != null && item.summary!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(item.summary!),
                ),
              if (item.keywords.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: item.keywords
                      .map(
                        (k) => Chip(
                          label: Text(k),
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 12),
              if (item.attachments.isNotEmpty) ...[
                const Text('Attachments'),
                const SizedBox(height: 6),
                ...item.attachments.map(
                  (path) => FutureBuilder(
                    future: signedCache.getUrl(path),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const ListTile(
                          leading: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }
                      return ListTile(
                        leading: const Icon(Icons.link),
                        title: Text(path.split('/').last),
                        onTap: () => launchUrl(Uri.parse(snapshot.data!)),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class ResearchFormScreen extends ConsumerStatefulWidget {
  const ResearchFormScreen({super.key, this.id});

  final String? id;

  @override
  ConsumerState<ResearchFormScreen> createState() => _ResearchFormScreenState();
}

class _ResearchFormScreenState extends ConsumerState<ResearchFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _summary = TextEditingController();
  final _role = TextEditingController();
  final _status = ValueNotifier<String>('Planned');
  final _keywords = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  List<String> _existingAttachments = [];
  final List<File> _newAttachments = [];

  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      _load();
    }
  }

  Future<void> _load() async {
    final item = await ref.read(researchDetailProvider(widget.id!).future);
    _title.text = item.title;
    _summary.text = item.summary ?? '';
    _role.text = item.role ?? '';
    _status.value = item.status;
    _keywords.text = item.keywords.join(', ');
    _startDate = item.startDate;
    _endDate = item.endDate;
    _existingAttachments = item.attachments;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final mutation = ref.watch(portfolioMutationProvider);
    final signedCache = ref.watch(signedUrlCacheProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.id == null ? 'New Research' : 'Edit Research'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Title required' : null,
              ),
              TextFormField(
                controller: _summary,
                decoration: const InputDecoration(labelText: 'Summary'),
                maxLines: 3,
              ),
              TextFormField(
                controller: _role,
                decoration: const InputDecoration(labelText: 'Role'),
              ),
              ValueListenableBuilder(
                valueListenable: _status,
                builder: (_, value, __) => DropdownButtonFormField<String>(
                  initialValue: value,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'Planned', child: Text('Planned')),
                    DropdownMenuItem(value: 'Ongoing', child: Text('Ongoing')),
                    DropdownMenuItem(
                      value: 'Completed',
                      child: Text('Completed'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) _status.value = v;
                  },
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => _pickDate(context, true),
                      child: Text(
                        _startDate == null
                            ? 'Start date'
                            : 'Start: ${_startDate!.toLocal().toString().split(' ').first}',
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () => _pickDate(context, false),
                      child: Text(
                        _endDate == null
                            ? 'End date'
                            : 'End: ${_endDate!.toLocal().toString().split(' ').first}',
                      ),
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _keywords,
                decoration:
                    const InputDecoration(labelText: 'Keywords (comma separated)'),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Attachments'),
                  TextButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickMultiImage();
                      if (picked.isNotEmpty) {
                        _newAttachments.addAll(picked.map((e) => File(e.path)));
                        setState(() {});
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
              Column(
                children: [
                  ..._existingAttachments.map(
                    (path) => FutureBuilder(
                      future: signedCache.getUrl(path),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const ListTile(
                            leading: CircularProgressIndicator(strokeWidth: 2),
                          );
                        }
                        return ListTile(
                          leading: const Icon(Icons.link),
                          title: Text(path.split('/').last),
                          onTap: () => launchUrl(Uri.parse(snapshot.data!)),
                        );
                      },
                    ),
                  ),
                  ..._newAttachments.map(
                    (file) => ListTile(
                      leading: const Icon(Icons.insert_drive_file),
                      title: Text(file.path.split(Platform.pathSeparator).last),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: mutation.isLoading ? null : _save,
                child: mutation.isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, bool start) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (start) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final keywords = _keywords.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final repo = ref.read(portfolioRepositoryProvider);
    final mutation = ref.read(portfolioMutationProvider.notifier);

    ResearchProject payload = ResearchProject(
      id: widget.id ?? '',
      title: _title.text.trim(),
      status: _status.value,
      createdBy: '',
      summary: _summary.text.trim().isEmpty ? null : _summary.text.trim(),
      role: _role.text.trim().isEmpty ? null : _role.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      keywords: keywords,
      attachments: _existingAttachments,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      String id = widget.id ?? '';
      if (widget.id == null) {
        id = await mutation.createResearch(payload);
      } else {
        await mutation.updateResearch(id, payload);
      }

      if (_newAttachments.isNotEmpty) {
        final newPaths = <String>[];
        for (final file in _newAttachments) {
          final path = await repo.uploadAttachment(
            kind: 'research',
            itemId: id,
            file: file,
          );
          newPaths.add(path);
        }
        final updated = ResearchProject(
          id: id,
          title: payload.title,
          status: payload.status,
          createdBy: '',
          summary: payload.summary,
          role: payload.role,
          startDate: payload.startDate,
          endDate: payload.endDate,
          keywords: payload.keywords,
          attachments: [..._existingAttachments, ...newPaths],
          createdAt: payload.createdAt,
          updatedAt: payload.updatedAt,
        );
        await mutation.updateResearch(id, updated);
      }

      if (mounted) {
        await ref.read(researchListProvider.notifier).load();
        context.go('/profile');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved project')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }
}
