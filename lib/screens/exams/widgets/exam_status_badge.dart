/// EduX School Management System
/// Exam Status Badge Widget
library;

import 'package:flutter/material.dart';
import '../../../core/theme/theme.dart';

class ExamStatusBadge extends StatelessWidget {
  final String status;
  final bool showIcon;

  const ExamStatusBadge({
    super.key,
    required this.status,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = _getStatusInfo(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  (Color, IconData, String) _getStatusInfo(String status) {
    switch (status) {
      case 'draft':
        return (AppColors.warning, Icons.edit_outlined, 'Draft');
      case 'active':
        return (AppColors.primary, Icons.play_circle_outline, 'Active');
      case 'completed':
        return (AppColors.success, Icons.check_circle_outline, 'Completed');
      default:
        return (AppColors.textSecondary, Icons.help_outline, status);
    }
  }
}

class GradeBadge extends StatelessWidget {
  final String grade;
  final bool showGpa;
  final double? gpa;

  const GradeBadge({
    super.key,
    required this.grade,
    this.showGpa = false,
    this.gpa,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getGradeColor(grade);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            grade,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (showGpa && gpa != null) ...[
            const SizedBox(height: 2),
            Text(
              'GPA: ${gpa!.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'A+':
      case 'A':
        return AppColors.success;
      case 'A-':
      case 'B+':
      case 'B':
        return AppColors.primary;
      case 'B-':
      case 'C+':
      case 'C':
        return AppColors.info;
      case 'C-':
      case 'D+':
      case 'D':
        return AppColors.warning;
      case 'F':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}

class PassFailBadge extends StatelessWidget {
  final bool isPassed;

  const PassFailBadge({super.key, required this.isPassed});

  @override
  Widget build(BuildContext context) {
    final color = isPassed ? AppColors.success : AppColors.error;
    final label = isPassed ? 'Passed' : 'Failed';
    final icon = isPassed ? Icons.check_circle : Icons.cancel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class RankBadge extends StatelessWidget {
  final int rank;
  final int totalStudents;

  const RankBadge({super.key, required this.rank, required this.totalStudents});

  @override
  Widget build(BuildContext context) {
    final isTop3 = rank <= 3;
    final (color, icon) = _getRankInfo(rank);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: isTop3
            ? LinearGradient(
                colors: [
                  color.withValues(alpha: 0.25),
                  color.withValues(alpha: 0.1),
                ],
              )
            : null,
        color: isTop3 ? null : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: isTop3 ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isTop3) ...[
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            _getOrdinal(rank),
            style: TextStyle(
              fontSize: 14,
              fontWeight: isTop3 ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
          Text(
            ' / $totalStudents',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  (Color, IconData) _getRankInfo(int rank) {
    switch (rank) {
      case 1:
        return (const Color(0xFFFFD700), Icons.emoji_events); // Gold
      case 2:
        return (const Color(0xFFC0C0C0), Icons.emoji_events); // Silver
      case 3:
        return (const Color(0xFFCD7F32), Icons.emoji_events); // Bronze
      default:
        return (AppColors.textSecondary, Icons.leaderboard);
    }
  }

  String _getOrdinal(int number) {
    if (number >= 11 && number <= 13) {
      return '${number}th';
    }
    switch (number % 10) {
      case 1:
        return '${number}st';
      case 2:
        return '${number}nd';
      case 3:
        return '${number}rd';
      default:
        return '${number}th';
    }
  }
}
