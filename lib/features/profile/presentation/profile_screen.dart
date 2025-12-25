import 'create_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_controller.dart';
import '../application/profile_controller.dart';
import '../data/profile_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF0B5FFF)),
            tooltip: 'Edit Profile',
            onPressed: () {
              context.push('/profile/edit');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'Logout',
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
          ),
        ],
      ),
      body: profileState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : profile == null
          ? const Center(child: Text('No profile found'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile photo section
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: const Color(0xFF0B5FFF),
                          backgroundImage:
                              profile.profilePhotoUrl != null &&
                                  profile.profilePhotoUrl!.isNotEmpty
                              ? NetworkImage(profile.profilePhotoUrl!)
                              : null,
                          child:
                              profile.profilePhotoUrl == null ||
                                  profile.profilePhotoUrl!.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  size: 48,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              // Navigate to profile media screen for photo upload
                              context.push('/profile/media');
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(6),
                              child: const Icon(
                                Icons.edit,
                                size: 20,
                                color: Color(0xFF0B5FFF),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ProfileSection(
                    title: 'Personal Information',
                    icon: Icons.person_outline,
                    children: [
                      _InfoTile(label: 'Name', value: profile.name),
                      _InfoTile(label: 'Age', value: '${profile.age}'),
                      _InfoTile(
                        label: 'Gender',
                        value: profile.gender ?? 'Not specified',
                      ),
                      _InfoTile(
                        label: 'Date of Birth',
                        value:
                            '${profile.dob.day}/${profile.dob.month}/${profile.dob.year}',
                      ),
                      if (profile.degrees.isNotEmpty)
                        _InfoTile(
                          label: 'Degrees',
                          value: profile.degrees.join(', '),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ProfileSection(
                    title: 'Professional Details',
                    icon: Icons.work_outline,
                    children: [
                      _InfoTile(
                        label: 'Designation',
                        value: profile.designation,
                      ),
                      _InfoTile(label: 'Centre', value: profile.centre),
                      _InfoTile(label: 'Hospital', value: profile.hospital),
                      _InfoTile(
                        label: 'Employee ID',
                        value: profile.employeeId,
                      ),
                      if (profile.idNumber != null)
                        _InfoTile(label: 'ID Number', value: profile.idNumber!),
                      if (profile.hodName != null)
                        _InfoTile(label: 'HOD Name', value: profile.hodName!),
                      if (profile.dateOfJoining != null)
                        _InfoTile(
                          label: 'Date of Joining',
                          value:
                              '${profile.dateOfJoining!.day}/${profile.dateOfJoining!.month}/${profile.dateOfJoining!.year}',
                        ),
                      if (profile.dateOfJoining != null)
                        _InfoTile(
                          label: 'Months in Program',
                          value:
                              '${_monthsIntoProgram(profile.dateOfJoining!)} months',
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ProfileSection(
                    title: 'Contact Information',
                    icon: Icons.contact_phone_outlined,
                    children: [
                      _InfoTile(label: 'Phone', value: profile.phone),
                      _InfoTile(label: 'Email', value: profile.email),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  int _monthsIntoProgram(DateTime joining) {
    final now = DateTime.now();
    var months = (now.year - joining.year) * 12 + (now.month - joining.month);
    if (now.day < joining.day) months -= 1;
    return months < 0 ? 0 : months;
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
