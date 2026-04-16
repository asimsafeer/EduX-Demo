/// EduX School Management System
/// Attendance Chart Widget
library;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../repositories/attendance_repository.dart';

/// Pie chart widget for attendance distribution
class AttendancePieChart extends StatelessWidget {
  final AttendanceStats stats;
  final double radius;
  final bool showLabels;

  const AttendancePieChart({
    super.key,
    required this.stats,
    this.radius = 80,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = stats.totalDays;

    if (total == 0) {
      return Center(
        child: Text(
          'No data available',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: radius * 0.4,
              sections: [
                _buildSection(stats.presentDays, Colors.green.shade600, 'P'),
                _buildSection(stats.absentDays, Colors.red.shade600, 'A'),
                _buildSection(stats.lateDays, Colors.orange.shade600, 'L'),
                _buildSection(stats.leaveDays, Colors.blue.shade600, 'LV'),
              ],
            ),
          ),
        ),
        if (showLabels) ...[
          const SizedBox(width: 24),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegend('Present', stats.presentDays, Colors.green.shade600),
              const SizedBox(height: 8),
              _buildLegend('Absent', stats.absentDays, Colors.red.shade600),
              const SizedBox(height: 8),
              _buildLegend('Late', stats.lateDays, Colors.orange.shade600),
              const SizedBox(height: 8),
              _buildLegend('Leave', stats.leaveDays, Colors.blue.shade600),
            ],
          ),
        ],
      ],
    );
  }

  PieChartSectionData _buildSection(int value, Color color, String label) {
    if (value == 0) {
      return PieChartSectionData(
        value: 0,
        color: Colors.transparent,
        showTitle: false,
        radius: radius * 0.6,
      );
    }

    return PieChartSectionData(
      value: value.toDouble(),
      color: color,
      title: label,
      titleStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      radius: radius * 0.6,
    );
  }

  Widget _buildLegend(String label, int value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text('$label: $value'),
      ],
    );
  }
}

/// Bar chart for weekly/monthly trends
class AttendanceTrendChart extends StatelessWidget {
  final List<({String label, double percentage})> data;
  final String title;
  final double height;

  const AttendanceTrendChart({
    super.key,
    required this.data,
    this.title = 'Attendance Trend',
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'No data available',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: height,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 100,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${data[groupIndex].percentage.toStringAsFixed(1)}%',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < data.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            data[index].label,
                            style: theme.textTheme.bodySmall,
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}%',
                        style: theme.textTheme.bodySmall,
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 25,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: data.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: item.percentage,
                      width: 20,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                      color: _getBarColor(item.percentage),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Color _getBarColor(double percentage) {
    if (percentage >= 90) return Colors.green.shade600;
    if (percentage >= 75) return Colors.lightGreen.shade600;
    if (percentage >= 60) return Colors.orange.shade600;
    return Colors.red.shade600;
  }
}
