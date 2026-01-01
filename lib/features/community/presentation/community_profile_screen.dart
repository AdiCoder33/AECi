import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/community_controller.dart';
import '../../profile/data/profile_model.dart';

class CommunityProfileScreen extends ConsumerWidget {
  const CommunityProfileScreen({super.key, required this.profileId});

  final String profileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(communityProfileProvider(profileId));
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found.'));
          }
          return _ProfileBody(profile: profile);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load profile: $e')),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CircleAvatar(
              radius: 44,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
              foregroundColor: theme.colorScheme.primary,
              backgroundImage: profile.profilePhotoUrl != null &&
                      profile.profilePhotoUrl!.isNotEmpty
                  ? NetworkImage(profile.profilePhotoUrl!)
                  : null,
              child: profile.profilePhotoUrl == null ||
                      profile.profilePhotoUrl!.isEmpty
                  ? Text(
                      _initials(profile.name),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
          ),
          _ProfileSection(
            title: 'Personal Information',
            icon: Icons.person_outline,
            children: [
              _InfoRow(label: 'Name', value: profile.name),
              _InfoRow(label: 'Age', value: '${profile.age}'),
              _InfoRow(label: 'Gender', value: profile.gender ?? '-'),
              _InfoRow(label: 'Date of Birth', value: _formatDate(profile.dob)),
              if (profile.degrees.isNotEmpty)
                _InfoRow(label: 'Degrees', value: profile.degrees.join(', ')),
            ],
          ),
          const SizedBox(height: 16),
          _ProfileSection(
            title: 'Professional Details',
            icon: Icons.work_outline,
            children: [
              _InfoRow(label: 'Designation', value: profile.designation),
              _InfoRow(
                label: 'Centre',
                value: profile.aravindCentre ?? profile.centre,
              ),
              _InfoRow(label: 'Hospital', value: profile.hospital),
              _InfoRow(label: 'Employee ID', value: profile.employeeId),
              if (profile.idNumber != null && profile.idNumber!.isNotEmpty)
                _InfoRow(label: 'ID Number', value: profile.idNumber!),
              if (profile.hodName != null && profile.hodName!.isNotEmpty)
                _InfoRow(label: 'HOD Name', value: profile.hodName!),
              if (profile.dateOfJoining != null)
                _InfoRow(
                  label: 'Date of Joining',
                  value: _formatDate(profile.dateOfJoining!),
                ),
              if (profile.dateOfJoining != null)
                _InfoRow(
                  label: 'Months in Program',
                  value: '${_monthsIntoProgram(profile.dateOfJoining!)} months',
                ),
            ],
          ),
          const SizedBox(height: 16),
          _ProfileSection(
            title: 'Contact Information',
            icon: Icons.contact_phone_outlined,
            children: [
              _InfoRow(label: 'Phone', value: profile.phone),
              _InfoRow(label: 'Email', value: profile.email),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  int _monthsIntoProgram(DateTime joining) {
    final now = DateTime.now();
    var months = (now.year - joining.year) * 12 + (now.month - joining.month);
    if (now.day < joining.day) months -= 1;
    return months < 0 ? 0 : months;
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
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
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
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
                    color: theme.colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
