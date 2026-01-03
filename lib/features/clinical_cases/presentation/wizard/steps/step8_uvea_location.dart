import 'package:flutter/material.dart';

class Step8UveaLocation extends StatelessWidget {
  const Step8UveaLocation({
    super.key,
    required this.formKey,
    required this.locations,
    required this.onChanged,
  });

  final GlobalKey<FormState> formKey;
  final Map<String, dynamic> locations;
  final void Function(String eye, String? value) onChanged;

  static const _locationOptions = [
    'Anterior uveitis',
    'Intermediate uveitis',
    'Posterior uveitis',
    'Pan uveitis',
    'Nil',
  ];

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _EyeLocation(
                      eyeKey: 'RE',
                      locations: locations,
                      onChanged: onChanged,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _EyeLocation(
                      eyeKey: 'LE',
                      locations: locations,
                      onChanged: onChanged,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EyeLocation extends StatelessWidget {
  const _EyeLocation({
    required this.eyeKey,
    required this.locations,
    required this.onChanged,
  });

  final String eyeKey;
  final Map<String, dynamic> locations;
  final void Function(String eye, String? value) onChanged;

  @override
  Widget build(BuildContext context) {
    final value = locations[eyeKey] as String?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyeKey,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Location of uveitis'),
          items: Step8UveaLocation._locationOptions
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                ),
              )
              .toList(),
          onChanged: (next) => onChanged(eyeKey, next),
          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
        ),
      ],
    );
  }
}
