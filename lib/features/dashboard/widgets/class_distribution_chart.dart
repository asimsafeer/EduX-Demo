/// EduX School Management System
/// Class Distribution Pie Chart Widget
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/core.dart';
import '../../../providers/dashboard_provider.dart';

/// Pie chart showing student distribution by class
class ClassDistributionChart extends StatefulWidget {
  final List<ChartDataPoint> data;

  const ClassDistributionChart({super.key, required this.data});

  @override
  State<ClassDistributionChart> createState() => _ClassDistributionChartState();
}

class _ClassDistributionChartState extends State<ClassDistributionChart> {
  int touchedIndex = -1;

  static const List<Color> _colors = [
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Green
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFF8B5CF6), // Purple
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF97316), // Orange
    Color(0xFF84CC16), // Lime
    Color(0xFFEC4899), // Pink
    Color(0xFF14B8A6), // Teal
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const _EmptyChartState(
        icon: LucideIcons.pieChart,
        message: 'No class distribution data',
      );
    }

    final total = widget.data.map((e) => e.value).reduce((a, b) => a + b);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Check if we have enough height for a column layout
          final hasHeightForColumn = constraints.maxHeight > 300;
          final isNarrow = constraints.maxWidth < 350;

          // Use column layout only if narrow AND we have vertical space
          if (isNarrow && hasHeightForColumn) {
            return Column(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildPieChart(total),
                ),
                const SizedBox(height: 16),
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    child: _buildLegend(total),
                  ),
                ),
              ],
            );
          }

          // Default to Row layout (better for fixed height cards like in Dashboard)
          return Row(
            children: [
              Expanded(
                flex: 4,
                child: _buildPieChart(total),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 6,
                child: SingleChildScrollView(
                  child: _buildLegend(total),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPieChart(double total) {
    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  pieTouchResponse == null ||
                  pieTouchResponse.touchedSection == null) {
                touchedIndex = -1;
                return;
              }
              touchedIndex =
                  pieTouchResponse.touchedSection!.touchedSectionIndex;
            });
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 3,
        centerSpaceRadius: 25,
        sections: _buildSections(total),
      ),
    );
  }

  Widget _buildLegend(double total) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.data.asMap().entries.map((entry) {
        final color = _colors[entry.key % _colors.length];
        final percentage =
            (entry.value.value / total * 100).toStringAsFixed(0);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
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
              Expanded(
                child: Text(
                  entry.value.label,
                  style: AppTextStyles.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$percentage%',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<PieChartSectionData> _buildSections(double total) {
    return widget.data.asMap().entries.map((entry) {
      final isTouched = entry.key == touchedIndex;
      final fontSize = isTouched ? 14.0 : 11.0;
      final radius = isTouched ? 28.0 : 22.0;
      final color = _colors[entry.key % _colors.length];
      final percentage = (entry.value.value / total * 100).toStringAsFixed(0);

      return PieChartSectionData(
        color: color,
        value: entry.value.value,
        title: isTouched ? entry.value.label : '${entry.value.value.toInt()}',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          color: Colors.white,
          shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
        ),
        showTitle: isTouched || (entry.value.value / total * 100) >= 12,
        titlePositionPercentageOffset: 0.55,
        badgeWidget: isTouched
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 2,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '$percentage%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        badgePositionPercentageOffset: 1.2,
      );
    }).toList();
  }
}

/// Empty chart state widget
class _EmptyChartState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyChartState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
