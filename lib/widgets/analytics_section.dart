import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:reset_flow/providers/goal_provider.dart';
import 'package:reset_flow/models/daily_log.dart';
import 'package:reset_flow/models/goal.dart';
import 'package:reset_flow/utils/streak_calculator.dart';

// ---------------------------------------------------------------------------
// Root Analytics Section — embedded on HomeScreen above MomentumRoulette
// ---------------------------------------------------------------------------
class AnalyticsSection extends ConsumerStatefulWidget {
  const AnalyticsSection({super.key});

  @override
  ConsumerState<AnalyticsSection> createState() => _AnalyticsSectionState();
}

class _AnalyticsSectionState extends ConsumerState<AnalyticsSection> {
  int _selectedDays = 30; // 7, 30, -1 = all

  @override
  Widget build(BuildContext context) {
    final goalState = ref.watch(goalProvider);
    final allLogs = goalState.allLogs;
    final goals = goalState.goals;

    // When there is no history, only show an empty state instead of crashing.
    final hasAnyLogs = allLogs.any((l) => l.status != 'pending');
    if (goals.isEmpty && !hasAnyLogs) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final formatter = DateFormat('yyyy-MM-dd');
    final today = DateTime.now();

    // ── Compute window ──────────────────────────────────────
    final int dayCount = _computeDayCount(allLogs, today);

    // ── Per-day success rates (for chart) ───────────────────
    final List<_DayRate> dailyRates = _buildDailyRates(
        allLogs, today, dayCount, formatter);

    // ── Day-of-week averages ─────────────────────────────────
    final dowRates = _buildDowRates(allLogs, formatter);

    // ── History entries (all unique dates with logs) ─────────
    final historyDays = _buildHistoryDays(allLogs, goals, formatter);

    // ── Overall stats ────────────────────────────────────────
    final totalCompleted =
        allLogs.where((l) => l.status == 'completed').length;
    final totalResolved =
        allLogs.where((l) => l.status != 'pending').length;
    final overallPct =
        totalResolved == 0 ? 0.0 : (totalCompleted / totalResolved) * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ──
        _SectionHeader(
          overallPct: overallPct,
          selectedDays: _selectedDays,
          onPeriodChanged: (v) => setState(() => _selectedDays = v),
        ),

        const SizedBox(height: 16),

        // ── Performance chart ──
        _PerformanceChart(
            dailyRates: dailyRates, colorScheme: colorScheme),

        const SizedBox(height: 16),

        // ── Day-of-week heatmap ──
        _DowHeatmap(dowRates: dowRates, colorScheme: colorScheme),

        const SizedBox(height: 16),

        // ── Per-goal breakdown (only for recurring / multi-day goals) ──
        if (goals.isNotEmpty)
          _GoalBreakdown(
              goals: goals, allLogs: allLogs, colorScheme: colorScheme),

        if (goals.isNotEmpty) const SizedBox(height: 16),

        // ── Day-by-day history (key feature: every day is unique!) ──
        _DayHistory(historyDays: historyDays, colorScheme: colorScheme),

        const SizedBox(height: 8),
      ],
    );
  }

  int _computeDayCount(List<DailyLog> logs, DateTime today) {
    if (_selectedDays != -1) return _selectedDays;
    if (logs.isEmpty) return 30;
    final formatter = DateFormat('yyyy-MM-dd');
    try {
      final earliest = logs
          .map((l) => l.date)
          .reduce((a, b) => a.compareTo(b) < 0 ? a : b);
      return today.difference(formatter.parse(earliest)).inDays + 1;
    } catch (_) {
      return 30;
    }
  }

  List<_DayRate> _buildDailyRates(List<DailyLog> logs, DateTime today,
      int dayCount, DateFormat fmt) {
    final rates = <_DayRate>[];
    for (int i = dayCount - 1; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final dayStr = fmt.format(day);
      final dayLogs = logs.where((l) => l.date == dayStr).toList();
      if (dayLogs.isEmpty) {
        rates.add(_DayRate(day: day, rate: null));
      } else {
        final completed =
            dayLogs.where((l) => l.status == 'completed').length;
        rates.add(
            _DayRate(day: day, rate: (completed / dayLogs.length) * 100));
      }
    }
    return rates;
  }

  List<double> _buildDowRates(List<DailyLog> logs, DateFormat fmt) {
    final totals = List.filled(7, 0.0);
    final counts = List.filled(7, 0);
    for (final log in logs) {
      try {
        final date = fmt.parse(log.date);
        final wd = date.weekday - 1;
        if (log.status == 'completed') totals[wd] += 1;
        if (log.status != 'pending') counts[wd] += 1;
      } catch (_) {}
    }
    return List.generate(
        7, (i) => counts[i] == 0 ? 0 : (totals[i] / counts[i]) * 100);
  }

  List<_HistoryDay> _buildHistoryDays(
      List<DailyLog> logs, List<Goal> goals, DateFormat fmt) {
    // Group logs by date
    final Map<String, List<DailyLog>> byDate = {};
    for (final log in logs) {
      byDate.putIfAbsent(log.date, () => []).add(log);
    }

    // Sort dates descending (newest first)
    final sortedDates = byDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return sortedDates.map((dateStr) {
      final dayLogs = byDate[dateStr]!;
      final entries = dayLogs.map((log) {
        final goal = goals.firstWhere(
          (g) => g.id == log.goalId,
          orElse: () => Goal(
            id: '',
            title: 'Deleted goal',
            isActionBased: true,
            activeDays: [],
            createdAt: DateTime.now(),
          ),
        );
        return _HistoryEntry(
          goalTitle: goal.title,
          isOneTime: goal.isOneTime,
          isActionBased: goal.isActionBased,
          status: log.status,
        );
      }).toList();

      final completed =
          dayLogs.where((l) => l.status == 'completed').length;
      final total = dayLogs.length;
      final rate = total == 0 ? 0.0 : completed / total;

      return _HistoryDay(
        dateStr: dateStr,
        entries: entries,
        completedCount: completed,
        totalCount: total,
        rate: rate,
      );
    }).toList();
  }
}

// ---------------------------------------------------------------------------
// Section header with period selector
// ---------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  final double overallPct;
  final int selectedDays;
  final ValueChanged<int> onPeriodChanged;

  const _SectionHeader({
    required this.overallPct,
    required this.selectedDays,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ANALYTICS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: colorScheme.onSurface.withOpacity(0.45),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${overallPct.toStringAsFixed(1)}% all-time',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        _PeriodSelector(
            selected: selectedDays, onChanged: onPeriodChanged),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Period Selector chips
// ---------------------------------------------------------------------------
class _PeriodSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _PeriodSelector(
      {required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const options = [
      (label: '7d', value: 7),
      (label: '30d', value: 30),
      (label: 'All', value: -1),
    ];
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final isSelected = selected == opt.value;
          return GestureDetector(
            onTap: () => onChanged(opt.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                opt.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Performance Line Chart
// ---------------------------------------------------------------------------
class _PerformanceChart extends StatelessWidget {
  final List<_DayRate> dailyRates;
  final ColorScheme colorScheme;

  const _PerformanceChart(
      {required this.dailyRates, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final hasSomeData = dailyRates.any((d) => d.rate != null);

    return Container(
      decoration: _cardDecoration(colorScheme),
      padding: const EdgeInsets.fromLTRB(16, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('DAILY SUCCESS RATE', colorScheme),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: !hasSomeData
                ? Center(
                    child: Text(
                      'No data yet — keep logging!',
                      style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.4),
                          fontSize: 13),
                    ),
                  )
                : _buildLineChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    final spots = <FlSpot>[];
    for (int i = 0; i < dailyRates.length; i++) {
      if (dailyRates[i].rate != null) {
        spots.add(FlSpot(i.toDouble(), dailyRates[i].rate!));
      }
    }

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (val) => FlLine(
            color: colorScheme.outline.withOpacity(0.08),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 50,
              reservedSize: 28,
              getTitlesWidget: (val, meta) {
                if (val == 0 || val == 50 || val == 100) {
                  return Text(
                    '${val.toInt()}%',
                    style: TextStyle(
                        fontSize: 9,
                        color: colorScheme.onSurface.withOpacity(0.4)),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: _labelInterval(dailyRates.length.toDouble()),
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx < 0 || idx >= dailyRates.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('d/M').format(dailyRates[idx].day),
                    style: TextStyle(
                        fontSize: 8,
                        color: colorScheme.onSurface.withOpacity(0.4)),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: colorScheme.primary,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: spots.length <= 10,
              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                radius: 3,
                color: colorScheme.primary,
                strokeWidth: 1,
                strokeColor: colorScheme.surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.primary.withOpacity(0.18),
                  colorScheme.primary.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      '${s.y.toInt()}%',
                      TextStyle(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }

  double _labelInterval(double count) {
    if (count <= 10) return 1;
    if (count <= 30) return 5;
    return 10;
  }
}

// ---------------------------------------------------------------------------
// Day-of-Week Heatmap
// ---------------------------------------------------------------------------
class _DowHeatmap extends StatelessWidget {
  final List<double> dowRates;
  final ColorScheme colorScheme;

  const _DowHeatmap(
      {required this.dowRates, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxRate = dowRates.reduce((a, b) => a > b ? a : b);
    final bestIdx = maxRate > 0 ? dowRates.indexOf(maxRate) : -1;

    return Container(
      decoration: _cardDecoration(colorScheme),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('BEST DAYS OF WEEK', colorScheme),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final rate = dowRates[i];
              final isBest = i == bestIdx;
              final barColor = isBest
                  ? colorScheme.primary
                  : colorScheme.primary.withOpacity(0.3);
              final barHeight =
                  rate == 0 ? 4.0 : (rate / 100) * 64 + 4;
              return Column(
                children: [
                  if (isBest)
                    Text(
                      '${rate.toInt()}%',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary),
                    )
                  else
                    const SizedBox(height: 14),
                  const SizedBox(height: 2),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    width: 28,
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    days[i],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isBest ? FontWeight.bold : FontWeight.normal,
                      color: isBest
                          ? colorScheme.primary
                          : colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Per-Goal Breakdown (for recurring goals)
// ---------------------------------------------------------------------------
class _GoalBreakdown extends StatelessWidget {
  final List<Goal> goals;
  final List<DailyLog> allLogs;
  final ColorScheme colorScheme;

  const _GoalBreakdown({
    required this.goals,
    required this.allLogs,
    required this.colorScheme,
  });

  static const _colors = [
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFFE65100),
    Color(0xFF6A1B9A),
    Color(0xFF00838F),
    Color(0xFFC62828),
  ];

  @override
  Widget build(BuildContext context) {
    // Filter to goals that have resolved logs (avoid empty list items)
    final activeGoals = goals.where((g) {
      final gl = allLogs.where((l) => l.goalId == g.id).toList();
      return gl.any((l) => l.status != 'pending');
    }).toList();

    if (activeGoals.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: _cardDecoration(colorScheme),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('GOAL BREAKDOWN', colorScheme),
          const SizedBox(height: 16),
          ...activeGoals.asMap().entries.map((entry) {
            final idx = entry.key;
            final goal = entry.value;
            final goalLogs =
                allLogs.where((l) => l.goalId == goal.id).toList();
            final resolved =
                goalLogs.where((l) => l.status != 'pending').length;
            final completed =
                goalLogs.where((l) => l.status == 'completed').length;
            final rate = resolved == 0 ? 0.0 : completed / resolved;
            final streak = StreakCalculator.calculateCurrentStreak(
                goal, goalLogs);
            final color = _colors[idx % _colors.length];

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    goal.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    goal.isOneTime
                                        ? 'One-time'
                                        : 'Recurring',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: colorScheme.onSurface
                                          .withOpacity(0.45),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          if (streak > 0) ...[
                            Icon(Icons.local_fire_department,
                                size: 12,
                                color: colorScheme.primary
                                    .withOpacity(0.8)),
                            const SizedBox(width: 2),
                            Text(
                              '$streak',
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            '${(rate * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _rateColor(rate),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: rate,
                      minHeight: 5,
                      backgroundColor: color.withOpacity(0.12),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$completed completed · $resolved logged',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _rateColor(double r) {
    if (r >= 0.8) return const Color(0xFF2E7D32);
    if (r >= 0.5) return const Color(0xFFE65100);
    return const Color(0xFFC62828);
  }
}

// ---------------------------------------------------------------------------
// Day-by-Day History  ← KEY for daily-variable goals
// Each expanded row shows the specific goals that were active on that day
// and whether each was completed, failed, or pending.
// ---------------------------------------------------------------------------
class _DayHistory extends StatefulWidget {
  final List<_HistoryDay> historyDays;
  final ColorScheme colorScheme;

  const _DayHistory(
      {required this.historyDays, required this.colorScheme});

  @override
  State<_DayHistory> createState() => _DayHistoryState();
}

class _DayHistoryState extends State<_DayHistory> {
  // Which days are expanded
  final Set<String> _expanded = {};
  // How many days to show
  int _visibleCount = 10;

  @override
  Widget build(BuildContext context) {
    final colorScheme = widget.colorScheme;
    final days = widget.historyDays;

    if (days.isEmpty) return const SizedBox.shrink();

    final visible = days.take(_visibleCount).toList();

    return Container(
      decoration: _cardDecoration(colorScheme),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _label('DAILY HISTORY', colorScheme),
              Text(
                '${days.length} days logged',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Day rows
          ...visible.map((day) {
            final isExpanded = _expanded.contains(day.dateStr);
            return _DayRow(
              day: day,
              isExpanded: isExpanded,
              colorScheme: colorScheme,
              onTap: () => setState(() {
                if (isExpanded) {
                  _expanded.remove(day.dateStr);
                } else {
                  _expanded.add(day.dateStr);
                }
              }),
            );
          }),

          // Load more
          if (_visibleCount < days.length)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: GestureDetector(
                onTap: () =>
                    setState(() => _visibleCount += 10),
                child: Center(
                  child: Text(
                    'Show more (${days.length - _visibleCount} remaining)',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
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

class _DayRow extends StatelessWidget {
  final _HistoryDay day;
  final bool isExpanded;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _DayRow({
    required this.day,
    required this.isExpanded,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateObj =
        DateFormat('yyyy-MM-dd').parse(day.dateStr);
    final isToday = day.dateStr ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    final completedColor = _successColor(day.rate);

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                vertical: 8, horizontal: 4),
            child: Row(
              children: [
                // Date column
                SizedBox(
                  width: 52,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('d MMM').format(dateObj),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isToday
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        DateFormat('EEE').format(dateObj),
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurface
                              .withOpacity(0.45),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Progress mini-bar
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: day.rate,
                          minHeight: 6,
                          backgroundColor: colorScheme
                              .surfaceVariant
                              .withOpacity(0.4),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(
                                  completedColor),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${day.completedCount}/${day.totalCount} goals',
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurface
                              .withOpacity(0.45),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Rate badge
                Container(
                  width: 40,
                  alignment: Alignment.center,
                  child: Text(
                    '${(day.rate * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: completedColor,
                    ),
                  ),
                ),

                // Chevron
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color:
                        colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Detail rows (expanded)
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(
                      left: 8, bottom: 8),
                  child: Column(
                    children:
                        day.entries.map((entry) {
                      return _GoalEntryRow(
                          entry: entry,
                          colorScheme: colorScheme);
                    }).toList(),
                  ),
                )
              : const SizedBox.shrink(),
        ),

        Divider(
          height: 1,
          color: colorScheme.outline.withOpacity(0.08),
        ),
      ],
    );
  }

  Color _successColor(double rate) {
    if (rate >= 0.8) return const Color(0xFF2E7D32);
    if (rate >= 0.5) return const Color(0xFFE65100);
    if (rate > 0) return const Color(0xFFC62828);
    return const Color(0xFFB0B0B0);
  }
}

class _GoalEntryRow extends StatelessWidget {
  final _HistoryEntry entry;
  final ColorScheme colorScheme;

  const _GoalEntryRow(
      {required this.entry, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final isCompleted = entry.status == 'completed';
    final isFailed = entry.status == 'failed';

    Color statusColor;
    IconData statusIcon;
    if (isCompleted) {
      statusColor = const Color(0xFF2E7D32);
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (isFailed) {
      statusColor = const Color(0xFFC62828);
      statusIcon = Icons.cancel_outlined;
    } else {
      statusColor = colorScheme.onSurface.withOpacity(0.3);
      statusIcon = Icons.radio_button_unchecked;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(statusIcon, size: 15, color: statusColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.goalTitle,
              style: TextStyle(
                fontSize: 12,
                color: isCompleted
                    ? colorScheme.onSurface.withOpacity(0.7)
                    : isFailed
                        ? const Color(0xFFC62828)
                        : colorScheme.onSurface
                            .withOpacity(0.4),
                decoration: isCompleted
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ),
          // Tags
          if (entry.isOneTime)
            _tag('one-time',
                colorScheme.tertiary.withOpacity(0.8))
          else
            _tag(
                entry.isActionBased ? 'do' : 'avoid',
                entry.isActionBased
                    ? colorScheme.primary.withOpacity(0.7)
                    : colorScheme.error.withOpacity(0.7)),
        ],
      ),
    );
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 9, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
BoxDecoration _cardDecoration(ColorScheme cs) => BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: cs.outline.withOpacity(0.1)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );

Widget _label(String text, ColorScheme cs) => Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: cs.onSurface.withOpacity(0.45),
      ),
    );

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------
class _DayRate {
  final DateTime day;
  final double? rate;
  const _DayRate({required this.day, required this.rate});
}

class _HistoryDay {
  final String dateStr;
  final List<_HistoryEntry> entries;
  final int completedCount;
  final int totalCount;
  final double rate;

  const _HistoryDay({
    required this.dateStr,
    required this.entries,
    required this.completedCount,
    required this.totalCount,
    required this.rate,
  });
}

class _HistoryEntry {
  final String goalTitle;
  final bool isOneTime;
  final bool isActionBased;
  final String status;

  const _HistoryEntry({
    required this.goalTitle,
    required this.isOneTime,
    required this.isActionBased,
    required this.status,
  });
}
