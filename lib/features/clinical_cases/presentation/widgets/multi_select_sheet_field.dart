import 'package:flutter/material.dart';

class MultiSelectSheetField extends StatelessWidget {
  const MultiSelectSheetField({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.hintText = 'Select findings',
    this.enableSearch = true,
  });

  final String label;
  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final String hintText;
  final bool enableSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        if (selected.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: selected
                .map(
                  (item) => Chip(
                    label: Text(item),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )
                .toList(),
          )
        else
          Text(
            hintText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => _openSheet(context),
          child: const Text('Select findings'),
        ),
      ],
    );
  }

  Future<void> _openSheet(BuildContext context) async {
    final theme = Theme.of(context);
    final selectedSet = selected.toSet();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setState) {
            final filtered = options.where((option) {
              if (query.trim().isEmpty) return true;
              return option.toLowerCase().contains(query.toLowerCase());
            }).toList();
            final normalSelected = selectedSet.contains('Normal');

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            selectedSet.clear();
                            setState(() {});
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                    if (enableSearch) ...[
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search',
                        ),
                        onChanged: (value) => setState(() => query = value),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final option = filtered[index];
                          final isSelected = selectedSet.contains(option);
                          final isNormal = option == 'Normal';
                          final disableOption =
                              normalSelected && !isNormal;
                          return CheckboxListTile(
                            value: isSelected,
                            dense: true,
                            title: Text(option),
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: disableOption
                                ? null
                                : (value) {
                                    if (value == null) return;
                                    if (isNormal) {
                                      if (value) {
                                        selectedSet
                                          ..clear()
                                          ..add('Normal');
                                      } else {
                                        selectedSet.remove('Normal');
                                      }
                                    } else {
                                      selectedSet.remove('Normal');
                                      if (value) {
                                        selectedSet.add(option);
                                      } else {
                                        selectedSet.remove(option);
                                      }
                                    }
                                    setState(() {});
                                  },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          onChanged(selectedSet.toList());
                          Navigator.pop(context);
                        },
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
