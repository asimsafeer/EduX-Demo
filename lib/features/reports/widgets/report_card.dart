/// EduX School Management System
/// Report Card Widget - Clickable report item
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/core.dart';

/// Report item configuration
class ReportItem {
  final String title;
  final String description;
  final IconData icon;
  final List<String> exportFormats;
  final VoidCallback onGenerate;

  const ReportItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.exportFormats,
    required this.onGenerate,
  });
}

/// Report card widget
class ReportCard extends StatelessWidget {
  final ReportItem report;

  const ReportCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: report.onGenerate,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(report.icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report.title, style: AppTextStyles.labelLarge),
                    const SizedBox(height: 4),
                    Text(
                      report.description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: report.exportFormats.map((format) {
                        return _FormatChip(format: format);
                      }).toList(),
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormatChip extends StatelessWidget {
  final String format;

  const _FormatChip({required this.format});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _getFormatStyle(format);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            format.toUpperCase(),
            style: AppTextStyles.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  (Color, IconData) _getFormatStyle(String format) {
    return switch (format.toLowerCase()) {
      'pdf' => (AppColors.error, LucideIcons.fileText),
      'excel' || 'xlsx' => (AppColors.success, LucideIcons.fileSpreadsheet),
      'csv' => (AppColors.info, LucideIcons.fileCode),
      _ => (AppColors.textSecondary, LucideIcons.file),
    };
  }
}

/// Grid of report cards
class ReportGrid extends StatelessWidget {
  final List<ReportItem> reports;
  final String searchQuery;

  const ReportGrid({super.key, required this.reports, this.searchQuery = ''});

  @override
  Widget build(BuildContext context) {
    final filtered = searchQuery.isEmpty
        ? reports
        : reports.where((r) {
            final q = searchQuery.toLowerCase();
            return r.title.toLowerCase().contains(q) ||
                r.description.toLowerCase().contains(q);
          }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No matching reports found',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.5,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) => ReportCard(report: filtered[index]),
    );
  }
}
