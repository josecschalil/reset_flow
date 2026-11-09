import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:reset_flow/models/expense.dart';

/// A line chart that plots daily total spending over the given [expenses].
/// Defaults to the Ink Navy brand theme matching the Finance & Cash Requirements screens.
class DailySpendChart extends StatelessWidget {
  final List<Expense> expenses;
  final Color color;
  final String title;

  const DailySpendChart({
    super.key,
    required this.expenses,
    this.color = const Color(0xFF1E3A5F), // Ink Navy brand accent
    this.title = 'DAILY SPENDING',
  });

  // ── Palette Tokens: Clean white surfaces + Ink Navy & Slate Accents ──
  static const Color _border = Color(0xFFDFE3E9);
  static const Color _gridLine = Color(0xFFF1F5F9);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _textSubtle = Color(0xFF8892A0);

  static const List<BoxShadow> _cardShadow = [
    BoxShadow(
      color: Color(0x0A14202E),
      blurRadius: 14,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x0614202E),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Aggregate spending per day
    final Map<String, double> dailyTotals = {};
    for (final e in expenses) {
      final key = DateFormat('yyyy-MM-dd').format(e.date);
      dailyTotals[key] = (dailyTotals[key] ?? 0.0) + e.amount;
    }

    if (dailyTotals.isEmpty) return const SizedBox.shrink();

    // Sort dates
    final sortedKeys = dailyTotals.keys.toList()..sort();
    final spots = <FlSpot>[];
    double totalSpent = 0.0;
    for (int i = 0; i < sortedKeys.length; i++) {
      final amt = dailyTotals[sortedKeys[i]]!;
      spots.add(FlSpot(i.toDouble(), amt));
      totalSpent += amt;
    }

    final avgDaily =
        sortedKeys.isNotEmpty ? totalSpent / sortedKeys.length : 0.0;
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.fromLTRB(18, 18, 20, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.show_chart_rounded,
                        size: 13,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: _textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _border),
                ),
                child: Text(
                  'Avg ₹${avgDaily.toStringAsFixed(0)} / day',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
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
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: _gridLine,
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
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: _textSubtle,
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        final step =
                            (spots.length / 5).ceil().clamp(1, 9999);
                        if (idx % step != 0 && idx != spots.length - 1) {
                          return const SizedBox.shrink();
                        }
                        if (idx >= 0 && idx < sortedKeys.length) {
                          final d = DateTime.parse(sortedKeys[idx]);
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              DateFormat('d MMM').format(d),
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: _textSubtle,
                              ),
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
                        radius: 3.5,
                        color: color,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withValues(alpha: 0.16),
                          color.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => Colors.white,
                    tooltipBorder: const BorderSide(color: _border),
                    tooltipRoundedRadius: 10,
                    tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((s) {
                        final d = DateTime.parse(sortedKeys[s.x.toInt()]);
                        return LineTooltipItem(
                          '${DateFormat('d MMM').format(d)}\n',
                          const TextStyle(
                            color: _textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            TextSpan(
                              text: '₹${s.y.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
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
