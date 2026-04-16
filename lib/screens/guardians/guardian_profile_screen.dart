/// EduX School Management System
/// Guardian Profile Screen - View guardian details
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/widgets/app_error_state.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../providers/guardian_provider.dart';
import '../../database/app_database.dart';

class GuardianProfileScreen extends ConsumerWidget {
  final int guardianId;

  const GuardianProfileScreen({super.key, required this.guardianId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guardianAsync = ref.watch(guardianByIdProvider(guardianId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian Profile'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.edit),
            onPressed: () => context.go('/guardians/$guardianId/edit'),
            tooltip: 'Edit Guardian',
          ),
        ],
      ),
      body: guardianAsync.when(
        loading: () => const Center(child: AppLoadingIndicator()),
        error: (error, stack) => AppErrorState(
          message: 'Failed to load guardian profile',
          onRetry: () => ref.refresh(guardianByIdProvider(guardianId)),
        ),
        data: (guardian) {
          if (guardian == null) {
            return const AppErrorState(message: 'Guardian not found');
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                _buildProfileHeader(context, guardian, theme),
                const SizedBox(height: 32),

                // Contact Info
                _buildSectionTitle(theme, 'Contact Information'),
                const SizedBox(height: 16),
                _buildContactInfo(context, guardian),
                const SizedBox(height: 32),

                // Employment Info
                _buildSectionTitle(theme, 'Employment Information'),
                const SizedBox(height: 16),
                _buildEmploymentInfo(context, guardian),
                const SizedBox(height: 32),

                // Associated Students
                _buildSectionTitle(theme, 'Associated Students'),
                const SizedBox(height: 16),
                _buildAssociatedStudents(context, ref, guardianId),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    Guardian guardian,
    ThemeData theme,
  ) {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            '${guardian.firstName[0]}${guardian.lastName[0]}'.toUpperCase(),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${guardian.firstName} ${guardian.lastName}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                guardian.relation,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              if (guardian.cnic != null) ...[
                const SizedBox(height: 4),
                Text(
                  'CNIC: ${guardian.cnic}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildContactInfo(BuildContext context, Guardian guardian) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow(
              context,
              LucideIcons.phone,
              'Phone',
              guardian.phone,
              onTap: () => _launchURL('tel:${guardian.phone}'),
            ),
            if (guardian.alternatePhone != null) ...[
              const Divider(),
              _buildInfoRow(
                context,
                LucideIcons.phoneCall,
                'Alt. Phone',
                guardian.alternatePhone!,
                onTap: () => _launchURL('tel:${guardian.alternatePhone}'),
              ),
            ],
            if (guardian.email != null) ...[
              const Divider(),
              _buildInfoRow(
                context,
                LucideIcons.mail,
                'Email',
                guardian.email!,
                onTap: () => _launchURL('mailto:${guardian.email}'),
              ),
            ],
            if (guardian.address != null) ...[
              const Divider(),
              _buildInfoRow(
                context,
                LucideIcons.mapPin,
                'Address',
                '${guardian.address}${guardian.city != null ? ', ${guardian.city}' : ''}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmploymentInfo(BuildContext context, Guardian guardian) {
    if (guardian.occupation == null && guardian.workplace == null) {
      return const Text('No employment information available');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (guardian.occupation != null)
              _buildInfoRow(
                context,
                LucideIcons.briefcase,
                'Occupation',
                guardian.occupation!,
              ),
            if (guardian.workplace != null) ...[
              if (guardian.occupation != null) const Divider(),
              _buildInfoRow(
                context,
                LucideIcons.building,
                'Workplace',
                guardian.workplace!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAssociatedStudents(
    BuildContext context,
    WidgetRef ref,
    int guardianId,
  ) {
    // In a real app, we'd fetch students linked to this guardian
    // For now, prompt to view student profile to see links
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(LucideIcons.info, color: Colors.blue),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'To view associated students, please visit the student details page.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(value, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: Theme.of(context).colorScheme.outline,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
