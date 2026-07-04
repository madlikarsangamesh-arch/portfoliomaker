import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:portfolio_ai/config/theme.dart';

class AnalyticsSummaryChart extends StatelessWidget {
  final Map<String, int> data;
  final bool isPieChart;

  const AnalyticsSummaryChart({
    Key? key,
    required this.data,
    this.isPieChart = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No analytics recorded yet.',
          style: TextStyle(color: Colors.white38),
        ),
      );
    }

    if (isPieChart) {
      return _buildPieChart(context);
    }
    
    return _buildBarChart(context);
  }

  Widget _buildPieChart(BuildContext context) {
    final list = data.entries.toList();
    final colors = [
      AppTheme.neonCyan,
      AppTheme.neonPurple,
      AppTheme.electricPink,
      Colors.amberAccent,
      Colors.blueAccent,
    ];

    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 40,
        sections: List.generate(list.length, (index) {
          final entry = list[index];
          final color = colors[index % colors.length];
          return PieChartSectionData(
            color: color,
            value: entry.value.toDouble(),
            title: '${entry.key}\n(${entry.value})',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBarChart(BuildContext context) {
    final list = data.entries.toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: data.values.fold<int>(0, (max, v) => v > max ? v : max).toDouble() + 2,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < list.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      list[index].key,
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(list.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: list[index].value.toDouble(),
                gradient: AppTheme.primaryGradient,
                width: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      ),
    );
  }
}
