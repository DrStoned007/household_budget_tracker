import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../helpers/currency_utils.dart';

class PieChartWidget extends StatelessWidget {
  final Map<String, double> data;
  final String? centerLabel;
  final int? maxSegments; // if set and data has more entries, group remaining into 'Others'
  const PieChartWidget({super.key, required this.data, this.centerLabel, this.maxSegments});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No expenses yet.'));
    }

    final theme = Theme.of(context);
    final colors = [
      theme.colorScheme.primary,
      theme.colorScheme.error,
      theme.colorScheme.tertiary,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
    ];
    // Prepare segments with optional grouping into 'Others'
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    List<MapEntry<String, double>> segments;
    if (maxSegments != null && entries.length > maxSegments!) {
      final take = maxSegments! - 1;
      final top = entries.take(take).toList();
      final othersSum = entries.skip(take).fold<double>(0, (s, e) => s + e.value);
      segments = [...top, MapEntry('Others', othersSum)];
    } else {
      segments = entries;
    }

    final total = segments.fold<double>(0, (sum, e) => sum + e.value);
    int colorIdx = 0;

    final sections = segments.map((entry) {
      final sectionColor = colors[colorIdx % colors.length];
      colorIdx++;
      return PieChartSectionData(
        value: entry.value,
        color: sectionColor,
        title: '',
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        radius: 60,
      );
    }).toList();

    final legendItems = segments;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final isNarrow = maxW < 420;

        // Dynamically size the chart for responsiveness
        final double chartDiameter = () {
          final target = isNarrow ? maxW * 0.55 : maxW * 0.36;
          // Reserve a bit of horizontal padding within the card
          final safeWidth = (maxW - 16).clamp(0.0, double.infinity);
          double sized = target.clamp(120.0, 260.0);
          sized = sized > safeWidth ? safeWidth : sized;
          if (!isNarrow) {
            // In wide layout, ensure chart does not exceed ~45% of total width to leave space for legend
            final maxForChart = maxW * 0.45;
            if (sized > maxForChart) sized = maxForChart;
          }
          return sized;
        }();
        final double centerHole = isNarrow ? chartDiameter * 0.26 : chartDiameter * 0.28;

        final chart = Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: chartDiameter,
              height: chartDiameter,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: centerHole,
                  startDegreeOffset: -90,
                ),
              ),
            ),
            if (centerLabel != null)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(centerLabel!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                  Builder(builder: (context) {
                    final currency = getCurrencySymbol();
                    final formatted = NumberFormat.currency(symbol: currency, decimalDigits: 0).format(total);
                    return Text(
                      formatted,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    );
                  }),
                ],
              ),
          ],
        );

        final legendWrap = LayoutBuilder(
      builder: (context, c) {
        // Determine how many columns of legend chips to show based on width
        final canFitTwo = c.maxWidth > 340;
        final children = List.generate(legendItems.length, (index) {
          final entry = legendItems[index];
          final percent = total > 0 ? (entry.value / total * 100) : 0;
              final sectionColor = entry.key == 'Others'
                  ? theme.colorScheme.outline
                  : colors[index % colors.length];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: sectionColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: sectionColor, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${entry.key}: ${percent.toStringAsFixed(1)}%',
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        });
        if (canFitTwo) {
          // Use Grid for better packing with many legends
          return GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 5,
            children: children,
          );
        }
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: children,
        );
      },
    );

        // Constrain legend to avoid overflow; allow scroll if content is long
        final legend = ConstrainedBox(
          constraints: BoxConstraints(
            // Allow more space for long legends; in narrow mode, limit height to avoid overflow
            maxHeight: isNarrow ? chartDiameter * 1.2 : chartDiameter * 1.5,
            // Prevent over-wide legend blocks; they will wrap
            maxWidth: isNarrow ? maxW : maxW - chartDiameter - 24,
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: legendWrap,
          ),
        );

        final content = isNarrow
            ? (constraints.hasBoundedHeight
                ? Column(
                    children: [
                      chart,
                      const SizedBox(height: 8),
                      Expanded(child: legend),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [chart, const SizedBox(height: 12), legend],
                  ))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [chart, const SizedBox(width: 24), Expanded(child: legend)],
              );

        // Add inner padding to prevent the chart from touching card edges
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: content,
        );
      },
    );
  }
}
