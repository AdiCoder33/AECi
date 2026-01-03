import 'package:flutter/material.dart';

class Step6UveaAnterior extends StatelessWidget {
  const Step6UveaAnterior({
    super.key,
    required this.formKey,
    required this.uveaAnterior,
    required this.onChanged,
  });

  final GlobalKey<FormState> formKey;
  final Map<String, dynamic> uveaAnterior;
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
                    child: _UveaAnteriorEyeSection(
                      eyeKey: 'RE',
                      uveaAnterior: uveaAnterior,
                      onChanged: onChanged,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _UveaAnteriorEyeSection(
                      eyeKey: 'LE',
                      uveaAnterior: uveaAnterior,
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

class _UveaAnteriorEyeSection extends StatelessWidget {
  const _UveaAnteriorEyeSection({
    required this.eyeKey,
    required this.uveaAnterior,
    required this.onChanged,
  });

  final String eyeKey;
  final Map<String, dynamic> uveaAnterior;
  final void Function(String eye, String field, dynamic value) onChanged;

  static const _conjunctivaOptions = [
    'Nil',
    'CCC',
    'Episcleritis',
    'Scleritis',
    'Other',
  ];

  static const _kpsTypeOptions = [
    'Nil',
    'Granulomatous',
    'Non-granulomatous',
  ];

  static const _kpsDistributionOptions = [
    'Nil',
    'Diffuse',
    'Inferior',
  ];

  static const _acCellOptions = [
    '0',
    '0.5+',
    '1+',
    '2+',
    '3+',
    '4+',
  ];

  static const _flareOptions = [
    '0',
    '1+',
    '2+',
    '3+',
    '4+',
  ];

  static const _glaucomaOptions = [
    'Nil',
    'Open angle',
    'Angle closure',
    'Steroid induced',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    final eye = Map<String, dynamic>.from(uveaAnterior[eyeKey] as Map? ?? {});
    final conjunctiva = eye['conjunctiva'] as String?;
    final conjunctivaOther = (eye['conjunctiva_other'] ?? '').toString();
    final keratitis = eye['corneal_keratitis'] as bool?;
    final kpsType = eye['kps_type'] as String?;
    final kpsDistribution = eye['kps_distribution'] as String?;
    final acCells = eye['ac_cells'] as String?;
    final flare = eye['flare'] as String?;
    final fm = eye['fm'] as bool?;
    final hypopyon = eye['hypopyon'] as bool?;
    final hypopyonHeight = (eye['hypopyon_height_mm'] ?? '').toString();
    final glaucoma = eye['glaucoma'] as String?;
    final glaucomaOther = (eye['glaucoma_other'] ?? '').toString();
    final lensStatus = (eye['lens_status'] ?? '').toString();

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
        _buildDropdown<String>(
          label: 'Conjunctiva',
          value: conjunctiva,
          items: _conjunctivaOptions,
          validator: (value) =>
              value == null || value.isEmpty ? 'Required' : null,
          onChanged: (value) => onChanged(eyeKey, 'conjunctiva', value),
        ),
        if (conjunctiva == 'Other') ...[
          const SizedBox(height: 8),
          TextFormField(
            key: ValueKey('$eyeKey-conjunctiva-other-$conjunctivaOther'),
            initialValue: conjunctivaOther,
            decoration: const InputDecoration(labelText: 'Conjunctiva (other)'),
            validator: (value) {
              if (conjunctiva != 'Other') return null;
              if (value == null || value.trim().isEmpty) return 'Required';
              return null;
            },
            onChanged: (value) =>
                onChanged(eyeKey, 'conjunctiva_other', value.trim()),
          ),
        ],
        const SizedBox(height: 12),
        _buildYesNo(
          label: 'Corneal keratitis',
          value: keratitis,
          onChanged: (value) =>
              onChanged(eyeKey, 'corneal_keratitis', value),
        ),
        const SizedBox(height: 12),
        _buildDropdown<String>(
          label: 'KPs type',
          value: kpsType,
          items: _kpsTypeOptions,
          validator: (value) =>
              value == null || value.isEmpty ? 'Required' : null,
          onChanged: (value) => onChanged(eyeKey, 'kps_type', value),
        ),
        const SizedBox(height: 12),
        _buildDropdown<String>(
          label: 'KPs distribution',
          value: kpsDistribution,
          items: _kpsDistributionOptions,
          validator: (value) =>
              value == null || value.isEmpty ? 'Required' : null,
          onChanged: (value) =>
              onChanged(eyeKey, 'kps_distribution', value),
        ),
        const SizedBox(height: 12),
        _buildDropdown<String>(
          label: 'AC cells',
          value: acCells,
          items: _acCellOptions,
          validator: (value) =>
              value == null || value.isEmpty ? 'Required' : null,
          onChanged: (value) => onChanged(eyeKey, 'ac_cells', value),
        ),
        const SizedBox(height: 12),
        _buildDropdown<String>(
          label: 'Flare',
          value: flare,
          items: _flareOptions,
          validator: (value) =>
              value == null || value.isEmpty ? 'Required' : null,
          onChanged: (value) => onChanged(eyeKey, 'flare', value),
        ),
        const SizedBox(height: 12),
        _buildYesNo(
          label: 'FM',
          value: fm,
          onChanged: (value) => onChanged(eyeKey, 'fm', value),
        ),
        const SizedBox(height: 12),
        _buildYesNo(
          label: 'Hypopyon',
          value: hypopyon,
          onChanged: (value) => onChanged(eyeKey, 'hypopyon', value),
        ),
        if (hypopyon == true) ...[
          const SizedBox(height: 8),
          TextFormField(
            key: ValueKey('$eyeKey-hypopyon-height-$hypopyonHeight'),
            initialValue: hypopyonHeight,
            decoration: const InputDecoration(
              labelText: 'Hypopyon height (mm)',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (hypopyon != true) return null;
              if (value == null || value.trim().isEmpty) return 'Required';
              if (double.tryParse(value.trim()) == null) {
                return 'Enter a number';
              }
              return null;
            },
            onChanged: (value) =>
                onChanged(eyeKey, 'hypopyon_height_mm', value.trim()),
          ),
        ],
        const SizedBox(height: 12),
        _buildDropdown<String>(
          label: 'Glaucoma',
          value: glaucoma,
          items: _glaucomaOptions,
          validator: (value) =>
              value == null || value.isEmpty ? 'Required' : null,
          onChanged: (value) => onChanged(eyeKey, 'glaucoma', value),
        ),
        if (glaucoma == 'Other') ...[
          const SizedBox(height: 8),
          TextFormField(
            key: ValueKey('$eyeKey-glaucoma-other-$glaucomaOther'),
            initialValue: glaucomaOther,
            decoration: const InputDecoration(labelText: 'Glaucoma (other)'),
            validator: (value) {
              if (glaucoma != 'Other') return null;
              if (value == null || value.trim().isEmpty) return 'Required';
              return null;
            },
            onChanged: (value) =>
                onChanged(eyeKey, 'glaucoma_other', value.trim()),
          ),
        ],
        const SizedBox(height: 12),
        TextFormField(
          key: ValueKey('$eyeKey-lens-status-$lensStatus'),
          initialValue: lensStatus,
          decoration: const InputDecoration(labelText: 'Lens status'),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Required' : null,
          onChanged: (value) =>
              onChanged(eyeKey, 'lens_status', value.trim()),
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
