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
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Intraocular Pressure',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _EyeField(
                  label: 'Right Eye (RE)',
                  icon: Icons.remove_red_eye_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  controller: iopReController,
                  validator: _validateNumber,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _EyeField(
                  label: 'Left Eye (LE)',
                  icon: Icons.remove_red_eye_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
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
    required this.icon,
    required this.gradient,
    required this.controller,
    required this.validator,
  });

  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final TextEditingController controller;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with Gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          // Input Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: 'IOP (mmHg)',
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
                hintText: '0.0',
                hintStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE2E8F0),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFEC4899),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
              ),
              validator: validator,
            ),
          ),
        ],
      ),
    );
  }
}
