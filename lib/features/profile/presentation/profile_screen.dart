import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

import '../../auth/application/auth_controller.dart';
import '../application/profile_controller.dart';
import '../data/profile_constants.dart';
import '../data/profile_model.dart';
import '../../../core/supabase_client.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _editMode = false;
  File? _imageFile;
  bool _uploadingImage = false;

  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _employeeIdController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  DateTime? _dob;
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
          IconButton(
            icon: const Icon(Icons.file_upload),
            onPressed: () => context.push('/export'),
          ),
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            onPressed: () => context.push('/storage-tools'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: profile.profilePhotoUrl == null
                                      ? const LinearGradient(
                                          colors: [Color(0xFF0B5FFF), Color(0xFF6366F1)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: profile.profilePhotoUrl != null ? Colors.grey[200] : null,
                                  border: Border.all(color: Colors.white, width: 4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0B5FFF).withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                  image: profile.profilePhotoUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(profile.profilePhotoUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: profile.profilePhotoUrl == null
                                    ? Center(
                                        child: Text(
                                          profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'A',
                                          style: const TextStyle(
                                            fontSize: 42,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                    : _uploadingImage
                                        ? const Center(
                                            child: CircularProgressIndicator(
                                              color: Color(0xFF0B5FFF),
                                              strokeWidth: 3,
                                            ),
                                          )
                                        : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _uploadingImage ? null : _pickAndUploadImage,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0B5FFF),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: _uploadingImage
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.camera_alt,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            profile.name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B5FFF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF0B5FFF).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              profile.designation,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0B5FFF),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile.centre,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Divider(height: 1),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Professional Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _editMode = !_editMode;
                              if (!_editMode) {
                                // Reset form when canceling
                                _seedControllers(profile);
                              }
                            });
                          },
                          child: Text(
                            _editMode ? 'Cancel' : 'Edit',
                            style: TextStyle(
                              color: _editMode ? const Color(0xFFEF4444) : const Color(0xFF0B5FFF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
    _gender = profile.gender ?? 'male';
  }

  void _save(String userId) async {
    if (!_formKey.currentState!.validate() || _dob == null) {
      if (_dob == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select Date of Birth'),
            backgroundColor: Color(0xFFEF4444),
          ),
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
      gender: _gender,
    );
    await ref.read(profileControllerProvider.notifier).upsertProfile(profile);
    final error = ref.read(profileControllerProvider).errorMessage;
    if (mounted) {
      if (error == null) {
        setState(() => _editMode = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _imageFile = File(image.path);
        _uploadingImage = true;
      });

      final profile = ref.read(profileControllerProvider).profile;
      if (profile == null) return;

      // Upload to Supabase storage
      final userId = profile.id;
      final fileName = 'profile_$userId.jpg';
      final bytes = await _imageFile!.readAsBytes();

      final supabase = ref.read(supabaseClientProvider);
      await supabase.storage.from('profiles').uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(upsert: true),
          );

      // Get public URL
      final photoUrl = supabase.storage.from('profiles').getPublicUrl(fileName);

      // Update profile with photo URL
      final updatedProfile = profile.copyWith(profilePhotoUrl: photoUrl);
      await ref.read(profileControllerProvider.notifier).upsertProfile(updatedProfile);

      if (mounted) {
        setState(() => _uploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingImage = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload photo: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
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
        _Row(label: 'Gender', value: profile.gender ?? 'Not specified'),
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
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
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
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
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
