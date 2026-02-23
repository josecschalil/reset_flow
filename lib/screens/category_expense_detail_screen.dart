import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:reset_flow/models/expense.dart';
import 'package:reset_flow/providers/expense_provider.dart';
import 'package:reset_flow/widgets/expense_dialogs.dart';

class CategoryExpenseDetailScreen extends ConsumerWidget {
  final ExpenseCategory category;

  const CategoryExpenseDetailScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(expenseProvider);
    final notifier = ref.read(expenseProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final categoryColor = Color(category.colorValue);

    // Filter expenses for this category
    final expenses = state.expenses.where((e) => e.categoryId == category.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddExpenseForCategory(context, notifier),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryHeader(context, expenses, categoryColor),
          Expanded(
            child: expenses.isEmpty
                ? const Center(child: Text('No expenses in this category.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      return _buildExpenseTile(context, expense, notifier, colorScheme);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(BuildContext context, List<Expense> expenses, Color categoryColor) {
    double total = expenses.fold(0, (sum, e) => sum + e.amount);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: categoryColor.withOpacity(0.05),
        border: Border(bottom: BorderSide(color: categoryColor.withOpacity(0.1))),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: categoryColor.withOpacity(0.1),
            child: Icon(
              IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
              color: categoryColor,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Total Spending',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          Text(
            '₹${total.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
          ),
          Text(
            '${expenses.length} transactions',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseTile(BuildContext context, Expense expense, ExpenseNotifier notifier, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          expense.label.isEmpty ? 'Expense' : expense.label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          DateFormat('MMM dd, yyyy • hh:mm a').format(expense.date),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₹${expense.amount.toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.error),
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'edit') {
                  _showEditExpenseDialog(context, notifier, expense);
                } else if (val == 'delete') {
                  _showDeleteConfirm(context, notifier, expense.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExpenseForCategory(BuildContext context, ExpenseNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AddExpenseDialog(
        notifier: notifier,
        initialExpense: Expense(categoryId: category.id, amount: 0, date: DateTime.now()),
      ),
    );
  }

  void _showEditExpenseDialog(BuildContext context, ExpenseNotifier notifier, Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AddExpenseDialog(notifier: notifier, initialExpense: expense),
    );
  }

  void _showDeleteConfirm(BuildContext context, ExpenseNotifier notifier, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              notifier.deleteExpense(id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
