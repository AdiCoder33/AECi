import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
import '../application/profile_controller.dart';
import '../data/profile_constants.dart';
import '../data/profile_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _editMode = false;

  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _employeeIdController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  DateTime? _dob;
  String _designation = profileDesignations.first;
  String _centre = profileCentres.first;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    _employeeIdController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
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
    final profile = profileState.profile;

    if (!profileState.initialized ||
        profileState.isLoading && profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (profile == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/profile/create');
      });
      return const Scaffold();
    }

    _seedControllers(profile);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Professional details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _editMode = !_editMode);
                          },
                          child: Text(_editMode ? 'Cancel' : 'Edit'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (profileState.errorMessage != null) ...[
                      _ErrorBanner(message: profileState.errorMessage!),
                      const SizedBox(height: 12),
                    ],
                    _editMode
                        ? Form(
                            key: _formKey,
                            child: Column(
                              children: [
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
                                        (d) => DropdownMenuItem(
                                          value: d,
                                          child: Text(d),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _designation = v!),
                                  decoration: const InputDecoration(
                                    labelText: 'Designation',
                                  ),
                                ),
                                DropdownButtonFormField<String>(
                                  initialValue: _centre,
                                  items: profileCentres
                                      .map(
                                        (d) => DropdownMenuItem(
                                          value: d,
                                          child: Text(d),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _centre = v!),
                                  decoration: const InputDecoration(
                                    labelText: 'Centre',
                                  ),
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
                                    if (!v.contains('@')) {
                                      return 'Enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 10),
                                _DobField(
                                  dob: _dob,
                                  onPick: () async {
                                    final now = DateTime.now();
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _dob ?? DateTime(1990, 1, 1),
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
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: profileState.isLoading
                                        ? null
                                        : () => _save(profile.id),
                                    child: profileState.isLoading
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.black,
                                            ),
                                          )
                                        : const Text(
                                            'Save Changes',
                                            style: TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _ProfileView(profile: profile),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _seedControllers(Profile profile) {
    _nameController.text = profile.name;
    _ageController.text = profile.age.toString();
    _employeeIdController.text = profile.employeeId;
    _phoneController.text = profile.phone;
    _emailController.text = profile.email;
    _dob = profile.dob;
    _designation = profile.designation;
    _centre = profile.centre;
  }

  void _save(String userId) async {
    if (!_formKey.currentState!.validate() || _dob == null) {
      if (_dob == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select Date of Birth')),
        );
      }
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
    final error = ref.read(profileControllerProvider).errorMessage;
    if (error == null) {
      setState(() => _editMode = false);
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

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Row(label: 'Name', value: profile.name),
        _Row(label: 'Age', value: profile.age.toString()),
        _Row(label: 'Designation', value: profile.designation),
        _Row(label: 'Hospital', value: profile.hospital),
        _Row(label: 'Centre', value: profile.centre),
        _Row(label: 'Employee ID', value: profile.employeeId),
        _Row(label: 'Phone', value: profile.phone),
        _Row(label: 'Email', value: profile.email),
        _Row(
          label: 'DOB',
          value:
              '${profile.dob.year}-${profile.dob.month.toString().padLeft(2, '0')}-${profile.dob.day.toString().padLeft(2, '0')}',
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
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
