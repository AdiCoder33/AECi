import 'package:flutter/material.dart';

class Step5Iop extends StatelessWidget {
  const Step5Iop({
    super.key,
    required this.formKey,
    required this.iopReController,
    required this.iopLeController,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController iopReController;
  final TextEditingController iopLeController;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _EyeField(
                  label: 'RE',
                  controller: iopReController,
                  validator: _validateNumber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _EyeField(
                  label: 'LE',
                  controller: iopLeController,
                  validator: _validateNumber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _validateNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final parsed = num.tryParse(value);
    if (parsed == null) return 'Enter a valid number';
    return null;
  }
}

class _EyeField extends StatelessWidget {
  const _EyeField({
    required this.label,
    required this.controller,
    required this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'IOP (mmHg)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: validator,
        ),
      ],
    );
  }
}
