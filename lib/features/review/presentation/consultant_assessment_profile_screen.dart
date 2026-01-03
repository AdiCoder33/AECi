import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../community/application/community_controller.dart';
import '../../logbook/domain/logbook_sections.dart';
import '../../profile/data/profile_model.dart';
import '../application/consultant_assessments_controller.dart';

class ConsultantAssessmentProfileScreen extends ConsumerWidget {
  const ConsultantAssessmentProfileScreen({
    super.key,
    required this.traineeId,
  });

  final String traineeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(communityProfileProvider(traineeId));
    final entriesAsync = ref.watch(traineeSubmissionItemsProvider(traineeId));

    return Scaffold(
      appBar: AppBar(
        title: profileAsync.maybeWhen(
          data: (profile) => Text(profile?.name ?? 'Profile'),
          orElse: () => const Text('Profile'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          profileAsync.when(
            data: (profile) {
              if (profile == null) {
                return const _InfoCard(
                  title: 'Profile not found',
                  subtitle: 'Unable to load trainee details.',
                );
              }
              return _ProfileCard(profile: profile);
            },
            loading: () => const _LoadingCard(),
            error: (e, _) => _InfoCard(
              title: 'Failed to load profile',
              subtitle: e.toString(),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Submitted Logbook Items',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          entriesAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const _InfoCard(
                  title: 'No submissions yet',
                  subtitle: 'This trainee has not submitted any logbook items.',
                );
              }
              final groups = _groupItems(items);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final group in groups) ...[
                    Text(
                      group.label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ...group.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SubmissionItemCard(
                          item: item,
                          onTap: () => _openItem(context, item),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => _InfoCard(
              title: 'Failed to load entries',
              subtitle: e.toString(),
            ),
          ),
        ],
      ),
    );
  }

  void _openItem(BuildContext context, SubmissionItemDetail item) {
    switch (item.entityType) {
      case 'elog_entry':
        context.pushNamed('logbookDetail', pathParameters: {'id': item.entityId});
        break;
      case 'clinical_case':
        context.pushNamed(
          'caseDetail',
          pathParameters: {'id': item.entityId},
          queryParameters: {'readonly': '1'},
        );
        break;
      case 'publication':
        context.pushNamed('pubDetail', pathParameters: {'id': item.entityId});
        break;
    }
  }

  List<_SectionGroup> _groupItems(List<SubmissionItemDetail> items) {
    final order = <String, int>{
      for (var i = 0; i < logbookSections.length; i++)
        logbookSections[i].key: i,
    };
    final grouped = <String, List<SubmissionItemDetail>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.moduleKey, () => []).add(item);
    }
    final labels = {
      for (final section in logbookSections) section.key: section.label,
    };
    final keys = grouped.keys.toList()
      ..sort((a, b) => (order[a] ?? 999).compareTo(order[b] ?? 999));
    return keys.map((key) {
      final list = grouped[key] ?? [];
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return _SectionGroup(
        key,
        labels[key] ?? key,
        list,
      );
    }).toList();
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                foregroundColor: theme.colorScheme.primary,
                radius: 22,
                child: Text(_initials(profile.name)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        profile.designation,
                        (profile.aravindCentre ?? profile.centre),
                      ].where((e) => e.isNotEmpty).join(' | '),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: 'Employee ID',
            value: profile.employeeId,
          ),
          if (profile.email.isNotEmpty)
            _InfoRow(
              label: 'Email',
              value: profile.email,
            ),
          if (profile.phone.isNotEmpty)
            _InfoRow(
              label: 'Phone',
              value: profile.phone,
            ),
        ],
      ),
    );
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 12),
          Text('Loading profile...'),
        ],
      ),
    );
  }
}

class _SubmissionItemCard extends StatelessWidget {
  const _SubmissionItemCard({
    required this.item,
    required this.onTap,
  });

  final SubmissionItemDetail item;
  final VoidCallback onTap;

  IconData _icon() {
    switch (item.entityType) {
      case 'elog_entry':
        return Icons.menu_book_outlined;
      case 'clinical_case':
        return Icons.local_hospital_outlined;
      case 'publication':
        return Icons.article_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
          foregroundColor: Theme.of(context).colorScheme.primary,
          child: Icon(_icon()),
        ),
        title: Text(item.title),
        subtitle: Text(item.subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _SectionGroup {
  const _SectionGroup(this.key, this.label, this.items);

  final String key;
  final String label;
  final List<SubmissionItemDetail> items;
}
