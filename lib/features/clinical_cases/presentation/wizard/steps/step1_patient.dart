import 'package:flutter/material.dart';

class Step1Patient extends StatelessWidget {
  const Step1Patient({
    super.key,
    required this.formKey,
    required this.examDate,
    required this.onPickDate,
    required this.patientNameController,
    required this.uidController,
    required this.mrController,
    required this.ageController,
    required this.gender,
    required this.onGenderChanged,
  });

  final GlobalKey<FormState> formKey;
  final DateTime examDate;
  final VoidCallback onPickDate;
  final TextEditingController patientNameController;
  final TextEditingController uidController;
  final TextEditingController mrController;
  final TextEditingController ageController;
  final String gender;
  final ValueChanged<String> onGenderChanged;

  @override
  Widget build(BuildContext context) {
    final dateText =
        '${examDate.year}-${examDate.month.toString().padLeft(2, '0')}-${examDate.day.toString().padLeft(2, '0')}';
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Date of examination',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: onPickDate,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(dateText),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: patientNameController,
            decoration: const InputDecoration(labelText: 'Patient Name'),
            validator: _required,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: uidController,
            decoration: const InputDecoration(labelText: 'UID Number'),
            validator: _required,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: mrController,
            decoration: const InputDecoration(labelText: 'MR Number'),
            validator: _required,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: gender,
            decoration: const InputDecoration(labelText: 'Gender'),
            items: const [
              DropdownMenuItem(value: 'male', child: Text('Male')),
              DropdownMenuItem(value: 'female', child: Text('Female')),
            ],
            onChanged: (value) => onGenderChanged(value ?? 'male'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: ageController,
            decoration: const InputDecoration(labelText: 'Age'),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Required';
              final age = int.tryParse(value);
              if (age == null || age <= 0) return 'Enter a valid age';
              return null;
            },
          ),
        ],
      ),
    );
  }

  static String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }
}
