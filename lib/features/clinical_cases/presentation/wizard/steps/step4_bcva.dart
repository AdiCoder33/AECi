import 'package:flutter/material.dart';

import '../../../data/clinical_case_constants.dart';

class Step4Bcva extends StatelessWidget {
  const Step4Bcva({
    super.key,
    required this.formKey,
    required this.bcvaRe,
    required this.bcvaLe,
    required this.onBcvaReChanged,
    required this.onBcvaLeChanged,
  });

  final GlobalKey<FormState> formKey;
  final String bcvaRe;
  final String bcvaLe;
  final ValueChanged<String> onBcvaReChanged;
  final ValueChanged<String> onBcvaLeChanged;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Best Corrected Visual Acuity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _EyeField(
                  label: 'Right Eye (RE)',
                  icon: Icons.visibility_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF34D399)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  value: bcvaRe,
                  onChanged: onBcvaReChanged,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _EyeField(
                  label: 'Left Eye (LE)',
                  icon: Icons.visibility_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  value: bcvaLe,
                  onChanged: onBcvaLeChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EyeField extends StatelessWidget {
  const _EyeField({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final String value;
  final ValueChanged<String> onChanged;

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
                Icon(icon, size: 24, color: Colors.white),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          // Dropdown Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: value.isEmpty ? null : value,
              isExpanded: true,
              menuMaxHeight: 300,
              borderRadius: BorderRadius.circular(16),
              items: bcvaOptions
                  .map(
                    (o) => DropdownMenuItem(
                      value: o,
                      child: Text(
                        o,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  )
                  .toList(),
              decoration: InputDecoration(
                labelText: 'Select BCVA',
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF10B981),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              validator: (val) =>
                  (val == null || val.isEmpty) ? 'Required' : null,
              onChanged: (val) => onChanged(val ?? ''),
            ),
          ),
        ],
      ),
    );
  }
}
