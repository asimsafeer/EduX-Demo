/// EduX School Management System
/// Profit vs Loss Line Chart Widget
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/core.dart';
import '../../../providers/dashboard_provider.dart';

/// Line chart showing monthly profit (income) vs loss (expense)
class ProfitLossChart extends StatelessWidget {
  final List<ProfitLossDataPoint> data;

  const ProfitLossChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const _EmptyChartState(
        icon: LucideIcons.lineChart,
        message: 'No financial data available',
      );
    }

    // Calculate Net Profit for each point
    final List<FlSpot> spots = [];
    double minYValue = 0;
    double maxYValue = 0;

    for (int i = 0; i < data.length; i++) {
      final netBalance = data[i].income - data[i].expense;
      spots.add(FlSpot(i.toDouble(), netBalance));

      if (netBalance < minYValue) minYValue = netBalance;
      if (netBalance > maxYValue) maxYValue = netBalance;
    }

    // Ensure some range even if data is flat
    if (minYValue == maxYValue) {
      minYValue -= 1000;
      maxYValue += 1000;
    }

    // Add padding to Y range
    final yRange = maxYValue - minYValue;
    final chartMinY = minYValue - (yRange * 0.1);
    final chartMaxY = maxYValue + (yRange * 0.2);
    final interval = (chartMaxY - chartMinY) / 5;

    return Padding(
      padding: const EdgeInsets.only(right: 24, left: 0, top: 16, bottom: 8),
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.surface,
              tooltipRoundedRadius: 8,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  final value = touchedSpot.y;
                  final formatted = NumberFormat.currency(
                    symbol: 'Rs. ',
                    decimalDigits: 0,
                  ).format(value);
                  final date = data[touchedSpot.x.toInt()].label;

                  return LineTooltipItem(
                    '$date\n$formatted',
                    AppTextStyles.labelMedium.copyWith(
                      color: value >= 0 ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval > 0 ? interval : 1000,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppColors.divider.withValues(alpha: 0.5),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 5, // Show label every 5 days to avoid collision
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < data.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        data[index].label,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: interval > 0 ? interval : 1000,
                reservedSize: 45,
                getTitlesWidget: (value, meta) {
                  return Text(
                    NumberFormat.compact().format(value),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: chartMinY,
          maxY: chartMaxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              preventCurveOverShooting: true,
              curveSmoothness: 0.35,
              color: AppColors.primary,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.25),
                    AppColors.primary.withValues(alpha: 0.05),
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
