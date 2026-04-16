/// EduX School Management System
/// Student Reports Tab
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../services/report_service.dart';
import 'report_card.dart';
import 'selector_dialogs.dart';

/// Student reports tab content
class StudentReportsTab extends ConsumerWidget {
  final String searchQuery;
  const StudentReportsTab({super.key, this.searchQuery = ''});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportService = ref.watch(reportServiceProvider);

    final reports = [
      ReportItem(
        title: 'Student List',
        description: 'Complete list of all students with enrollment details',
        icon: LucideIcons.users,
        exportFormats: ['pdf', 'excel'],
        onGenerate: () => _showSortOptionsDialog(
          context,
          title: 'Sort Student List By',
          options: const [
            ('studentName', 'Student Name (Alphabetic)'),
            ('admissionNumber', 'Admission Number'),
            ('admissionDate', 'Admission Date'),
          ],
          onSelected: (sortBy) => _generateReport(
            context,
            () => reportService.generateStudentList(context, sortBy: sortBy),
          ),
        ),
      ),
      ReportItem(
        title: 'Class-wise Student List',
        description: 'Students grouped by class and section',
        icon: LucideIcons.layoutList,
        exportFormats: ['pdf', 'excel'],
        onGenerate: () => _showClassSelector(context, reportService),
      ),
      ReportItem(
        title: 'Student Contact Directory',
        description: 'Contact information for all students and guardians',
        icon: LucideIcons.phone,
        exportFormats: ['pdf', 'excel'],
        onGenerate: () => _generateReport(
          context,
          () => reportService.generateContactDirectory(context),
        ),
      ),
      ReportItem(
        title: 'Admission Report',
        description: 'New admissions by month/year',
        icon: LucideIcons.userPlus,
        exportFormats: ['pdf', 'excel'],
        onGenerate: () => _showAdmissionReportOptions(context, reportService),
      ),
      ReportItem(
        title: 'Student Profile',
        description: 'Detailed individual student report',
        icon: LucideIcons.userCircle,
        exportFormats: ['pdf'],
        onGenerate: () => _showStudentSelector(context, reportService),
      ),
      ReportItem(
        title: 'Birthday List',
        description: 'Students with birthdays - filter by today, specific date, or upcoming',
        icon: LucideIcons.cake,
        exportFormats: ['pdf', 'excel'],
        onGenerate: () => _showBirthdayFilterOptions(context, reportService),
      ),
    ];

    return ReportGrid(reports: reports, searchQuery: searchQuery);
  }

  void _generateReport(
    BuildContext context,
    Future<void> Function() generator,
  ) async {
    _showLoadingDialog(context);
    try {
      await generator();
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report generated successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating report: $e')));
      }
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 24),
            Text('Generating report...'),
          ],
        ),
      ),
    );
  }

  void _showClassSelector(BuildContext context, ReportService reportService) {
    showDialog(
      context: context,
      builder: (_) => ClassSelectorDialog(
        onSelected: (classId, sectionId) async {
          // Show sort options after selecting class/section
          _showSortOptionsDialog(
            context,
            title: 'Sort Students By',
            options: const [
              ('studentName', 'Student Name (Alphabetic)'),
              ('admissionNumber', 'Admission Number'),
              ('rollNumber', 'Roll Number'),
            ],
            onSelected: (sortBy) async {
              _showLoadingDialog(context);
              try {
                // If sectionId is null, it generates for whole class
                if (sectionId != null) {
                  await reportService.generateClassSectionList(
                    context,
                    classId,
                    sectionId,
                    sortBy: sortBy,
                  );
                } else {
                  await reportService.generateClassList(
                    context,
                    classId,
                    sortBy: sortBy,
                  );
                }
                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true).pop(); // Close loading
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report generated successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true).pop(); // Close loading
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
          );
        },
      ),
    );
  }

  void _showSortOptionsDialog(
    BuildContext context, {
    required String title,
    required List<(String value, String label)> options,
    required void Function(String sortBy) onSelected,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) {
            return ListTile(
              title: Text(option.$2),
              leading: const Icon(Icons.sort),
              onTap: () {
                Navigator.pop(context);
                onSelected(option.$1);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAdmissionReportOptions(BuildContext context, ReportService reportService) async {
    // First select date range
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
    );
    
    if (range == null || !context.mounted) return;
    
    // Then select sort option
    _showSortOptionsDialog(
      context,
      title: 'Sort Admissions By',
      options: const [
        ('admissionDate', 'Admission Date (Oldest First)'),
        ('studentName', 'Student Name (Alphabetic)'),
        ('admissionNumber', 'Admission Number'),
      ],
      onSelected: (sortBy) async {
        _showLoadingDialog(context);
        try {
          await reportService.generateAdmissionReport(
            context,
            range.start,
            range.end,
            sortBy: sortBy,
          );
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop(); // Close loading
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Report generated successfully')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop(); // Close loading
          }
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        }
      },
    );
  }

  void _showStudentSelector(BuildContext context, ReportService reportService) {
    showDialog(
      context: context,
      builder: (_) => StudentSelectorDialog(
        onSelected: (studentId) async {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Generating report...')),
            );
          }
          try {
            await reportService.generateStudentProfile(context, studentId);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          }
        },
      ),
    );
  }

  /// Show Birthday List filter options dialog
  void _showBirthdayFilterOptions(BuildContext context, ReportService reportService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cake, color: Colors.pink),
            SizedBox(width: 8),
            Text('Birthday List'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select filter option:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Today's Birthdays
            _buildBirthdayOption(
              context,
              icon: Icons.today,
              title: "Today's Birthdays",
              subtitle: 'Students celebrating birthday today',
              color: Colors.green,
              onTap: () {
                Navigator.pop(context);
                _generateReport(
                  context,
                  () => reportService.generateBirthdayList(
                    context,
                    filterType: 'today',
                  ),
                );
              },
            ),
            
            const SizedBox(height: 8),
            
            // Specific Date
            _buildBirthdayOption(
              context,
              icon: Icons.calendar_today,
              title: 'Specific Date',
              subtitle: 'Select any date to see birthdays',
              color: Colors.blue,
              onTap: () async {
                Navigator.pop(context);
                
                // Show date picker
                final selectedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  helpText: 'Select date to view birthdays',
                );
                
                if (selectedDate != null && context.mounted) {
                  _generateReport(
                    context,
                    () => reportService.generateBirthdayList(
                      context,
                      filterType: 'specific',
                      specificDate: selectedDate,
                    ),
                  );
                }
              },
            ),
            
            const SizedBox(height: 8),
            
            // Upcoming 30 Days
            _buildBirthdayOption(
              context,
              icon: Icons.calendar_month,
              title: 'Upcoming Birthdays',
              subtitle: 'Next 30 days',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                _generateReport(
                  context,
                  () => reportService.generateBirthdayList(
                    context,
                    filterType: 'upcoming',
                    upcomingDays: 30,
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Build a birthday option tile
  Widget _buildBirthdayOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
