import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reset_flow/providers/goal_provider.dart';
import 'package:reset_flow/screens/focus_mode_screen.dart';
import 'package:flutter/services.dart';
import 'package:reset_flow/utils/quotes.dart';
import 'package:reset_flow/widgets/momentum_roulette.dart';
import 'package:reset_flow/widgets/analytics_section.dart';
import 'dart:math' as math;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final goalState = ref.watch(goalProvider);
    final notifier = ref.read(goalProvider.notifier);

    final int completedToday =
        goalState.todayLogs.where((l) => l.status == 'completed').length;
    final int failedToday =
        goalState.todayLogs.where((l) => l.status == 'failed').length;
    final int totalToday = goalState.todayLogs.length;
    final double successRate =
        totalToday == 0 ? 0 : (completedToday / totalToday) * 100;

    final double weeklyAvg = notifier.getWeeklySuccessRate();
    final int bestStreak = notifier.getBestCurrentStreak();
    final List<bool> last7 = notifier.getLast7DayResults();

    return Scaffold(
      body: SafeArea(
        child: goalState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildHeader(),
                        const SizedBox(height: 28),
                        _buildDashboard(
                          context,
                          successRate,
                          completedToday,
                          failedToday,
                          totalToday,
                          weeklyAvg,
                          bestStreak,
                          last7,
                        ),
                        const SizedBox(height: 28),
                        const AnalyticsSection(),
                        const SizedBox(height: 28),
                        MomentumRoulette(successRate: successRate),
                        const SizedBox(height: 40),
                      ]),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ResetFlow',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Beat Procrastination',
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.timer_outlined, size: 28),
              tooltip: 'Deep Focus Mode',
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FocusModeScreen()),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.format_quote_rounded,
                  color: colorScheme.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  DailyQuotes.todaysQuote,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withOpacity(0.8),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    double successRate,
    int completed,
    int failed,
    int total,
    double weeklyAvg,
    int bestStreak,
    List<bool> last7,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    String level;
    Color levelColor;
    if (successRate >= 90) {
      level = 'Peak Performance';
      levelColor = const Color(0xFF2E7D32);
    } else if (successRate >= 70) {
      level = 'Building Momentum';
      levelColor = const Color(0xFF1565C0);
    } else if (successRate >= 50) {
      level = 'Steady Progress';
      levelColor = const Color(0xFFE65100);
    } else if (successRate > 0) {
      level = 'Getting Started';
      levelColor = colorScheme.onSurface.withOpacity(0.5);
    } else {
      level = 'No Activity Yet';
      levelColor = colorScheme.onSurface.withOpacity(0.4);
    }

    return Column(
      children: [
        // --- Top Row: Gauge + Key Metrics ---
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Performance Gauge
              Expanded(
                flex: 5,
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: colorScheme.outline.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TODAY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: colorScheme.onSurface.withOpacity(0.45),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: SizedBox(
                          height: 120,
                          width: 120,
                          child: CustomPaint(
                            painter: _GaugePainter(
                              value: successRate / 100,
                              trackColor: colorScheme.surfaceVariant,
                              fillColor: levelColor,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${successRate.toInt()}%',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: levelColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            level,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: levelColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Right column: stacked metrics
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    _buildMetricTile(
                      context,
                      label: 'Completed',
                      value: '$completed / $total',
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: const Color(0xFF2E7D32),
                    ),
                    const SizedBox(height: 12),
                    _buildMetricTile(
                      context,
                      label: 'Best Streak',
                      value: '$bestStreak days',
                      icon: Icons.local_fire_department_outlined,
                      iconColor: const Color(0xFFE65100),
                    ),
                    const SizedBox(height: 12),
                    _buildMetricTile(
                      context,
                      label: 'Weekly Avg',
                      value: '${weeklyAvg.toInt()}%',
                      icon: Icons.trending_up_rounded,
                      iconColor: const Color(0xFF1565C0),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // --- 7-Day Consistency Bar ---
        _buildConsistencyBar(context, last7),
      ],
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: colorScheme.outline.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsistencyBar(BuildContext context, List<bool> last7) {
    final colorScheme = Theme.of(context).colorScheme;
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '7-DAY CONSISTENCY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: colorScheme.onSurface.withOpacity(0.45),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final dayOffset = 6 - i;
              final dayDate = now.subtract(Duration(days: dayOffset));
              final dayLabel = days[dayDate.weekday - 1];
              final isToday = dayOffset == 0;
              final isActive = i < last7.length && last7[i];

              return Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? const Color(0xFF2E7D32).withOpacity(0.15)
                          : colorScheme.surfaceVariant.withOpacity(0.5),
                      border: Border.all(
                        color: isToday
                            ? colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      isActive
                          ? Icons.check_rounded
                          : Icons.remove_rounded,
                      size: 16,
                      color: isActive
                          ? const Color(0xFF2E7D32)
                          : colorScheme.onSurface.withOpacity(0.25),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dayLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday
                          ? colorScheme.primary
                          : colorScheme.onSurface.withOpacity(0.45),
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

/// Custom painter for the circular performance gauge arc.
class _GaugePainter extends CustomPainter {
  final double value; // 0.0 to 1.0
  final Color trackColor;
  final Color fillColor;

  const _GaugePainter({
    required this.value,
    required this.trackColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 10.0;
    const startAngle = math.pi * 0.75; // 135 degrees
    const sweepTotal = math.pi * 1.5; // 270 degrees arc

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track arc
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, sweepTotal, false, trackPaint);

    // Fill arc
    if (value > 0) {
      final fillPaint = Paint()
        ..color = fillColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, sweepTotal * value, false, fillPaint);
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value || old.fillColor != fillColor;
}
