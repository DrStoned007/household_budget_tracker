import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PieChartWidget extends StatelessWidget {
  final Map<String, double> data;
  const PieChartWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No expenses yet.'));
    }
    final colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal];
    final total = data.values.fold<double>(0, (sum, v) => sum + v);
    int colorIdx = 0;
    final sections = data.entries.map((entry) {
      final sectionColor = colors[colorIdx % colors.length];
      colorIdx++;
      return PieChartSectionData(
        value: entry.value,
        color: sectionColor,
        title: '', // No label inside the chart
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        radius: 60,
        titlePositionPercentageOffset: 0.7,
      );
    }).toList();

    // Build legend with percentage outside the chart
    final legend = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.entries.map((entry) {
        final percent = total > 0 ? (entry.value / total * 100) : 0;
        final sectionColor = colors[data.keys.toList().indexOf(entry.key) % colors.length];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(width: 12, height: 12, color: sectionColor, margin: const EdgeInsets.only(right: 8)),
              Text('${entry.key}: ', style: const TextStyle(fontSize: 14)),
              Text('${percent.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }).toList(),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              startDegreeOffset: -90,
            ),
          ),
        ),
        const SizedBox(width: 24),
        legend,
      ],
    );
  }
}
