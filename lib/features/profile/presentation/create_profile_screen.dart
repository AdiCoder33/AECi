import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
import '../application/profile_controller.dart';
import '../data/profile_constants.dart';
import '../data/profile_model.dart';

class CreateProfileScreen extends ConsumerStatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  ConsumerState<CreateProfileScreen> createState() =>
      _CreateProfileScreenState();
}

class _CreateProfileScreenState extends ConsumerState<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  DateTime? _dob;
  String _designation = profileDesignations.first;
  String _centre = profileCentres.first;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authControllerProvider);
    _emailController.text = auth.session?.user.email ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _employeeIdController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final isSaving = profileState.isLoading;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Complete your profile'),
          automaticallyImplyLeading: false,
          actions: [
            TextButton(
              onPressed: isSaving
                  ? null
                  : () => ref.read(authControllerProvider.notifier).signOut(),
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Card(
                color: const Color(0xFF0F1624),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Aravind E-Logbook',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Complete your professional profile to proceed.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (profileState.errorMessage != null) ...[
                          _ErrorBanner(message: profileState.errorMessage!),
                          const SizedBox(height: 12),
                        ],
                        _FormField(
                          label: 'Name',
                          controller: _nameController,
                          validator: _requiredValidator,
                        ),
                        _FormField(
                          label: 'Age',
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            final v = value?.trim() ?? '';
                            if (v.isEmpty) return 'Required';
                            final age = int.tryParse(v);
                            if (age == null || age < 18 || age > 80) {
                              return 'Age must be between 18-80';
                            }
                            return null;
                          },
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: _designation,
                          items: profileDesignations
                              .map(
                                (d) =>
                                    DropdownMenuItem(value: d, child: Text(d)),
                              )
                              .toList(),
                          decoration: const InputDecoration(
                            labelText: 'Designation',
                          ),
                          onChanged: isSaving
                              ? null
                              : (value) =>
                                    setState(() => _designation = value!),
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: _centre,
                          items: profileCentres
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                          decoration: const InputDecoration(
                            labelText: 'Centre',
                          ),
                          onChanged: isSaving
                              ? null
                              : (value) => setState(() => _centre = value!),
                        ),
                        const SizedBox(height: 12),
                        const _ReadonlyField(
                          label: 'Hospital',
                          value: 'Aravind Eye Hospital',
                        ),
                        _FormField(
                          label: 'Employee ID',
                          controller: _employeeIdController,
                          validator: _requiredValidator,
                        ),
                        _FormField(
                          label: 'Phone Number',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            final v = value?.trim() ?? '';
                            if (v.isEmpty) return 'Required';
                            final numeric = RegExp(r'^[0-9]{10}$');
                            if (!numeric.hasMatch(v)) {
                              return 'Enter a valid 10 digit number';
                            }
                            return null;
                          },
                        ),
                        _FormField(
                          label: 'Email',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            final v = value?.trim() ?? '';
                            if (v.isEmpty) return 'Required';
                            if (!v.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _DobField(
                          dob: _dob,
                          onPick: isSaving
                              ? null
                              : () async {
                                  final now = DateTime.now();
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime(1990, 1, 1),
                                    firstDate: DateTime(
                                      now.year - 80,
                                      now.month,
                                      now.day,
                                    ),
                                    lastDate: DateTime(
                                      now.year - 18,
                                      now.month,
                                      now.day,
                                    ),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _dob = picked;
                                    });
                                  }
                                },
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isSaving ? null : _saveProfile,
                            child: isSaving
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Text(
                                    'Save Profile',
                                    style: TextStyle(color: Colors.black),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Date of Birth')),
      );
      return;
    }
    final auth = ref.read(authControllerProvider);
    final userId = auth.session?.user.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please sign in again.')),
      );
      return;
    }

    final profile = Profile(
      id: userId,
      name: _nameController.text.trim(),
      age: int.parse(_ageController.text.trim()),
      designation: _designation,
      hospital: 'Aravind Eye Hospital',
      centre: _centre,
      employeeId: _employeeIdController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      dob: _dob!,
    );

    await ref.read(profileControllerProvider.notifier).upsertProfile(profile);

    final profileState = ref.read(profileControllerProvider);
    if (profileState.errorMessage == null &&
        profileState.profile != null &&
        mounted) {
      context.go('/home');
    }
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.controller,
    this.keyboardType,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _DobField extends StatelessWidget {
  const _DobField({required this.dob, required this.onPick});

  final DateTime? dob;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final text = dob == null
        ? 'Select date of birth'
        : '${dob!.year}-${dob!.month.toString().padLeft(2, '0')}-${dob!.day.toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date of Birth',
          style: TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.calendar_today, size: 18),
          label: Text(text),
        ),
      ],
    );
  }
}

class _ReadonlyField extends StatelessWidget {
  const _ReadonlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              color: Colors.white.withValues(alpha: 0.03),
            ),
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.15),
        border: Border.all(color: Colors.redAccent),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
