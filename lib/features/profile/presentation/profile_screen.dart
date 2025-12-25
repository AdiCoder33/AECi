import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _hodController = TextEditingController();
  DateTime? _dob;
  DateTime? _dateOfJoining;
  String _designation = profileDesignations.first;
  String _centre = profileCentres.first;
  String _gender = 'male';

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
    _idNumberController.dispose();
    _hodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState.profile;

    if (profile != null && !_initialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadFromProfile(profile);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          TextButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) {
                  context.go('/auth');
                }
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : _editing
              ? _buildEdit(profileState)
              : _buildView(profile),
    );
  }

  Widget _buildView(Profile profile) {
    final months = profile.dateOfJoining == null
        ? null
        : _monthsIntoProgram(profile.dateOfJoining!);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SectionCard(
            title: 'Personal',
            children: [
              _InfoRow(label: 'Name', value: profile.name),
              _InfoRow(
                label: 'Gender',
                value: profile.gender ?? '-',
              ),
              _InfoRow(label: 'Age', value: profile.age.toString()),
              _InfoRow(label: 'DOB', value: _formatDate(profile.dob)),
              _InfoRow(label: 'Phone', value: profile.phone),
              _InfoRow(label: 'Email', value: profile.email),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Professional',
            children: [
              _InfoRow(label: 'Designation', value: profile.designation),
              _InfoRow(label: 'Degrees', value: _joinList(profile.degrees)),
              _InfoRow(
                label: 'Aravind Centre',
                value: profile.aravindCentre ?? profile.centre,
              ),
              _InfoRow(label: 'Hospital', value: profile.hospital),
              _InfoRow(label: 'Employee ID', value: profile.employeeId),
              _InfoRow(label: 'ID Number', value: profile.idNumber ?? '-'),
              _InfoRow(label: 'HOD', value: profile.hodName ?? '-'),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Program',
            children: [
              _InfoRow(
                label: 'Date of Joining',
                value: profile.dateOfJoining == null
                    ? '-'
                    : _formatDate(profile.dateOfJoining!),
              ),
              _InfoRow(
                label: 'Months into program',
                value: months == null ? '-' : '$months',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEdit(ProfileState profileState) {
    final isSaving = profileState.isLoading;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _SectionCard(
              title: 'Personal',
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
                  value: _gender,
                  items: profileGenders
                      .map(
                        (g) => DropdownMenuItem(
                          value: g,
                          child: Text(g[0].toUpperCase() + g.substring(1)),
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
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  value: _gender,
                                  items: const [
                                    DropdownMenuItem(value: 'male', child: Text('Male')),
                                    DropdownMenuItem(value: 'female', child: Text('Female')),
                                    DropdownMenuItem(value: 'other', child: Text('Other')),
                                  ],
                                  onChanged: (v) => setState(() => _gender = v!),
                                  decoration: const InputDecoration(
                                    labelText: 'Gender',
                                  ),
                                ),
                                const SizedBox(height: 12),
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
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: profileState.isLoading
                                        ? null
                                        : () => _save(profile.id),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0B5FFF),
                                      foregroundColor: Colors.white,
                                      elevation: 2,
                                      shadowColor: const Color(0xFF0B5FFF).withOpacity(0.3),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: profileState.isLoading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(
                                            'Save Changes',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _ProfileView(profile: profile),
                  ],
                      )
                      .toList(),
                  decoration: const InputDecoration(labelText: 'Gender'),
                  onChanged: isSaving
                      ? null
                      : (value) => setState(() => _gender = value!),
                ),
                const SizedBox(height: 12),
                _DateField(
                  label: 'Date of Birth',
                  value: _dob,
                  onPick: isSaving
                      ? null
                      : () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dob ?? DateTime(1990, 1, 1),
                            firstDate: DateTime(now.year - 80),
                            lastDate: DateTime(now.year - 18),
                          );
                          if (picked != null) {
                            setState(() => _dob = picked);
                          }
                        },
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
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Professional',
              children: [
                const Text(
                  'Degrees',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profileDegrees.map((degree) {
                    final selected = _degrees.contains(degree);
                    return FilterChip(
                      selected: selected,
                      label: Text(degree),
                      onSelected: isSaving
                          ? null
                          : (value) {
                              setState(() {
                                if (value) {
                                  _degrees = [..._degrees, degree];
                                } else {
                                  _degrees = _degrees
                                      .where((d) => d != degree)
                                      .toList();
                                }
                              });
                            },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _designation,
                  items: profileDesignations
                      .map(
                        (d) => DropdownMenuItem(value: d, child: Text(d)),
                      )
                      .toList(),
                  decoration: const InputDecoration(labelText: 'Designation'),
                  onChanged: isSaving
                      ? null
                      : (value) => setState(() => _designation = value!),
                ),
                DropdownButtonFormField<String>(
                  value: _centre,
                  items: profileCentres
                      .map(
                        (c) => DropdownMenuItem(value: c, child: Text(c)),
                      )
                      .toList(),
                  decoration: const InputDecoration(labelText: 'Aravind Centre'),
                  onChanged: isSaving
                      ? null
                      : (value) => setState(() => _centre = value!),
                ),
                _FormField(
                  label: 'Employee ID',
                  controller: _employeeIdController,
                  validator: _requiredValidator,
                ),
                _FormField(
                  label: 'ID Number',
                  controller: _idNumberController,
                  validator: _requiredValidator,
                ),
                _FormField(
                  label: 'Name of HOD',
                  controller: _hodController,
                  validator: _requiredValidator,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Program',
              children: [
                _DateField(
                  label: 'Date of Joining',
                  value: _dateOfJoining,
                  onPick: isSaving
                      ? null
                      : () async {
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dateOfJoining ?? now,
                            firstDate: DateTime(now.year - 20),
                            lastDate: now,
                          );
                          if (picked != null) {
                            setState(() => _dateOfJoining = picked);
                          }
                        },
                ),
                const SizedBox(height: 8),
                _ReadonlyTile(
                  label: 'Months into program',
                  value: _dateOfJoining == null
                      ? 'Select date of joining'
                      : '${_monthsIntoProgram(_dateOfJoining!)} months',
                ),
              ],
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
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _loadFromProfile(Profile profile) {
    setState(() {
      _initialized = true;
      _nameController.text = profile.name;
      _ageController.text = profile.age.toString();
      _employeeIdController.text = profile.employeeId;
      _phoneController.text = profile.phone;
      _emailController.text = profile.email;
      _idNumberController.text = profile.idNumber ?? '';
      _hodController.text = profile.hodName ?? '';
      _dob = profile.dob;
      _dateOfJoining = profile.dateOfJoining;
      _designation = profile.designation;
      _centre = profile.aravindCentre ?? profile.centre;
      _gender = profile.gender ?? profileGenders.first;
      _degrees = profile.degrees;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null || _dateOfJoining == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all dates.')),
      );
      return;
    }
    if (_degrees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one degree.')),
      );
      return;
    }

    final profile = ref.read(profileControllerProvider).profile;
    if (profile == null) return;

    final updated = profile.copyWith(
      name: _nameController.text.trim(),
      age: int.parse(_ageController.text.trim()),
      designation: _designation,
      centre: _centre,
      employeeId: _employeeIdController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      dob: _dob,
      gender: _gender,
      degrees: _degrees,
      aravindCentre: _centre,
      idNumber: _idNumberController.text.trim(),
      dateOfJoining: _dateOfJoining,
      hodName: _hodController.text.trim(),
    );

    await ref.read(profileControllerProvider.notifier).upsertProfile(updated);
    if (mounted) {
      setState(() => _editing = false);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _joinList(List<String> items) {
    if (items.isEmpty) return '-';
    return items.join(', ');
  }

  int _monthsIntoProgram(DateTime joining) {
    final now = DateTime.now();
    var months = (now.year - joining.year) * 12 + (now.month - joining.month);
    if (now.day < joining.day) months -= 1;
    return months < 0 ? 0 : months;
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
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

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
  });

  final String label;
  final DateTime? value;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? 'Select date'
        : '${value!.year}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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

class _ReadonlyTile extends StatelessWidget {
  const _ReadonlyTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
