import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../logbook/application/logbook_providers.dart';
import '../application/portfolio_controller.dart';
import '../data/portfolio_repository.dart';

class PublicationListScreen extends ConsumerWidget {
  const PublicationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(publicationListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Publications')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed('pubNew'),
        child: const Icon(Icons.add),
      ),
      body: list.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No items yet'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              final title = (item.venueOrJournal?.isNotEmpty == true)
                  ? item.venueOrJournal!
                  : item.title;
              final year = item.date?.year.toString() ?? '-';
              return ListTile(
                tileColor: Colors.white.withValues(alpha: 0.04),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text(title),
                subtitle: Text('Year: $year'),
                onTap: () => context.pushNamed(
                  'pubDetail',
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

class PublicationDetailScreen extends ConsumerWidget {
  const PublicationDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(publicationDetailProvider(id));
    final signedCache = ref.watch(signedUrlCacheProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.pushNamed(
              'pubEdit',
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
              Text(
                item.venueOrJournal?.isNotEmpty == true
                    ? item.venueOrJournal!
                    : item.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              if (item.abstractText?.isNotEmpty == true) ...[
                const Text('Abstract', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(item.abstractText!),
                const SizedBox(height: 12),
              ],
              if (item.venueOrJournal?.isNotEmpty == true)
                Text('Journal: ${item.venueOrJournal}'),
              if (item.date != null) Text('Year: ${item.date!.year}'),
              if (item.link?.isNotEmpty == true)
                TextButton.icon(
                  onPressed: () => launchUrl(Uri.parse(item.link!)),
                  icon: const Icon(Icons.link),
                  label: const Text('Open link'),
                ),
              if (item.attachments.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('Attachments'),
                const SizedBox(height: 4),
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
                        leading: const Icon(Icons.picture_as_pdf),
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

class PublicationFormScreen extends ConsumerStatefulWidget {
  const PublicationFormScreen({super.key, this.id});
  final String? id;

  @override
  ConsumerState<PublicationFormScreen> createState() =>
      _PublicationFormScreenState();
}

class _PublicationFormScreenState extends ConsumerState<PublicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _abstract = TextEditingController();
  final _journal = TextEditingController();
  final _year = TextEditingController();
  final _link = TextEditingController();
  List<String> _keywords = [];

  List<String> _existingAttachments = [];
  final List<File> _newAttachments = [];

  @override
  void initState() {
    super.initState();
    if (widget.id != null) _load();
  }

  Future<void> _load() async {
    final item = await ref.read(publicationDetailProvider(widget.id!).future);
    _abstract.text = item.abstractText ?? '';
    _journal.text = item.venueOrJournal ?? '';
    _year.text = item.date?.year.toString() ?? '';
    _link.text = item.link ?? '';
    _keywords = item.keywords;
    _existingAttachments = item.attachments;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final mutation = ref.watch(portfolioMutationProvider);
    final signedCache = ref.watch(signedUrlCacheProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.id == null ? 'New Publication' : 'Edit Publication'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _abstract,
                decoration: const InputDecoration(labelText: 'Abstract'),
                minLines: 3,
                maxLines: 6,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Abstract required' : null,
              ),
              TextFormField(
                controller: _journal,
                decoration: const InputDecoration(labelText: 'Journal name'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Journal required' : null,
              ),
              TextFormField(
                controller: _year,
                decoration:
                    const InputDecoration(labelText: 'Year of publication'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Year required';
                  }
                  final year = int.tryParse(v.trim());
                  if (year == null || year < 1900 || year > 2100) {
                    return 'Enter a valid year';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _link,
                decoration:
                    const InputDecoration(labelText: 'Link to the journal'),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('PDF Upload'),
                  TextButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: const ['pdf'],
                        allowMultiple: true,
                      );
                      if (result != null && result.files.isNotEmpty) {
                        final files = result.paths
                            .whereType<String>()
                            .map((path) => File(path))
                            .toList();
                        _newAttachments.addAll(files);
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
                          leading: const Icon(Icons.picture_as_pdf),
                          title: Text(path.split('/').last),
                          onTap: () => launchUrl(Uri.parse(snapshot.data!)),
                        );
                      },
                    ),
                  ),
                  ..._newAttachments.map(
                    (file) => ListTile(
                      leading: const Icon(Icons.picture_as_pdf),
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final year = int.tryParse(_year.text.trim());
    final date = year != null ? DateTime(year, 1, 1) : null;
    final journal = _journal.text.trim();
    final title = journal.isNotEmpty
        ? journal
        : year != null
            ? 'Publication $year'
            : 'Publication';
    final repo = ref.read(portfolioRepositoryProvider);
    final mutation = ref.read(portfolioMutationProvider.notifier);
    PublicationItem payload = PublicationItem(
      id: widget.id ?? '',
      type: 'publication',
      title: title,
      createdBy: '',
      abstractText:
          _abstract.text.trim().isEmpty ? null : _abstract.text.trim(),
      venueOrJournal: journal.isEmpty ? null : journal,
      date: date,
      link: _link.text.trim().isEmpty ? null : _link.text.trim(),
      keywords: _keywords,
      attachments: _existingAttachments,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    try {
      String id = widget.id ?? '';
      if (widget.id == null) {
        id = await mutation.createPublication(payload);
      } else {
        await mutation.updatePublication(id, payload);
      }
      if (_newAttachments.isNotEmpty) {
        final newPaths = <String>[];
        for (final file in _newAttachments) {
          final path = await repo.uploadAttachment(
            kind: 'pubs',
            itemId: id,
            file: file,
          );
          newPaths.add(path);
        }
        final updated = PublicationItem(
          id: id,
          type: payload.type,
          title: payload.title,
          createdBy: '',
          abstractText: payload.abstractText,
          venueOrJournal: payload.venueOrJournal,
          date: payload.date,
          link: payload.link,
          keywords: payload.keywords,
          attachments: [..._existingAttachments, ...newPaths],
          createdAt: payload.createdAt,
          updatedAt: payload.updatedAt,
        );
        await mutation.updatePublication(id, updated);
      }
      if (mounted) {
        await ref.read(publicationListProvider.notifier).load();
        context.go('/profile');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved item')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }
}
