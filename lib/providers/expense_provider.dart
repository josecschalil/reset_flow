import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reset_flow/models/expense.dart';
import 'package:reset_flow/services/database_helper.dart';

class ExpenseState {
  final List<Expense> expenses;
  final List<ExpenseCategory> categories;
  final bool isLoading;
  final DateTime selectedMonth;

  ExpenseState({
    required this.expenses,
    required this.categories,
    this.isLoading = false,
    DateTime? selectedMonth,
  }) : selectedMonth = selectedMonth ?? DateTime(DateTime.now().year, DateTime.now().month);

  ExpenseState copyWith({
    List<Expense>? expenses,
    List<ExpenseCategory>? categories,
    bool? isLoading,
    DateTime? selectedMonth,
  }) {
    return ExpenseState(
      expenses: expenses ?? this.expenses,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      selectedMonth: selectedMonth ?? this.selectedMonth,
    );
  }

  /// All expenses for the selected month only
  List<Expense> get selectedMonthExpenses {
    return expenses.where((e) =>
        e.date.year == selectedMonth.year && e.date.month == selectedMonth.month).toList();
  }

  /// Whether the selected month is the current month
  bool get isCurrentMonth {
    final now = DateTime.now();
    return selectedMonth.year == now.year && selectedMonth.month == now.month;
  }

  /// Total spent for the selected month
  double get totalForSelectedMonth {
    return selectedMonthExpenses.fold(0, (sum, e) => sum + e.amount);
  }

  /// List of distinct months that have at least one expense, plus current month
  List<DateTime> get availableMonths {
    final months = <DateTime>{};
    months.add(DateTime(DateTime.now().year, DateTime.now().month));
    for (final e in expenses) {
      months.add(DateTime(e.date.year, e.date.month));
    }
    final sorted = months.toList()..sort((a, b) => b.compareTo(a)); // newest first
    return sorted;
  }
}

final expenseProvider = StateNotifierProvider<ExpenseNotifier, ExpenseState>((ref) {
  return ExpenseNotifier(DatabaseHelper.instance);
});

class ExpenseNotifier extends StateNotifier<ExpenseState> {
  final DatabaseHelper dbHelper;

  ExpenseNotifier(this.dbHelper) : super(ExpenseState(expenses: [], categories: [], isLoading: true)) {
    loadAll();
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true);
    final expenses = await dbHelper.getAllExpenses();
    final categories = await dbHelper.getAllExpenseCategories();
    state = state.copyWith(expenses: expenses, categories: categories, isLoading: false);
  }

  void goToPreviousMonth() {
    final current = state.selectedMonth;
    final prev = DateTime(current.year, current.month - 1);
    state = state.copyWith(selectedMonth: prev);
  }

  void goToNextMonth() {
    final current = state.selectedMonth;
    final next = DateTime(current.year, current.month + 1);
    final now = DateTime.now();
    // Prevent going beyond current month
    if (next.year > now.year || (next.year == now.year && next.month > now.month)) return;
    state = state.copyWith(selectedMonth: next);
  }

  void selectMonth(DateTime month) {
    state = state.copyWith(selectedMonth: month);
  }

  // --- Category CRUD ---
  Future<void> addCategory(String name, int iconCodePoint, int colorValue) async {
    final category = ExpenseCategory(name: name, iconCodePoint: iconCodePoint, colorValue: colorValue);
    await dbHelper.insertExpenseCategory(category);
    await loadAll();
  }

  Future<void> updateCategory(ExpenseCategory category) async {
    await dbHelper.updateExpenseCategory(category);
    await loadAll();
  }

  Future<void> deleteCategory(String id) async {
    await dbHelper.deleteExpenseCategory(id);
    await loadAll();
  }

  // --- Expense CRUD ---
  Future<void> addExpense(String categoryId, double amount, DateTime date, String label) async {
    final expense = Expense(categoryId: categoryId, amount: amount, date: date, label: label);
    await dbHelper.insertExpense(expense);
    await loadAll();
  }

  Future<void> updateExpense(Expense expense) async {
    await dbHelper.updateExpense(expense);
    await loadAll();
  }

  Future<void> deleteExpense(String id) async {
    await dbHelper.deleteExpense(id);
    await loadAll();
  }
}
