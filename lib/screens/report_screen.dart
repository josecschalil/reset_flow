import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:reset_flow/providers/goal_provider.dart';
import 'package:reset_flow/theme/app_theme.dart';
import 'package:intl/intl.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  @override
  Widget build(BuildContext context) {
    final goalState = ref.watch(goalProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Advanced Report', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: goalState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildSummaryCards(goalState),
                   const SizedBox(height: 32),
                   Text(
                      "Consistency Dashboard",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 16),
                   _buildGitHubHeatmap(goalState),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCards(GoalState state) {
    int totalCompleted = state.allLogs.where((l) => l.status == 'completed').length;
    int totalFailed = state.allLogs.where((l) => l.status == 'failed').length;

    return Row(
      children: [
        Expanded(child: _buildGlassCard("Total Completed", "$totalCompleted", AppTheme.successColor)),
        const SizedBox(width: 16),
        Expanded(child: _buildGlassCard("Missed/Failed", "$totalFailed", AppTheme.dangerColor)),
      ],
    );
  }

  Widget _buildGlassCard(String title, String value, Color accentInfo) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: AppTheme.glassShadows(),
        borderRadius: BorderRadius.circular(24),
      ),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 120,
        borderRadius: 24,
        blur: 20,
        alignment: Alignment.center,
        border: 1.5,
        linearGradient: AppTheme.glassLinearGradient(),
        borderGradient: AppTheme.glassBorderGradient(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: accentInfo)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  // A custom Github-style heatmap representation
  Widget _buildGitHubHeatmap(GoalState state) {
    // Generate the last 90 days.
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd');
    final Map<String, int> dailyDensity = {};

    for (var log in state.allLogs) {
      if (log.status == 'completed') {
         dailyDensity[log.date] = (dailyDensity[log.date] ?? 0) + 1;
      }
    }

    List<Widget> columns = [];
    int daysInWeekColumn = 0;
    List<Widget> currentColumn = [];

    // Create 12 weeks of data (84 days)
    for (int i = 84; i >= 0; i--) {
       final day = now.subtract(Duration(days: i));
       final dayStr = formatter.format(day);
       
       final density = dailyDensity[dayStr] ?? 0;
       Color cellColor = AppTheme.textSecondary.withOpacity(0.1); // No activity

       if (density > 0 && density <= 2) cellColor = AppTheme.successColor.withOpacity(0.3);
       if (density > 2 && density <= 4) cellColor = AppTheme.successColor.withOpacity(0.6);
       if (density > 4) cellColor = AppTheme.successColor;

       currentColumn.add(
         Container(
           width: 16,
           height: 16,
           margin: const EdgeInsets.only(bottom: 6),
           decoration: BoxDecoration(
             color: cellColor,
             borderRadius: BorderRadius.circular(4),
           ),
         )
       );

       daysInWeekColumn++;

       if (daysInWeekColumn == 7 || i == 0) {
          columns.add(
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: currentColumn,
            )
          );
          currentColumn = [];
          daysInWeekColumn = 0;
       }
    }

    return _buildHeatMap(columns);
  }

  Widget _buildHeatMap(List<Widget> columns) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: AppTheme.glassShadows(),
        borderRadius: BorderRadius.circular(24),
      ),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 250,
        borderRadius: 24,
        blur: 20,
        alignment: Alignment.center,
        border: 1.5,
        linearGradient: AppTheme.glassLinearGradient(),
        borderGradient: AppTheme.glassBorderGradient(),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Last 3 Months", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                  Row(
                    children: [
                      const Text("Less", style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                      const SizedBox(width: 4),
                      _legendBox(AppTheme.textSecondary.withOpacity(0.1)),
                      _legendBox(AppTheme.successColor.withOpacity(0.3)),
                      _legendBox(AppTheme.successColor.withOpacity(0.6)),
                      _legendBox(AppTheme.successColor),
                      const SizedBox(width: 4),
                      const Text("More", style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: columns.map((col) => Padding(padding: const EdgeInsets.only(right: 6), child: col)).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendBox(Color color) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
    );
  }
}
