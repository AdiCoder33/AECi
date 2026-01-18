import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logbook/data/entries_repository.dart';
import '../../logbook/data/media_repository.dart';
import '../../logbook/domain/elog_entry.dart';

class StorageManagementScreen extends ConsumerStatefulWidget {
  const StorageManagementScreen({super.key});

  @override
  ConsumerState<StorageManagementScreen> createState() =>
      _StorageManagementScreenState();
}

class _StorageManagementScreenState
    extends ConsumerState<StorageManagementScreen> {
  bool _loading = true;
  List<_MediaItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entriesRepo = ref.read(entriesRepositoryProvider);
    final all = <ElogEntry>[];
    for (final m in moduleTypes) {
      final list = await entriesRepo.listEntries(moduleType: m, onlyMine: true);
      all.addAll(list);
    }
    final items = <_MediaItem>[];
    for (final e in all) {
      final paths = _extractPaths(e);
      for (final p in paths) {
        items.add(_MediaItem(entryId: e.id, path: p, module: e.moduleType));
      }
    }
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  List<String> _extractPaths(ElogEntry e) {
    final p = e.payload;
    switch (e.moduleType) {
      case moduleCases:
        return [
          ...List<String>.from(p['ancillaryImagingPaths'] ?? []),
          ...List<String>.from(p['followUpVisitImagingPaths'] ?? []),
        ];
      case moduleImages:
        return [
          ...List<String>.from(p['uploadImagePaths'] ?? []),
          ...List<String>.from(p['followUpVisitImagingPaths'] ?? []),
        ];
      default:
        return [];
    }
  }

  Future<void> _remove(_MediaItem item) async {
    final entriesRepo = ref.read(entriesRepositoryProvider);
    final mediaRepo = ref.read(mediaRepositoryProvider);
    try {
      final entry = await entriesRepo.getEntry(item.entryId);
      final payload = Map<String, dynamic>.from(entry.payload);
      void removePath(String key) {
        if (payload[key] != null) {
          final list = List<String>.from(payload[key]);
          list.remove(item.path);
          payload[key] = list;
        }
      }

      removePath('ancillaryImagingPaths');
      removePath('followUpVisitImagingPaths');
      removePath('uploadImagePaths');
      await entriesRepo.updateEntry(
        item.entryId,
        ElogEntryUpdate(payload: payload),
      );
      await mediaRepo.removeObject(item.path);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Removed')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Storage')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Text(
                    'No uploaded images found in your account storage',
                  ),
                )
              : Padding
                  (
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'These are all images you have uploaded from your logbook entries. '
                        'Deleting a file here will remove it from your account storage and from any entries using it.',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.separated(
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return ListTile(
                              title: Text(item.path),
                              subtitle: Text('Entry: ${item.entryId} • ${item.module}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () => _remove(item),
                              ),
                            );
                          },
                          separatorBuilder: (_, __) => const Divider(),
                          itemCount: _items.length,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _MediaItem {
  _MediaItem({required this.entryId, required this.path, required this.module});

  final String entryId;
  final String path;
  final String module;
}
