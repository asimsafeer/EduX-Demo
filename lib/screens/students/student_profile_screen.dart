/// EduX School Management System
/// Student Profile Screen - View student details
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../database/app_database.dart';
import '../../providers/student_provider.dart';
import '../../providers/guardian_provider.dart';

import '../../core/utils/pdf_helper.dart';
import '../../core/widgets/app_loading_indicator.dart';
import '../../core/widgets/app_error_state.dart';

/// Screen for viewing student profile details
class StudentProfileScreen extends ConsumerWidget {
  final int studentId;

  const StudentProfileScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(studentByIdProvider(studentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/students'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Student',
            onPressed: () => context.go('/students/$studentId/edit'),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'print':
                  _printProfile(context, ref, studentId);
                  break;
                case 'delete':
                  _showDeleteDialog(context, ref);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'print',
                child: ListTile(
                  leading: Icon(Icons.print),
                  title: Text('Print Profile'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text(
                    'Delete Student',
                    style: TextStyle(color: Colors.red),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: studentAsync.when(
        data: (studentData) {
          if (studentData == null) {
            return const Center(child: Text('Student not found'));
          }

          return _ProfileContent(studentData: studentData);
        },
        loading: () => const Center(child: AppLoadingIndicator()),
        error: (error, stack) => AppErrorState(
          message: 'Failed to load student: ${error.toString()}',
          onRetry: () => ref.invalidate(studentByIdProvider(studentId)),
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: const Text(
          'Are you sure you want to delete this student? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(studentOperationProvider.notifier)
          .deleteStudent(studentId);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Student deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/students');
      }
    }
  }
}

class _ProfileContent extends ConsumerWidget {
  final dynamic studentData; // StudentWithEnrollment

  const _ProfileContent({required this.studentData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final student = studentData.student as Student;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          _buildHeaderCard(context, student),

          const SizedBox(height: 24),

          // Content in two columns
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column
              Expanded(
                child: Column(
                  children: [
                    _buildInfoCard(
                      context,
                      'Personal Information',
                      Icons.person,
                      [
                        _InfoRow('Admission No', student.admissionNumber),
                        _InfoRow('Gender', _capitalize(student.gender)),
                        if (student.dateOfBirth != null)
                          _InfoRow(
                            'Date of Birth',
                            dateFormat.format(student.dateOfBirth!),
                          ),
                        if (student.bloodGroup != null)
                          _InfoRow('Blood Group', student.bloodGroup!),
                        if (student.religion != null)
                          _InfoRow('Religion', student.religion!),
                        _InfoRow('Nationality', student.nationality),
                        if (student.cnic != null)
                          _InfoRow('CNIC/B-Form', student.cnic!),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      context,
                      'Contact Information',
                      Icons.phone,
                      [
                        if (student.phone != null)
                          _InfoRow('Phone', student.phone!),
                        if (student.email != null)
                          _InfoRow('Email', student.email!),
                        if (student.address != null)
                          _InfoRow('Address', student.address!),
                        if (student.city != null)
                          _InfoRow('City', student.city!),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Right column
              Expanded(
                child: Column(
                  children: [
                    _buildInfoCard(
                      context,
                      'Academic Information',
                      Icons.school,
                      [
                        _InfoRow('Class', studentData.classSection),
                        _InfoRow(
                          'Admission Date',
                          dateFormat.format(student.admissionDate),
                        ),
                        _InfoRow('Status', _capitalize(student.status)),
                        if (studentData.currentEnrollment?.rollNumber != null)
                          _InfoRow(
                            'Roll Number',
                            studentData.currentEnrollment!.rollNumber!,
                          ),
                      ],
                    ),
                    if (student.medicalInfo != null ||
                        student.allergies != null ||
                        student.specialNeeds != null) ...[
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        context,
                        'Medical Information',
                        Icons.medical_services,
                        [
                          if (student.medicalInfo != null)
                            _InfoRow('Medical Notes', student.medicalInfo!),
                          if (student.allergies != null)
                            _InfoRow('Allergies', student.allergies!),
                          if (student.specialNeeds != null)
                            _InfoRow('Special Needs', student.specialNeeds!),
                        ],
                      ),
                    ],
                    if (student.notes != null) ...[
                      const SizedBox(height: 16),
                      _buildInfoCard(context, 'Additional Notes', Icons.note, [
                        _InfoRow('Notes', student.notes!),
                      ]),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Guardian section placeholder
          _buildGuardianSection(context, ref),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, Student student) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 48,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                '${student.studentName[0]}${(student.fatherName ?? '?')[0]}'
                    .toUpperCase(),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 24),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${student.studentName} ${student.fatherName ?? ''}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Admission No: ${student.admissionNumber}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatusChip(student.status, theme),
                      const SizedBox(width: 8),
                      Chip(
                        avatar: Icon(
                          student.gender.toLowerCase() == 'male'
                              ? Icons.male
                              : Icons.female,
                          size: 18,
                        ),
                        label: Text(_capitalize(student.gender)),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    IconData icon,
    List<_InfoRow> rows,
  ) {
    final theme = Theme.of(context);

    if (rows.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        row.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(row.value, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuardianSection(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.family_restroom,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Guardians',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Guardian'),
                  onPressed: () {
                    context.pushNamed(
                      'student-guardian-add',
                      pathParameters: {'id': studentData.student.id.toString()},
                    );
                  },
                ),
              ],
            ),
            const Divider(height: 24),
            // Guardians list
            Consumer(
              builder: (context, ref, child) {
                final guardiansAsync = ref.watch(
                  guardiansByStudentProvider(studentData.student.id),
                );

                return guardiansAsync.when(
                  data: (links) {
                    if (links.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(
                                Icons.family_restroom,
                                size: 48,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No guardians added yet',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: links.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final link = links[index];
                        final guardian = link.guardian;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Text(
                              guardian.firstName[0],
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                '${guardian.firstName} ${guardian.lastName}',
                              ),
                              if (link.isPrimary) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Primary',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(guardian.relation),
                              if (guardian.phone.isNotEmpty)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.phone,
                                      size: 14,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(guardian.phone),
                                  ],
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () {
                              context.pushNamed(
                                'student-guardian-edit',
                                pathParameters: {
                                  'id': studentData.student.id.toString(),
                                  'guardianId': guardian.id.toString(),
                                },
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Error: $e')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, ThemeData theme) {
    Color backgroundColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'active':
        backgroundColor = Colors.green.withValues(alpha: 0.15);
        textColor = Colors.green.shade700;
        break;
      case 'withdrawn':
        backgroundColor = Colors.orange.withValues(alpha: 0.15);
        textColor = Colors.orange.shade700;
        break;
      case 'transferred':
        backgroundColor = Colors.blue.withValues(alpha: 0.15);
        textColor = Colors.blue.shade700;
        break;
      default:
        backgroundColor = Colors.grey.withValues(alpha: 0.15);
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        _capitalize(status),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _printProfile(
  BuildContext context,
  WidgetRef ref,
  int studentId,
) async {
  final nav = Navigator.of(context);
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    final studentData = await ref.read(studentByIdProvider(studentId).future);
    if (studentData == null) {
      nav.pop(); // Close loading
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Student data not found')));
      }
      return;
    }

    final guardians = await ref.read(
      guardiansByStudentProvider(studentId).future,
    );

    final schoolSettings = await ref.read(
      schoolSettingsForExportProvider.future,
    );

    if (schoolSettings == null) {
      nav.pop(); // Close loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('School settings not found')),
        );
      }
      return;
    }

    final exportService = ref.read(studentExportServiceProvider);
    final pdfBytes = await exportService.generateStudentProfilePdf(
      student: studentData.student,
      guardians: guardians,
      currentEnrollment: studentData.currentEnrollment,
      schoolClass: studentData.schoolClass,
      section: studentData.section,
      school: schoolSettings,
    );

    nav.pop(); // Close loading

    if (context.mounted) {
      await PdfHelper.previewPdf(
        context,
        pdfBytes,
        'Student_Profile_${studentData.student.admissionNumber}',
      );
    }
  } catch (e) {
    nav.pop(); // Close loading
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: ${e.toString()}')),
      );
    }
  }
}
