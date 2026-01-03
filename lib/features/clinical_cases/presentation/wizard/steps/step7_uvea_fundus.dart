import 'package:flutter/material.dart';

class Step7UveaFundus extends StatelessWidget {
  const Step7UveaFundus({
    super.key,
    required this.formKey,
    required this.uveaFundus,
    required this.onChanged,
  });

  final GlobalKey<FormState> formKey;
  final Map<String, dynamic> uveaFundus;
  final void Function(String eye, String field, dynamic value) onChanged;

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
                    child: _UveaFundusEyeSection(
                      eyeKey: 'RE',
                      uveaFundus: uveaFundus,
                      onChanged: onChanged,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _UveaFundusEyeSection(
                      eyeKey: 'LE',
                      uveaFundus: uveaFundus,
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

class _UveaFundusEyeSection extends StatelessWidget {
  const _UveaFundusEyeSection({
    required this.eyeKey,
    required this.uveaFundus,
    required this.onChanged,
  });

  final String eyeKey;
  final Map<String, dynamic> uveaFundus;
  final void Function(String eye, String field, dynamic value) onChanged;

  static const _backgroundOptions = [
    'Nil',
    'Focal',
    'Multifocal',
    'Disseminated',
  ];

  static const _vasculitisOptions = [
    'Nil',
    'Arterial',
    'Venous',
  ];

  @override
  Widget build(BuildContext context) {
    final eye = Map<String, dynamic>.from(uveaFundus[eyeKey] as Map? ?? {});
    final avf = (eye['avf_vitreous'] ?? '').toString();
    final opticDisc = (eye['optic_disc'] ?? '').toString();
    final vessels = (eye['vessels'] ?? '').toString();
    final retinitis = eye['background_retinitis'] as String?;
    final choroiditis = eye['background_choroiditis'] as String?;
    final vasculitis = eye['background_vasculitis'] as String?;
    final snowbanking = eye['background_snowbanking'] as bool?;
    final snowballing = eye['background_snowballing'] as bool?;
    final exudativeRd = eye['background_exudative_rd'] as bool?;
    final backgroundOther = (eye['background_other'] ?? '').toString();
    final cme = eye['macula_cme'] as bool?;
    final exudates = eye['macula_exudates'] as bool?;
    final maculaOther = (eye['macula_other'] ?? '').toString();
    final extraNotes = (eye['extra_notes'] ?? '').toString();

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
        TextFormField(
          key: ValueKey('$eyeKey-avf-$avf'),
          initialValue: avf,
          decoration: const InputDecoration(
            labelText: 'AVF/Vitreous opacities',
          ),
          onChanged: (value) =>
              onChanged(eyeKey, 'avf_vitreous', value.trim()),
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: ValueKey('$eyeKey-optic-disc-$opticDisc'),
          initialValue: opticDisc,
          decoration: const InputDecoration(labelText: 'Optic disc'),
          onChanged: (value) =>
              onChanged(eyeKey, 'optic_disc', value.trim()),
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: ValueKey('$eyeKey-vessels-$vessels'),
          initialValue: vessels,
          decoration: const InputDecoration(labelText: 'Vessels'),
          onChanged: (value) => onChanged(eyeKey, 'vessels', value.trim()),
        ),
        const SizedBox(height: 16),
        Text(
          'Background',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        _buildDropdown<String>(
          label: 'Retinitis',
          value: retinitis,
          items: _backgroundOptions,
          validator: (value) =>
              value == null || value.isEmpty ? 'Required' : null,
          onChanged: (value) =>
              onChanged(eyeKey, 'background_retinitis', value),
        ),
        const SizedBox(height: 12),
        _buildDropdown<String>(
          label: 'Choroiditis',
          value: choroiditis,
          items: _backgroundOptions,
          validator: (value) =>
              value == null || value.isEmpty ? 'Required' : null,
          onChanged: (value) =>
              onChanged(eyeKey, 'background_choroiditis', value),
        ),
        const SizedBox(height: 12),
        _buildDropdown<String>(
          label: 'Vasculitis',
          value: vasculitis,
          items: _vasculitisOptions,
          validator: (value) =>
              value == null || value.isEmpty ? 'Required' : null,
          onChanged: (value) =>
              onChanged(eyeKey, 'background_vasculitis', value),
        ),
        const SizedBox(height: 12),
        _buildYesNo(
          label: 'Snowbanking',
          value: snowbanking,
          onChanged: (value) =>
              onChanged(eyeKey, 'background_snowbanking', value),
        ),
        const SizedBox(height: 12),
        _buildYesNo(
          label: 'Snowballing',
          value: snowballing,
          onChanged: (value) =>
              onChanged(eyeKey, 'background_snowballing', value),
        ),
        const SizedBox(height: 12),
        _buildYesNo(
          label: 'Exudative retinal detachment',
          value: exudativeRd,
          onChanged: (value) =>
              onChanged(eyeKey, 'background_exudative_rd', value),
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: ValueKey('$eyeKey-background-other-$backgroundOther'),
          initialValue: backgroundOther,
          decoration: const InputDecoration(labelText: 'Background (other)'),
          onChanged: (value) =>
              onChanged(eyeKey, 'background_other', value.trim()),
        ),
        const SizedBox(height: 16),
        Text(
          'Macula',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        _buildYesNo(
          label: 'Cystoid macular edema',
          value: cme,
          onChanged: (value) => onChanged(eyeKey, 'macula_cme', value),
        ),
        const SizedBox(height: 12),
        _buildYesNo(
          label: 'Exudates',
          value: exudates,
          onChanged: (value) => onChanged(eyeKey, 'macula_exudates', value),
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: ValueKey('$eyeKey-macula-other-$maculaOther'),
          initialValue: maculaOther,
          decoration: const InputDecoration(labelText: 'Macula (other)'),
          onChanged: (value) =>
              onChanged(eyeKey, 'macula_other', value.trim()),
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: ValueKey('$eyeKey-extra-notes-$extraNotes'),
          initialValue: extraNotes,
          decoration: const InputDecoration(labelText: 'Extra notes'),
          maxLines: 2,
          onChanged: (value) =>
              onChanged(eyeKey, 'extra_notes', value.trim()),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: items
          .map((item) => DropdownMenuItem<T>(
                value: item,
                child: Text(item.toString()),
              ))
          .toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildYesNo({
    required String label,
    required bool? value,
    required ValueChanged<bool?> onChanged,
  }) {
    return DropdownButtonFormField<bool>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: const [
        DropdownMenuItem(value: true, child: Text('Yes')),
        DropdownMenuItem(value: false, child: Text('No')),
      ],
      onChanged: onChanged,
      validator: (val) => val == null ? 'Required' : null,
    );
  }
}
