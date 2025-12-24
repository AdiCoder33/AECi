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
          TextFormField(
            controller: iopReController,
            decoration: const InputDecoration(labelText: 'IOP - Right Eye (mmHg)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: _validateNumber,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: iopLeController,
            decoration: const InputDecoration(labelText: 'IOP - Left Eye (mmHg)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: _validateNumber,
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
