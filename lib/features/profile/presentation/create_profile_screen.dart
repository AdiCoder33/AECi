import '../data/profile_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
import '../application/profile_controller.dart';
import '../data/profile_constants.dart';
import '../data/profile_model.dart';

class CreateProfileScreen extends ConsumerStatefulWidget {
  final Profile? profile;
  const CreateProfileScreen({super.key, this.profile});

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
  final _idNumberController = TextEditingController();
  final _hodController = TextEditingController();
  DateTime? _dob;
  DateTime? _dateOfJoining;
  String _designation = profileDesignations.first;
  String _centre = profileCentres.first;
  String _gender = profileGenders.first;
  List<String> _degrees = [];

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authControllerProvider);
    final profile = widget.profile;
    if (profile != null) {
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
      _centre = profile.centre;
      _gender = profile.gender ?? profileGenders.first;
      _degrees = List<String>.from(profile.degrees);
    } else {
      _emailController.text = auth.session?.user.email ?? '';
    }
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
    final isSaving = profileState.isLoading;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFEAF2FF), Color(0xFFF7F9FC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    children: [
                      // Header Section
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0B5FFF),
                                    Color(0xFF0A2E73),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF0B5FFF,
                                    ).withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person_add_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Complete Your Profile',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0A2E73),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Let\'s set up your professional profile',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: isSaving
                                  ? null
                                  : () => ref
                                        .read(authControllerProvider.notifier)
                                        .signOut(),
                              icon: const Icon(Icons.logout, size: 16),
                              label: const Text('Sign Out'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Form Card
                      Card(
                        elevation: 10,
                        shadowColor: Colors.black12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Section: Personal Information
                                _SectionHeader(
                                  icon: Icons.person_outline,
                                  title: 'Personal Information',
                                ),
                                const SizedBox(height: 16),
                                if (profileState.errorMessage != null) ...[
                                  _ErrorBanner(
                                    message: profileState.errorMessage!,
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                _FormField(
                                  label: 'Full Name',
                                  controller: _nameController,
                                  prefixIcon: Icons.badge_outlined,
                                  validator: _requiredValidator,
                                  enabled: !isSaving,
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _FormField(
                                        label: 'Age',
                                        controller: _ageController,
                                        prefixIcon: Icons.cake_outlined,
                                        keyboardType: TextInputType.number,
                                        enabled: !isSaving,
                                        validator: (value) {
                                          final v = value?.trim() ?? '';
                                          if (v.isEmpty) return 'Required';
                                          final age = int.tryParse(v);
                                          if (age == null ||
                                              age < 18 ||
                                              age > 80) {
                                            return 'Age must be 18-80';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _GenderDropdown(
                                        value: _gender,
                                        enabled: !isSaving,
                                        onChanged: (value) =>
                                            setState(() => _gender = value!),
                                      ),
                                    ),
                                  ],
                                ),
                                _DobField(
                                  dob: _dob,
                                  enabled: !isSaving,
                                  onPick: isSaving
                                      ? null
                                      : () async {
                                          final now = DateTime.now();
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate: DateTime(
                                              now.year - 25,
                                            ),
                                            firstDate: DateTime(now.year - 80),
                                            lastDate: DateTime(now.year - 18),
                                            builder: (context, child) {
                                              return Theme(
                                                data: Theme.of(context).copyWith(
                                                  colorScheme:
                                                      const ColorScheme.light(
                                                        primary: Color(
                                                          0xFF0B5FFF,
                                                        ),
                                                      ),
                                                ),
                                                child: child!,
                                              );
                                            },
                                          );
                                          if (picked != null) {
                                            setState(() => _dob = picked);
                                          }
                                        },
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Select Degrees',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0A2E73),
                                  ),
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
                                                  _degrees = [
                                                    ..._degrees,
                                                    degree,
                                                  ];
                                                } else {
                                                  _degrees = _degrees
                                                      .where((d) => d != degree)
                                                      .toList();
                                                }
                                              });
                                            },
                                      selectedColor: const Color(
                                        0xFF0B5FFF,
                                      ).withOpacity(0.2),
                                      checkmarkColor: const Color(0xFF0B5FFF),
                                      side: BorderSide(
                                        color: selected
                                            ? const Color(0xFF0B5FFF)
                                            : Colors.grey[300]!,
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 24),
                                // Section: Professional Details
                                _SectionHeader(
                                  icon: Icons.work_outline,
                                  title: 'Professional Details',
                                ),
                                const SizedBox(height: 16),
                                _DesignationDropdown(
                                  value: _designation,
                                  enabled: !isSaving,
                                  onChanged: (value) =>
                                      setState(() => _designation = value!),
                                ),
                                _CentreDropdown(
                                  value: _centre,
                                  enabled: !isSaving,
                                  onChanged: (value) =>
                                      setState(() => _centre = value!),
                                ),
                                _ReadonlyField(
                                  label: 'Hospital',
                                  value: 'Aravind Eye Hospital',
                                  icon: Icons.local_hospital_outlined,
                                ),
                                _FormField(
                                  label: 'Employee ID',
                                  controller: _employeeIdController,
                                  prefixIcon: Icons.badge,
                                  enabled: !isSaving,
                                  validator: _requiredValidator,
                                ),
                                _FormField(
                                  label: 'ID Number',
                                  controller: _idNumberController,
                                  prefixIcon: Icons.credit_card,
                                  enabled: !isSaving,
                                  validator: _requiredValidator,
                                ),
                                _FormField(
                                  label: 'Name of HOD',
                                  controller: _hodController,
                                  prefixIcon: Icons.supervisor_account,
                                  enabled: !isSaving,
                                  validator: _requiredValidator,
                                ),
                                _DateField(
                                  label: 'Date of Joining',
                                  value: _dateOfJoining,
                                  onPick: isSaving
                                      ? null
                                      : () async {
                                          final now = DateTime.now();
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate: now,
                                            firstDate: DateTime(now.year - 20),
                                            lastDate: now,
                                            builder: (context, child) {
                                              return Theme(
                                                data: Theme.of(context).copyWith(
                                                  colorScheme:
                                                      const ColorScheme.light(
                                                        primary: Color(
                                                          0xFF0B5FFF,
                                                        ),
                                                      ),
                                                ),
                                                child: child!,
                                              );
                                            },
                                          );
                                          if (picked != null) {
                                            setState(
                                              () => _dateOfJoining = picked,
                                            );
                                          }
                                        },
                                ),
                                if (_dateOfJoining != null)
                                  _ReadonlyField(
                                    label: 'Months into program',
                                    value:
                                        '${_monthsIntoProgram(_dateOfJoining!)} months',
                                    icon: Icons.timeline,
                                  ),
                                const SizedBox(height: 24),
                                // Section: Contact Information
                                _SectionHeader(
                                  icon: Icons.contact_phone_outlined,
                                  title: 'Contact Information',
                                ),
                                const SizedBox(height: 16),
                                _FormField(
                                  label: 'Phone Number',
                                  controller: _phoneController,
                                  prefixIcon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  enabled: !isSaving,
                                  validator: (value) {
                                    final v = value?.trim() ?? '';
                                    if (v.isEmpty) return 'Required';
                                    final numeric = RegExp(r'^[0-9]{10}$');
                                    if (!numeric.hasMatch(v)) {
                                      return 'Enter valid 10-digit number';
                                    }
                                    return null;
                                  },
                                ),
                                _FormField(
                                  label: 'Email Address',
                                  controller: _emailController,
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  enabled: !isSaving,
                                  validator: (value) {
                                    final v = value?.trim() ?? '';
                                    if (v.isEmpty) return 'Required';
                                    if (!v.contains('@'))
                                      return 'Enter valid email';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 32),
                                // Submit Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: isSaving ? null : _saveProfile,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0B5FFF),
                                      foregroundColor: Colors.white,
                                      elevation: 2,
                                      shadowColor: const Color(
                                        0xFF0B5FFF,
                                      ).withOpacity(0.3),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: isSaving
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.check_circle_outline,
                                                size: 20,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'Complete Profile',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Center(
                                  child: Text(
                                    'All fields are required',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
    if (_dateOfJoining == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Date of Joining')),
      );
      return;
    }
    if (_degrees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one degree')),
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
      gender: _gender,
      degrees: _degrees,
      aravindCentre: _centre,
      idNumber: _idNumberController.text.trim(),
      dateOfJoining: _dateOfJoining,
      hodName: _hodController.text.trim(),
    );

    await ref.read(profileControllerProvider.notifier).upsertProfile(profile);

    final profileState = ref.read(profileControllerProvider);
    if (profileState.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(profileState.errorMessage!),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } else if (profileState.profile != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      context.go('/home');
    }
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  int _monthsIntoProgram(DateTime joining) {
    final now = DateTime.now();
    var months = (now.year - joining.year) * 12 + (now.month - joining.month);
    if (now.day < joining.day) months -= 1;
    return months < 0 ? 0 : months;
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.controller,
    this.prefixIcon,
    this.keyboardType,
    this.validator,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        enabled: enabled,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0B5FFF), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0B5FFF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF0B5FFF)),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0A2E73),
          ),
        ),
      ],
    );
  }
}

class _DesignationDropdown extends StatelessWidget {
  const _DesignationDropdown({
    required this.value,
    required this.onChanged,
    required this.enabled,
  });

  final String value;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        items: profileDesignations
            .map(
              (d) => DropdownMenuItem(
                value: d,
                child: Row(
                  children: [
                    Icon(
                      d == 'Consultant'
                          ? Icons.medical_services
                          : d == 'Resident'
                          ? Icons.school
                          : Icons.badge,
                      size: 18,
                      color: const Color(0xFF0B5FFF),
                    ),
                    const SizedBox(width: 12),
                    Text(d),
                  ],
                ),
              ),
            )
            .toList(),
        onChanged: enabled ? onChanged : null,
        decoration: InputDecoration(
          labelText: 'Designation',
          prefixIcon: const Icon(Icons.work_outline, size: 20),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0B5FFF), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class _CentreDropdown extends StatelessWidget {
  const _CentreDropdown({
    required this.value,
    required this.onChanged,
    required this.enabled,
  });

  final String value;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        items: profileCentres
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
        onChanged: enabled ? onChanged : null,
        decoration: InputDecoration(
          labelText: 'Centre',
          prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0B5FFF), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class _GenderDropdown extends StatelessWidget {
  const _GenderDropdown({
    required this.value,
    required this.onChanged,
    required this.enabled,
  });

  final String value;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        items: const [
          DropdownMenuItem(value: 'male', child: Text('Male')),
          DropdownMenuItem(value: 'female', child: Text('Female')),
          DropdownMenuItem(value: 'other', child: Text('Other')),
        ],
        onChanged: enabled ? onChanged : null,
        decoration: InputDecoration(
          labelText: 'Gender',
          prefixIcon: const Icon(Icons.person_outline, size: 20),
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF0B5FFF), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class _DobField extends StatelessWidget {
  const _DobField({
    required this.dob,
    required this.onPick,
    required this.enabled,
  });

  final DateTime? dob;
  final VoidCallback? onPick;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final text = dob == null
        ? 'Select date of birth'
        : '${dob!.day.toString().padLeft(2, '0')}/${dob!.month.toString().padLeft(2, '0')}/${dob!.year}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: enabled ? onPick : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: dob == null ? Colors.grey[600] : const Color(0xFF0B5FFF),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date of Birth',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 15,
                        color: dob == null ? Colors.grey[600] : Colors.black87,
                        fontWeight: dob == null
                            ? FontWeight.normal
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
            ],
          ),
        ),
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
        : '${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.year}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 20,
                color: value == null
                    ? Colors.grey[600]
                    : const Color(0xFF0B5FFF),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 15,
                        color: value == null
                            ? Colors.grey[600]
                            : Colors.black87,
                        fontWeight: value == null
                            ? FontWeight.normal
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadonlyField extends StatelessWidget {
  const _ReadonlyField({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0B5FFF).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF0B5FFF).withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF0B5FFF)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0B5FFF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
