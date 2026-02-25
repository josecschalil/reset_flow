import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:reset_flow/models/expense.dart';
import 'package:reset_flow/providers/expense_provider.dart';
import 'package:reset_flow/widgets/expense_dialogs.dart';
import 'package:reset_flow/widgets/daily_spend_chart.dart';

class CategoryExpenseDetailScreen extends ConsumerWidget {
  final ExpenseCategory category;

  const CategoryExpenseDetailScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(expenseProvider);
    final notifier = ref.read(expenseProvider.notifier);
    final cs = Theme.of(context).colorScheme;
    final categoryColor = Color(category.colorValue);

    final expenses = state.expenses
        .where((e) => e.categoryId == category.id)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    double total = expenses.fold(0, (sum, e) => sum + e.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text(category.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: () =>
                  _showAddExpenseForCategory(context, notifier),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add'),
              style: FilledButton.styleFrom(
                backgroundColor: categoryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
              ),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── Category Header Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      categoryColor.withOpacity(0.85),
                      categoryColor.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: categoryColor.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6))
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        IconData(category.iconCodePoint,
                            fontFamily: 'MaterialIcons'),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Spending',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                          Text(
                            '₹${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900),
                          ),
                          Text('${expenses.length} transactions',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Daily spend chart for this category
          if (expenses.isNotEmpty)
            SliverToBoxAdapter(
              child: DailySpendChart(
                expenses: expenses,
                color: categoryColor,
                title: 'DAILY SPENDING — ${category.name.toUpperCase()}',
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Section label
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Text('TRANSACTIONS',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: cs.onSurface.withOpacity(0.45))),
            ),
          ),

          // ── Expense list
          if (expenses.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: cs.outline.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            IconData(category.iconCodePoint,
                                fontFamily: 'MaterialIcons'),
                            color: categoryColor,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('No Expenses Yet',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Tap Add to log your first expense.',
                            style: TextStyle(
                                color: cs.onSurface.withOpacity(0.5),
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          if (expenses.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildExpenseTile(
                      context, expenses[index], notifier, cs,
                      categoryColor),
                  childCount: expenses.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildExpenseTile(
    BuildContext context,
    Expense expense,
    ExpenseNotifier notifier,
    ColorScheme cs,
    Color categoryColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                IconData(category.iconCodePoint,
                    fontFamily: 'MaterialIcons'),
                color: categoryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.label.isEmpty ? 'Expense' : expense.label,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('MMM dd, yyyy • hh:mm a')
                        .format(expense.date),
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withOpacity(0.45)),
                  ),
                ],
              ),
            ),
            Text(
              '₹${expense.amount.toStringAsFixed(2)}',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: cs.error),
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert,
                  size: 18, color: cs.onSurface.withOpacity(0.4)),
              onSelected: (val) {
                if (val == 'edit') {
                  _showEditExpenseDialog(context, notifier, expense);
                } else if (val == 'delete') {
                  _showDeleteConfirm(context, notifier, expense.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete',
                        style: TextStyle(color: cs.error))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExpenseForCategory(
      BuildContext context, ExpenseNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AddExpenseDialog(
        notifier: notifier,
        initialCategoryId: category.id,
      ),
    );
  }

  void _showEditExpenseDialog(
      BuildContext context, ExpenseNotifier notifier, Expense expense) {
    showDialog(
      context: context,
      builder: (context) =>
          AddExpenseDialog(notifier: notifier, initialExpense: expense),
    );
  }

  void _showDeleteConfirm(
      BuildContext context, ExpenseNotifier notifier, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.error),
            onPressed: () {
              notifier.deleteExpense(id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
