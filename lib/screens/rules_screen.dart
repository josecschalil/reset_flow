import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reset_flow/models/rule.dart';
import 'package:reset_flow/providers/rule_provider.dart';

class RulesScreen extends ConsumerStatefulWidget {
  const RulesScreen({super.key});

  @override
  ConsumerState<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends ConsumerState<RulesScreen> {
  static const _brand = Color(0xFF5C35C2);

  @override
  Widget build(BuildContext context) {
    final rules = ref.watch(ruleProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Decisions',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1A1A2E))),
                          const SizedBox(height: 4),
                          Text('Pre-planned responses',
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                        
                        onTap: () => _showAddEditDialog(context, null),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, size: 25, color: Colors.grey),
                              SizedBox(width: 4),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Empty state
            if (rules.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEDE9FB),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.shield_outlined,
                                color: _brand, size: 32),
                          ),
                          const SizedBox(height: 16),
                          const Text('No Decisions Yet',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          const SizedBox(height: 8),
                          Text(
                            'Pre-plan your responses to temptations\nand stay in control.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 13,
                                height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // ── Rules list
            if (rules.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildRuleCard(rules[index]),
                    childCount: rules.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleCard(AppRule rule) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          title: Text(
            rule.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1A1A2E),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              '${rule.solutions.length} response${rule.solutions.length != 1 ? 's' : ''}',
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 13),
            ),
          ),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shield, color: _brand, size: 20),
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 16),
            ...rule.solutions.map((sol) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 8, right: 12),
                        decoration: const BoxDecoration(
                          color: Colors.blue, 
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(sol,
                            style: const TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: Color(0xFF1A1A2E))),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit,
                      size: 20, color: Color(0xFF1A1A2E)),
                  onPressed: () => _showAddEditDialog(context, rule),
                ),
                IconButton(
                  icon: const Icon(Icons.delete,
                      size: 20, color: Colors.red),
                  onPressed: () =>
                      ref.read(ruleProvider.notifier).deleteRule(rule.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, AppRule? existingRule) {
    final titleController =
        TextEditingController(text: existingRule?.title ?? '');
    List<String> solutions =
        List.from(existingRule?.solutions ?? ['']);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title:
                Text(existingRule == null ? 'New Decision' : 'Edit Decision'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                          labelText: 'Problem / Situation'),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(solutions.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: solutions[index],
                                decoration: InputDecoration(
                                    labelText:
                                        'Solution point ${index + 1}'),
                                onChanged: (val) =>
                                    solutions[index] = val,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                  Icons.remove_circle_outline),
                              onPressed: () {
                                if (solutions.length > 1) {
                                  setState(
                                      () => solutions.removeAt(index));
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => solutions.add('')),
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
                  child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  if (titleController.text.trim().isEmpty) return;
                  final finalSolutions = solutions
                      .where((s) => s.trim().isNotEmpty)
                      .toList();
                  if (finalSolutions.isEmpty) return;

                  if (existingRule == null) {
                    ref.read(ruleProvider.notifier).addRule(
                        titleController.text.trim(), finalSolutions);
                  } else {
                    ref.read(ruleProvider.notifier).updateRule(AppRule(
                      id: existingRule.id,
                      title: titleController.text.trim(),
                      solutions: finalSolutions,
                      createdAt: existingRule.createdAt,
                    ));
                  }
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }
}
