import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:reset_flow/models/expense.dart';

/// A line chart that plots daily total spending over the given [expenses].
/// Pass [color] to tint the line for per-category screens.
class DailySpendChart extends StatelessWidget {
  final List<Expense> expenses;
  final Color color;
  final String title;

  const DailySpendChart({
    super.key,
    required this.expenses,
    this.color = const Color(0xFF5C35C2),
    this.title = 'DAILY SPENDING',
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Aggregate spending per day
    final Map<String, double> dailyTotals = {};
    for (final e in expenses) {
      final key = DateFormat('yyyy-MM-dd').format(e.date);
      dailyTotals[key] = (dailyTotals[key] ?? 0) + e.amount;
    }

    if (dailyTotals.isEmpty) return const SizedBox.shrink();

    // Sort dates
    final sortedKeys = dailyTotals.keys.toList()..sort();
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedKeys.length; i++) {
      spots.add(FlSpot(i.toDouble(), dailyTotals[sortedKeys[i]]!));
    }

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final labelColor = cs.onSurface.withOpacity(0.45);

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.fromLTRB(16, 20, 20, 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (spots.length - 1).toDouble(),
                minY: 0,
                maxY: maxY * 1.25,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? (maxY / 3) : 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: cs.outline.withOpacity(0.08),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: maxY > 0 ? (maxY / 3) : 1,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          '₹${value.toInt()}',
                          style: TextStyle(fontSize: 9, color: labelColor),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        // show label roughly every N ticks to avoid crowding
                        final step = (spots.length / 5).ceil().clamp(1, 9999);
                        if (idx % step != 0 && idx != spots.length - 1) {
                          return const SizedBox.shrink();
                        }
                        if (idx >= 0 && idx < sortedKeys.length) {
                          final d = DateTime.parse(sortedKeys[idx]);
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              DateFormat('d MMM').format(d),
                              style: TextStyle(fontSize: 9, color: labelColor),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: color,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: spots.length <= 15,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                        radius: 3,
                        color: color,
                        strokeWidth: 1.5,
                        strokeColor: cs.surface,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withOpacity(0.18),
                          color.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => cs.surface,
                    tooltipBorder: BorderSide(color: cs.outline.withOpacity(0.1)),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((s) {
                        final d = DateTime.parse(sortedKeys[s.x.toInt()]);
                        return LineTooltipItem(
                          '${DateFormat('d MMM').format(d)}\n₹${s.y.toStringAsFixed(0)}',
                          TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
