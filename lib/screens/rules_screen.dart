import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reset_flow/models/rule.dart';
import 'package:reset_flow/providers/rule_provider.dart';
import 'package:reset_flow/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

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
      appBar: AppBar(
        title: const Text('Pre-planned Decisions', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: rules.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Theme.of(context).colorScheme.errorContainer,
                          child: Icon(Icons.shield_outlined, color: Theme.of(context).colorScheme.error, size: 40),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "No Decisions Set",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Pre-plan your responses to stay in control.",
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: rules.length,
                itemBuilder: (context, index) {
                  return _buildRuleCard(rules[index]);
                },
              ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddEditDialog(context, null),
      ),
    );
  }

  Widget _buildRuleCard(AppRule rule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          rule.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _showAddEditDialog(context, rule),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => ref.read(ruleProvider.notifier).deleteRule(rule.id),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rule.solutions.map((sol) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.circle, size: 8, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(child: Text(sol)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
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
              title: Text(existingRule == null ? 'New Decision' : 'Edit Decision'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Problem / Situation'),
                      ),
                      const SizedBox(height: 16),
                      // List of solution fields
                      ...List.generate(solutions.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: solutions[index],
                                  decoration: InputDecoration(
                                    labelText: 'Solution point ${index + 1}',
                                  ),
                                  onChanged: (val) {
                                    solutions[index] = val;
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
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
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            solutions.add('');
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Point'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) return;
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
                  child: const Text('Save'),
                ),
              ],
            );
          }
        );
      },
    );
  }
}
