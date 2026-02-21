import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:reset_flow/models/rule.dart';
import 'package:reset_flow/providers/rule_provider.dart';
import 'package:reset_flow/theme/app_theme.dart';

class RulesScreen extends ConsumerStatefulWidget {
  const RulesScreen({super.key});

  @override
  ConsumerState<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends ConsumerState<RulesScreen> {
  @override
  Widget build(BuildContext context) {
    final rules = ref.watch(ruleProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Pre-planned Decisions', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: rules.isEmpty
          ? const Center(
              child: Text(
                "No decisions set.\nTap + to add a problem and solutions.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24.0),
              itemCount: rules.length,
              itemBuilder: (context, index) {
                final rule = rules[index];
                return _buildRuleCard(rule);
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.accentSecondary,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddEditDialog(context, null),
      ),
    );
  }

  Widget _buildRuleCard(AppRule rule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: AppTheme.glassShadows(),
          borderRadius: BorderRadius.circular(24),
        ),
        child: GlassmorphicContainer(
          width: double.infinity,
          height: 100 + (rule.solutions.length * 40.0), // Dynamic height based on solutions
          borderRadius: 24,
          blur: 20,
          alignment: Alignment.center,
          border: 1.5,
          linearGradient: AppTheme.glassLinearGradient(),
          borderGradient: AppTheme.glassBorderGradient(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        rule.title,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.dangerColor),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.textSecondary),
                          onPressed: () => _showAddEditDialog(context, rule),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.textSecondary),
                          onPressed: () => ref.read(ruleProvider.notifier).deleteRule(rule.id),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: rule.solutions.map((sol) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("• ", style: TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 18)),
                          Expanded(
                            child: Text(
                              sol,
                              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, height: 1.4, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, AppRule? existingRule) {
    final titleController = TextEditingController(text: existingRule?.title ?? '');
    List<String> solutions = List.from(existingRule?.solutions ?? ['']);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.backgroundLight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(existingRule == null ? 'New Decision' : 'Edit Decision', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(labelText: 'Problem / Situation'),
                      ),
                      const SizedBox(height: 24),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Pointwise Solutions:", style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                      ),
                      const SizedBox(height: 8),
                      // List of solution fields
                      ...List.generate(solutions.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: solutions[index],
                                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'Solution point ${index + 1}',
                                    isDense: true,
                                  ),
                                  onChanged: (val) {
                                    solutions[index] = val;
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: AppTheme.dangerColor, size: 20),
                                onPressed: () {
                                  if (solutions.length > 1) {
                                    setState(() {
                                      solutions.removeAt(index);
                                    });
                                  }
                                },
                              )
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            solutions.add(''); // Add empty solution
                          });
                        },
                        icon: const Icon(Icons.add, color: AppTheme.accentColor),
                        label: const Text('Add Point', style: TextStyle(color: AppTheme.accentColor)),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentSecondary),
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) return;
                    
                    // Filter out empty solutions
                    final finalSolutions = solutions.where((s) => s.trim().isNotEmpty).toList();
                    if (finalSolutions.isEmpty) return;
                    
                    if (existingRule == null) {
                      ref.read(ruleProvider.notifier).addRule(
                        titleController.text.trim(),
                        finalSolutions,
                      );
                    } else {
                       final updated = AppRule(
                         id: existingRule.id,
                         title: titleController.text.trim(),
                         solutions: finalSolutions,
                         createdAt: existingRule.createdAt,
                       );
                       ref.read(ruleProvider.notifier).updateRule(updated);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }
}
