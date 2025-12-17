import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/taxonomy_repository.dart';

class KeywordSuggestionsScreen extends ConsumerWidget {
  const KeywordSuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(taxonomyRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Keyword Suggestions')),
      body: FutureBuilder(
        future: repo.listSuggestions(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final list = snapshot.data!;
          if (list.isEmpty) return const Center(child: Text('No suggestions'));
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final s = list[i];
              return ListTile(
                title: Text(s.suggestedTerm),
                subtitle: Text('Status: ${s.status}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: s.status == 'pending'
                          ? () async {
                              await repo.reviewSuggestion(s.id, 'accepted');
                              (context as Element).reassemble();
                            }
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: s.status == 'pending'
                          ? () async {
                              await repo.reviewSuggestion(s.id, 'rejected');
                              (context as Element).reassemble();
                            }
                          : null,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
