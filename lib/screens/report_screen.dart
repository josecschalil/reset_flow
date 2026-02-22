import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      appBar: AppBar(
        title: const Text('Advanced Report', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: goalState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildSummaryCards(goalState),
                   const SizedBox(height: 32),
                   Text(
                      "Consistency Dashboard",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
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
        Expanded(child: _buildSummaryCard("Completed", "$totalCompleted", Colors.green)),
        const SizedBox(width: 12),
        Expanded(child: _buildSummaryCard("Missed/Failed", "$totalFailed", Theme.of(context).colorScheme.error)),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, Color accentColor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: accentColor)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12)),
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
       Color cellColor = Theme.of(context).colorScheme.surfaceVariant;

       if (density > 0 && density <= 2) cellColor = Colors.green.withOpacity(0.3);
       if (density > 2 && density <= 4) cellColor = Colors.green.withOpacity(0.6);
       if (density > 4) cellColor = Colors.green;

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
    return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Last 3 Months", style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      const Text("Less", style: TextStyle(fontSize: 10)),
                      const SizedBox(width: 4),
                      _legendBox(Theme.of(context).colorScheme.surfaceVariant),
                      _legendBox(Colors.green.withOpacity(0.3)),
                      _legendBox(Colors.green.withOpacity(0.6)),
                      _legendBox(Colors.green),
                      const SizedBox(width: 4),
                      const Text("More", style: TextStyle(fontSize: 10)),
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
