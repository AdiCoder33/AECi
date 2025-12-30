import 'package:flutter/material.dart';

class TaxonomyMultiSelectField extends StatelessWidget {
  const TaxonomyMultiSelectField({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.descriptions,
    required this.otherValue,
    required this.onSelectionChanged,
    required this.onDescriptionChanged,
    required this.onOtherChanged,
    this.validator,
    this.hintText = 'Select findings',
    this.enableSearch = true,
  });

  final String label;
  final List<String> options;
  final List<String> selected;
  final Map<String, String> descriptions;
  final String otherValue;
  final ValueChanged<List<String>> onSelectionChanged;
  final void Function(String option, String value) onDescriptionChanged;
  final ValueChanged<String> onOtherChanged;
  final String? Function(List<String>?)? validator;
  final String hintText;
  final bool enableSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FormField<List<String>>(
      key: ValueKey('$label-${selected.join('|')}'),
      initialValue: selected,
      validator: validator,
      builder: (state) {
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
              onPressed: () => _openSheet(context, state),
              child: const Text('Select findings'),
            ),
            if (state.errorText != null) ...[
              const SizedBox(height: 6),
              Text(
                state.errorText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            for (final option in selected.where(_isDescriptiveOption)) ...[
              const SizedBox(height: 8),
              TextFormField(
                key: ValueKey('$label-desc-$option-${descriptions[option] ?? ''}'),
                initialValue: descriptions[option] ?? '',
                decoration: InputDecoration(
                  labelText: '$option description',
                ),
                onChanged: (value) => onDescriptionChanged(option, value),
                validator: (value) {
                  if (!selected.contains(option)) return null;
                  if (value == null || value.trim().length < 3) {
                    return 'Enter at least 3 characters';
                  }
                  return null;
                },
              ),
            ],
            if (selected.contains('Other')) ...[
              const SizedBox(height: 8),
              TextFormField(
                key: ValueKey('$label-other-$otherValue'),
                initialValue: otherValue,
                decoration: const InputDecoration(
                  labelText: 'Other details',
                ),
                onChanged: onOtherChanged,
                validator: (value) {
                  if (!selected.contains('Other')) return null;
                  if (value == null || value.trim().length < 3) {
                    return 'Enter at least 3 characters';
                  }
                  return null;
                },
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _openSheet(
    BuildContext context,
    FormFieldState<List<String>> state,
  ) async {
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
                          final disableOption = normalSelected && !isNormal;
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
                          final ordered = options
                              .where((opt) => selectedSet.contains(opt))
                              .toList();
                          state.didChange(ordered);
                          onSelectionChanged(ordered);
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

  bool _isDescriptiveOption(String option) {
    final normalized = option.toLowerCase();
    return normalized.contains('descriptive') || normalized.contains('decriptive');
  }
}
