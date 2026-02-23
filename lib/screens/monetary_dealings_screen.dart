import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:reset_flow/models/financial_transaction.dart';
import 'package:reset_flow/providers/monetary_provider.dart';
import 'package:reset_flow/providers/emi_provider.dart';
import 'package:reset_flow/models/emi_model.dart';
import 'package:reset_flow/screens/emi_details_screen.dart';
import 'package:reset_flow/providers/expense_provider.dart';
import 'package:reset_flow/models/expense.dart';
import 'package:reset_flow/widgets/expense_dialogs.dart';
import 'package:reset_flow/screens/category_expense_detail_screen.dart';

class MonetaryDealingsScreen extends ConsumerStatefulWidget {
  const MonetaryDealingsScreen({super.key});

  @override
  ConsumerState<MonetaryDealingsScreen> createState() => _MonetaryDealingsScreenState();
}

class _MonetaryDealingsScreenState extends ConsumerState<MonetaryDealingsScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(monetaryProvider);
    final notifier = ref.read(monetaryProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Finance'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Ledger'),
              Tab(text: 'Expenses'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildLedgerView(state, notifier, colorScheme),
            _buildExpensesView(),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerView(MonetaryState state, MonetaryNotifier notifier, ColorScheme colorScheme) {
    return state.isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () => notifier.loadTransactions(),
            child: CustomScrollView(
              slivers: [
                // 1. Summary Dashboard
                SliverToBoxAdapter(
                  child: _buildSummaryDashboard(notifier, colorScheme),
                ),

                // 1.1 Action Cards
                SliverToBoxAdapter(
                  child: _buildActionCards(context, notifier, colorScheme),
                ),

                // 2. EMI & Liabilities Section
                _buildEMISection(colorScheme),

                // 3. People List Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                    child: Text(
                      'People',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                // 4. People List
                _buildPeopleList(state, notifier, colorScheme),
              ],
            ),
          );
  }

  Widget _buildExpensesView() {
    final expenseState = ref.watch(expenseProvider);
    final expenseNotifier = ref.read(expenseProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    if (expenseState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => expenseNotifier.loadAll(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildSwipeableMonthCard(expenseState, expenseNotifier, colorScheme),
          ),
          if (expenseState.isCurrentMonth)
            SliverToBoxAdapter(
              child: _buildExpenseActionCards(expenseNotifier, colorScheme),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text(
                'Spending by Category',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
          ),
          _buildExpenseGrid(expenseState, expenseNotifier, colorScheme),
        ],
      ),
    );
  }

  Widget _buildActionCards(BuildContext context, MonetaryNotifier notifier, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionCard(
              context,
              'New Dealing',
              Icons.add_circle_outline,
              colorScheme.primary,
              () => _showAddTransactionDialog(context, notifier),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionCard(
              context,
              'Add EMI',
              Icons.calendar_today_outlined,
              colorScheme.secondary,
              () => _showAddEMIDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEMISection(ColorScheme colorScheme) {
    final emiState = ref.watch(emiProvider);
    if (emiState.plans.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Text(
              'EMI & Liabilities',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          ...emiState.plans.map((plan) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: _buildEMIPlanTile(context, plan, ref.read(monetaryProvider.notifier), ref),
            ),
          )),
        ],
      ),
    );
  }

  void _showAddEMIDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const AddEMIDialog());
  }
  Widget _buildEMIPlanTile(BuildContext context, EMIPlan plan, MonetaryNotifier notifier, WidgetRef ref) {
    final installments = ref.watch(emiProvider).installments[plan.id] ?? [];
    int paidCount = installments.where((i) => i.isPaid).length;
    double paidAmount = installments.where((i) => i.isPaid).fold(0, (sum, i) => sum + i.amount);
    double progress = installments.isEmpty ? 0 : paidCount / installments.length;

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EMIDetailScreen(planId: plan.id))),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation(plan.type == 'credit' ? Colors.green : Colors.orange),
                  ),
                ),
                Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(plan.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(plan.provider, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${(plan.totalAmount - paidAmount).toStringAsFixed(2)}', 
                  style: TextStyle(fontWeight: FontWeight.bold, color: plan.type == 'credit' ? Colors.green : Colors.orange)),
                const Text('REMAINING', style: TextStyle(fontSize: 8, color: Colors.grey)),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryDashboard(MonetaryNotifier notifier, ColorScheme colorScheme) {
    final emiState = ref.watch(emiProvider);
    double credit = notifier.totalCredit;
    double debit = notifier.totalDebit;
    double net = notifier.netBalance;

    double emiRemainingLiability = 0;
    double emiRemainingAsset = 0;

    for (var plan in emiState.plans) {
      final insts = emiState.installments[plan.id] ?? [];
      double unpaid = insts.where((i) => !i.isPaid).fold(0, (sum, i) => sum + i.amount);
      if (plan.type == 'debit') {
        emiRemainingLiability += unpaid;
      } else {
        emiRemainingAsset += unpaid;
      }
    }

    double totalNet = net + emiRemainingAsset - emiRemainingLiability;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Total Net Worth',
            style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          Text(
            '₹${totalNet.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Current Cash: ₹${net.toStringAsFixed(2)}',
            style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.6), fontSize: 12),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildSummaryItem(
                'ASSETS', 
                '₹${(credit + emiRemainingAsset).toStringAsFixed(0)}', 
                Icons.arrow_upward, 
                Colors.greenAccent,
                colorScheme.onPrimary
              ),
              Container(width: 1, height: 40, color: colorScheme.onPrimary.withOpacity(0.2)),
              _buildSummaryItem(
                'LIABILITIES', 
                '₹${(debit + emiRemainingLiability).toStringAsFixed(0)}', 
                Icons.arrow_downward, 
                Colors.orangeAccent,
                colorScheme.onPrimary
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color iconColor, Color textColor) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ],
          ),
          Text(value, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPeopleList(MonetaryState state, MonetaryNotifier notifier, ColorScheme colorScheme) {
    final summary = notifier.personSummary;
    if (summary.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('No dealings yet. Use cards above to add.')),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          String person = summary.keys.elementAt(index);
          double pCredit = summary[person]!['credit']!;
          double pDebit = summary[person]!['debit']!;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: colorScheme.secondaryContainer,
                child: Text(person[0].toUpperCase(), style: TextStyle(color: colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold)),
              ),
              title: Text(person, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: (pCredit == 0 && pDebit == 0)
                ? const Text(
                    'FULLY SETTLED',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                  )
                : Wrap(
                    spacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_upward, size: 14, color: pCredit == 0 ? Colors.grey : Colors.green),
                          Text(' ₹${pCredit.toStringAsFixed(0)} ', style: TextStyle(color: pCredit == 0 ? Colors.grey : Colors.green, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_downward, size: 14, color: pDebit == 0 ? Colors.grey : Colors.orange),
                          Text(' ₹${pDebit.toStringAsFixed(0)} ', style: TextStyle(color: pDebit == 0 ? Colors.grey : Colors.orange, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
              trailing: PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'lent') {
                    _showAddTransactionDialog(context, notifier, initialPerson: person, initialType: TransactionType.credit);
                  } else if (val == 'borrowed') {
                    _showAddTransactionDialog(context, notifier, initialPerson: person, initialType: TransactionType.debit);
                  } else if (val == 'delete') {
                    _showDeletePersonConfirm(person, notifier);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'lent',
                    child: Row(
                      children: [
                        Icon(Icons.add_circle_outline, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text('Quick Lent'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'borrowed',
                    child: Row(
                      children: [
                        Icon(Icons.remove_circle_outline, color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Text('Quick Borrowed'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Delete Person', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
              onTap: () => _showPersonDetail(person),
              onLongPress: () => _showDeletePersonConfirm(person, notifier),
            ),
          );
        },
        childCount: summary.length,
      ),
    );
  }

  void _showPersonDetail(String person) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PersonDetailScreen(personName: person)),
    );
  }

  void _showDeletePersonConfirm(String person, MonetaryNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Person?'),
        content: Text('This will delete all transaction history for $person. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              notifier.deletePerson(person);
              Navigator.pop(context);
            },
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context, MonetaryNotifier notifier, {String? initialPerson, TransactionType? initialType}) {
    showDialog(
      context: context,
      builder: (context) => AddTransactionDialog(
        initialPerson: initialPerson,
        initialType: initialType,
      ),
    );
  }

  // --- EXPENSES UI HELPERS ---

  Widget _buildSwipeableMonthCard(ExpenseState state, ExpenseNotifier notifier, ColorScheme colorScheme) {
    final sel = state.selectedMonth;
    final monthLabel = DateFormat('MMMM yyyy').format(sel);
    final total = state.totalForSelectedMonth;
    final txCount = state.selectedMonthExpenses.length;

    final now = DateTime.now();
    final isCurrentMonth = state.isCurrentMonth;
    // Can go back if there are older months in the data
    final canGoBack = state.availableMonths.any(
        (m) => m.isBefore(DateTime(sel.year, sel.month)));

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withOpacity(0.8),
            colorScheme.primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.2),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
        child: Column(
          children: [
            // Month navigation row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: canGoBack ? () => notifier.goToPreviousMonth() : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                  color: Colors.white,
                  iconSize: 32,
                  disabledColor: Colors.white24,
                ),
                // Month label
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        monthLabel.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    if (!isCurrentMonth) ...
                      [
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Archive',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                  ],
                ),
                IconButton(
                  onPressed: isCurrentMonth ? null : () => notifier.goToNextMonth(),
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: Colors.white,
                  iconSize: 32,
                  disabledColor: Colors.white24,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '₹${total.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              '$txCount transaction${txCount == 1 ? '' : 's'} this month',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseActionCards(ExpenseNotifier notifier, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionCard(
              context,
              'Add Expense',
              Icons.receipt_long,
              colorScheme.tertiary,
              () => _showAddExpenseDialog(context, notifier),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionCard(
              context,
              'Categories',
              Icons.category_outlined,
              colorScheme.secondary,
              () => _showManageCategoriesDialog(context, notifier),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseGrid(ExpenseState state, ExpenseNotifier notifier, ColorScheme colorScheme) {
    if (state.categories.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('No categories found.')),
      );
    }

    final monthExpenses = state.selectedMonthExpenses;
    final totalMonthly = monthExpenses.fold(0.0, (sum, e) => sum + e.amount);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.0,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final category = state.categories[index];
            final categoryExpenses = monthExpenses
                .where((e) => e.categoryId == category.id)
                .toList();

            final double total = categoryExpenses.fold(0.0, (sum, e) => sum + e.amount);
            final double totalShare = totalMonthly > 0 ? total / totalMonthly : 0;

            return _buildCategoryCard(category, total, categoryExpenses.length, totalShare);
          },
          childCount: state.categories.length,
        ),
      ),
    );
  }

  Widget _buildCategoryCard(ExpenseCategory category, double total, int count, double share) {
    final colorScheme = Theme.of(context).colorScheme;
    final categoryColor = Color(category.colorValue);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryExpenseDetailScreen(category: category),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: categoryColor.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                  size: 100,
                  color: categoryColor.withOpacity(0.05),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                            color: categoryColor,
                            size: 20,
                          ),
                        ),
                        if (share > 0)
                          Text(
                            '${(share * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: categoryColor.withOpacity(0.5),
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      category.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${total.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: total > 0 ? colorScheme.onSurface : Colors.grey.shade400,
                      ),
                    ),
                    if (total > 0) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: share,
                          backgroundColor: categoryColor.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(categoryColor.withOpacity(0.4)),
                          minHeight: 4,
                        ),
                      ),
                    ] else
                      Text(
                        '$count expenses',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Removing _buildExpenseList as it's replaced by grid and detail screen


  void _showDeleteExpenseConfirm(
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

  void _showAddExpenseDialog(BuildContext context, ExpenseNotifier notifier,
      {Expense? initialExpense}) {
    showDialog(
      context: context,
      builder: (context) =>
          AddExpenseDialog(notifier: notifier, initialExpense: initialExpense),
    );
  }

  void _showManageCategoriesDialog(
      BuildContext context, ExpenseNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => ManageCategoriesDialog(notifier: notifier),
    );
  }
}

// --- PersonDetailScreen ---
class PersonDetailScreen extends ConsumerWidget {
  final String personName;
  const PersonDetailScreen({super.key, required this.personName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(monetaryProvider);
    final notifier = ref.read(monetaryProvider.notifier);
    final personTxs = state.transactions.where((tx) => tx.personName == personName).toList();
    final colorScheme = Theme.of(context).colorScheme;

    final creditTxs = personTxs.where((tx) => tx.type == TransactionType.credit).toList();
    final debitTxs = personTxs.where((tx) => tx.type == TransactionType.debit).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(personName),
          actions: [
            IconButton(
              icon: const Icon(Icons.merge_type),
              tooltip: 'Merge Balances',
              onPressed: () => _showMergeConfirm(context, notifier, personName),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete Person',
              onPressed: () => _showDeletePersonConfirm(context, notifier, personName),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'He Owes Me'),
              Tab(text: 'I Owe Him'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBucketList(context, personName, TransactionType.credit, notifier, colorScheme, Colors.green, ref),
            _buildBucketList(context, personName, TransactionType.debit, notifier, colorScheme, Colors.orange, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildBucketList(BuildContext context, String person, TransactionType type, MonetaryNotifier notifier, ColorScheme colorScheme, Color accent, WidgetRef ref) {
    final allTxs = notifier.state.transactions;
    final txs = allTxs.where((tx) => tx.personName == person && tx.type == type).toList();
    
    double totalLent = txs.where((tx) => tx.amount > 0).fold(0.0, (sum, tx) => sum + tx.amount);
    double totalRepaid = txs.where((tx) => tx.amount < 0).fold(0.0, (sum, tx) => sum + tx.amount).abs();
    double remaining = totalLent - totalRepaid;

    final items = txs.where((tx) => tx.amount > 0 || (tx.amount < 0 && (tx.parentId == null || !txs.any((p) => p.id == tx.parentId)))).toList();

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.08),
            border: Border(bottom: BorderSide(color: accent.withOpacity(0.2))),
          ),
          child: Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flex(
                    direction: Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('REMAINING', style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                            Text('₹${remaining.toStringAsFixed(2)}', style: TextStyle(color: accent, fontSize: 22, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      if (remaining > 0)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          alignment: WrapAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _showBulkPaymentDialog(context, notifier, person, type, remaining),
                              icon: const Icon(Icons.payment, size: 16),
                              label: const Text('Add Payment', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: accent,
                                side: BorderSide(color: accent),
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                minimumSize: const Size(0, 36),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _showSettleAllConfirm(context, notifier, person, type, remaining),
                              icon: const Icon(Icons.check_circle_outline, size: 16),
                              label: const Text('Settle', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                minimumSize: const Size(0, 36),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMiniStat('Total Dealing', '₹${totalLent.toStringAsFixed(0)}', colorScheme.onSurfaceVariant),
                  _buildMiniStat('Total Settled', '₹${totalRepaid.toStringAsFixed(0)}', Colors.grey),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: txs.isEmpty
          ? const Center(child: Text('No history here.'))
          : ListView(
            padding: const EdgeInsets.all(12),
            children: items.map((item) {
                if (item.amount < 0) {
                  return _buildOrphanRepayment(context, notifier, item, accent);
                }
                return _buildParentDealing(context, notifier, item, txs, accent);
              }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildOrphanRepayment(BuildContext context, MonetaryNotifier notifier, FinancialTransaction item, Color accent) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: const Icon(Icons.payment_outlined, color: Colors.grey, size: 20),
          title: Text(item.label.isEmpty ? 'Misc Payment' : item.label, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 14)),
          subtitle: Text(DateFormat('MMM dd').format(item.date), style: const TextStyle(fontSize: 11)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('-₹${item.amount.abs().toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 14)),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                onPressed: () => _showDeleteTransactionConfirm(context, notifier, item.id),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildParentDealing(BuildContext context, MonetaryNotifier notifier, FinancialTransaction parent, List<FinancialTransaction> allTxs, Color accent) {
    final children = allTxs.where((tx) => tx.parentId == parent.id).toList();
    double parentRemaining = parent.amount - children.fold(0.0, (sum, tx) => sum + tx.amount.abs());

    Widget buildTitle() => Text(
      parent.label.isEmpty ? 'Dealing' : parent.label,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
    );

    Widget buildSubtitle() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(DateFormat('MMM dd').format(parent.date), style: const TextStyle(fontSize: 11)),
        if (parentRemaining > 0)
          Text('Original: ₹${parent.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
        if (parentRemaining <= 0)
          const Text('FULLY SETTLED', style: TextStyle(fontSize: 9, color: Colors.green, fontWeight: FontWeight.bold)),
      ],
    );

    Widget buildTrailing() => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (parentRemaining > 0) ...[
              Text(
                '₹${parentRemaining.toStringAsFixed(2)}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: accent),
              ),
              const Text('REMAINING', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey)),
            ] else ...[
              Text(
                '₹${parent.amount.toStringAsFixed(0)}/${parent.amount.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
              ),
              const Text('SETTLED', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ],
        ),
        const SizedBox(width: 4),
        if (parentRemaining > 0)
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.receipt_long_outlined, size: 18),
            tooltip: 'Repayment',
            onPressed: () => _showRepaymentDialog(context, notifier, parent, parentRemaining),
          ),
        PopupMenuButton<String>(
          padding: EdgeInsets.zero,
          iconSize: 20,
          onSelected: (val) {
            if (val == 'delete') _showDeleteTransactionConfirm(context, notifier, parent.id);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
      ],
    );

    if (children.isEmpty) {
      return Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: Icon(Icons.add_chart_outlined, color: accent, size: 22),
            title: buildTitle(),
            subtitle: buildSubtitle(),
            trailing: buildTrailing(),
            onLongPress: () => _showDeleteTransactionConfirm(context, notifier, parent.id),
          ),
          const Divider(height: 1),
        ],
      );
    }

    return Column(
      children: [
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: Icon(Icons.add_chart_outlined, color: accent, size: 22),
            title: buildTitle(),
            subtitle: buildSubtitle(),
            trailing: buildTrailing(),
            children: children.map((child) => Padding(
              padding: const EdgeInsets.only(left: 48),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                dense: true,
                leading: const Icon(Icons.subdirectory_arrow_right, size: 16, color: Colors.grey),
                title: Text(child.label.isEmpty ? 'Repayment' : child.label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                subtitle: Text(DateFormat('MMM dd').format(child.date), style: const TextStyle(fontSize: 10)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('-₹${child.amount.abs().toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 16, color: Colors.grey),
                      onPressed: () => _showDeleteTransactionConfirm(context, notifier, child.id),
                    ),
                  ],
                ),
              ),
            )).toList(),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }


  void _showDeletePersonConfirm(BuildContext context, MonetaryNotifier notifier, String person) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Person?'),
        content: Text('This will delete all transaction history for $person. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              notifier.deletePerson(person);
              Navigator.pop(context); // Close dialog
              if (Navigator.canPop(context)) Navigator.pop(context); // Close detail screen if open
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteTransactionConfirm(BuildContext context, MonetaryNotifier notifier, String txId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text('Are you sure you want to delete this specific entry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              notifier.deleteTransaction(txId);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: color.withOpacity(0.6), fontSize: 11)),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _showSettleAllConfirm(BuildContext context, MonetaryNotifier notifier, String person, TransactionType type, double amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settle Entire Bucket?'),
        content: Text('This will add a repayment entry for ₹${amount.toStringAsFixed(2)} to clear the balance for $person.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              notifier.settleBucket(person, type);
              Navigator.pop(context);
            },
            child: const Text('Settle All'),
          ),
        ],
      ),
    );
  }

  void _showRepaymentDialog(BuildContext context, MonetaryNotifier notifier, FinancialTransaction originalTx, double bucketRemaining) {
    showDialog(
      context: context,
      builder: (context) => RepaymentDialog(
        originalTx: originalTx, 
        maxAllowed: bucketRemaining > originalTx.amount ? originalTx.amount : bucketRemaining,
      ),
    );
  }

  void _showBulkPaymentDialog(BuildContext context, MonetaryNotifier notifier, String person, TransactionType type, double remaining) {
    showDialog(
      context: context,
      builder: (context) => BulkPaymentDialog(
        personName: person,
        type: type,
        maxAllowed: remaining,
      ),
    );
  }

  void _showMergeConfirm(BuildContext context, MonetaryNotifier notifier, String person) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Merge Balances?'),
        content: const Text('This will offset what you owe against what is owed to you, reducing both buckets by the same amount.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              notifier.mergeBalances(person);
              Navigator.pop(context);
            },
            child: const Text('Merge'),
          ),
        ],
      ),
    );
  }
}

// --- Add Transaction Dialog ---
class AddTransactionDialog extends ConsumerStatefulWidget {
  final String? initialPerson;
  final TransactionType? initialType;

  const AddTransactionDialog({
    super.key, 
    this.initialPerson, 
    this.initialType
  });

  @override
  ConsumerState<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends ConsumerState<AddTransactionDialog> {
  late TextEditingController _amountController;
  late TextEditingController _personController;
  late TextEditingController _labelController;
  late TransactionType _type;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _personController = TextEditingController(text: widget.initialPerson ?? '');
    _labelController = TextEditingController();
    _type = widget.initialType ?? TransactionType.credit;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _personController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Dealing'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(value: TransactionType.credit, label: Text('Lent'), icon: Icon(Icons.arrow_upward)),
                ButtonSegment(value: TransactionType.debit, label: Text('Borrowed'), icon: Icon(Icons.arrow_downward)),
              ],
              selected: {_type},
              onSelectionChanged: (val) => setState(() => _type = val.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _personController,
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(labelText: 'Label (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Date'),
              subtitle: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final amount = double.tryParse(_amountController.text) ?? 0;
            final person = _personController.text.trim();
            if (amount > 0 && person.isNotEmpty) {
              ref.read(monetaryProvider.notifier).addTransaction(FinancialTransaction(
                    personName: person,
                    amount: amount,
                    type: _type,
                    date: _selectedDate,
                    label: _labelController.text,
                  ));
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// --- Repayment Dialog ---
class RepaymentDialog extends ConsumerStatefulWidget {
  final FinancialTransaction originalTx;
  final double maxAllowed;
  const RepaymentDialog({super.key, required this.originalTx, required this.maxAllowed});

  @override
  ConsumerState<RepaymentDialog> createState() => _RepaymentDialogState();
}

class _RepaymentDialogState extends ConsumerState<RepaymentDialog> {
  late TextEditingController _amountController;
  DateTime _paymentDate = DateTime.now();
  String? _error;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.maxAllowed.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isCredit = widget.originalTx.type == TransactionType.credit;
    String actionLabel = isCredit ? "Received Back" : "Paid Back";
    Color accent = isCredit ? Colors.green : Colors.orange;

    return AlertDialog(
      title: Text('Mark $actionLabel'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Person: ${widget.originalTx.personName}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Remaining for this: ₹${widget.maxAllowed.toStringAsFixed(2)}',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            onChanged: (val) {
              final amt = double.tryParse(val) ?? 0;
              if (amt > widget.maxAllowed) {
                setState(() => _error = 'Cannot exceed ₹${widget.maxAllowed.toStringAsFixed(2)}');
              } else {
                setState(() => _error = null);
              }
            },
            decoration: InputDecoration(
              labelText: 'Repayment Amount (₹)',
              border: const OutlineInputBorder(),
              errorText: _error,
              suffixIcon: IconButton(
                icon: const Icon(Icons.restart_alt),
                tooltip: 'Full Amount',
                onPressed: () {
                  _amountController.text = widget.maxAllowed.toStringAsFixed(2);
                  setState(() => _error = null);
                },
              ),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Date'),
            subtitle: Text(DateFormat('yyyy-MM-dd').format(_paymentDate)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _paymentDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) setState(() => _paymentDate = date);
            },
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: accent),
          onPressed: _error != null ? null : () {
            final amount = double.tryParse(_amountController.text) ?? 0;
            if (amount > 0 && amount <= widget.maxAllowed) {
              ref.read(monetaryProvider.notifier).addTransaction(FinancialTransaction(
                    personName: widget.originalTx.personName,
                    amount: -amount,
                    type: widget.originalTx.type,
                    date: _paymentDate,
                    label: 'Repayment of: ${widget.originalTx.label.isEmpty ? "previous deal" : widget.originalTx.label}',
                    parentId: widget.originalTx.id,
                  ));
              Navigator.pop(context);
            }
          },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

// --- Bulk Payment Dialog ---
class BulkPaymentDialog extends ConsumerStatefulWidget {
  final String personName;
  final TransactionType type;
  final double maxAllowed;
  const BulkPaymentDialog({super.key, required this.personName, required this.type, required this.maxAllowed});

  @override
  ConsumerState<BulkPaymentDialog> createState() => _BulkPaymentDialogState();
}

class _BulkPaymentDialogState extends ConsumerState<BulkPaymentDialog> {
  late TextEditingController _amountController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isCredit = widget.type == TransactionType.credit;
    String actionLabel = isCredit ? "Received Payment" : "Make Payment";
    Color accent = isCredit ? Colors.green : Colors.orange;

    return AlertDialog(
      title: Text(actionLabel),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Person: ${widget.personName}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Total Remaining: ₹${widget.maxAllowed.toStringAsFixed(2)}', style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            onChanged: (val) {
              final amt = double.tryParse(val) ?? 0;
              if (amt > widget.maxAllowed) {
                setState(() => _error = 'Cannot exceed total balance');
              } else {
                setState(() => _error = null);
              }
            },
            decoration: InputDecoration(
              labelText: 'Payment Amount (₹)',
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          const Text('This amount will be allocated to open dues starting with the oldest.', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: accent),
          onPressed: _error != null ? null : () {
            final amount = double.tryParse(_amountController.text) ?? 0;
            if (amount > 0 && amount <= widget.maxAllowed) {
              ref.read(monetaryProvider.notifier).bulkSettle(widget.personName, widget.type, amount);
              Navigator.pop(context);
            }
          },
          child: const Text('Allocate Payment'),
        ),
      ],
    );
  }
}

// --- Add EMI Dialog ---
class AddEMIDialog extends ConsumerStatefulWidget {
  final String? initialProvider;
  const AddEMIDialog({super.key, this.initialProvider});

  @override
  ConsumerState<AddEMIDialog> createState() => _AddEMIDialogState();
}

class _AddEMIDialogState extends ConsumerState<AddEMIDialog> {
  late TextEditingController _providerController;
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _countController = TextEditingController(text: '12');
  final _customAmounts = <TextEditingController>[];
  bool _isEven = true;
  TransactionType _type = TransactionType.debit;
  DateTime _startDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _providerController = TextEditingController(text: widget.initialProvider ?? '');
  }

  void _updateCustomControllers() {
    int count = int.tryParse(_countController.text) ?? 0;
    if (count < 1) count = 1;
    if (count > 60) count = 60; // Max 5 years

    while (_customAmounts.length < count) {
      _customAmounts.add(TextEditingController());
    }
    while (_customAmounts.length > count) {
      _customAmounts.removeLast().dispose();
    }

    if (_isEven) {
      double total = double.tryParse(_amountController.text) ?? 0;
      double even = total / count;
      for (var c in _customAmounts) {
        c.text = even.toStringAsFixed(2);
      }
    }
  }

  @override
  void dispose() {
    _providerController.dispose();
    _amountController.dispose();
    _titleController.dispose();
    _countController.dispose();
    for (var c in _customAmounts) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color accent = _type == TransactionType.credit ? Colors.green : Colors.orange;
    
    return AlertDialog(
      title: const Text('New EMI Plan'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(value: TransactionType.credit, label: Text('He Owes Me'), icon: Icon(Icons.arrow_upward)),
                ButtonSegment(value: TransactionType.debit, label: Text('I Owe Him'), icon: Icon(Icons.arrow_downward)),
              ],
              selected: {_type},
              onSelectionChanged: (val) => setState(() => _type = val.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _providerController,
              decoration: const InputDecoration(labelText: 'Provider (Bank, Person, etc.)', border: OutlineInputBorder()),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'EMI Title (e.g., iPhone 16)', border: OutlineInputBorder()),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Total Amount (₹)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onChanged: (_) { if (_isEven) setState(() => _updateCustomControllers()); },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _countController,
              decoration: const InputDecoration(labelText: 'Number of Installments', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() => _updateCustomControllers()),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Even Distribution'),
              subtitle: const Text('Split total amount equally'),
              value: _isEven,
              onChanged: (val) => setState(() {
                _isEven = val;
                _updateCustomControllers();
              }),
            ),
            if (!_isEven) ...[
              const Divider(),
              const Text('Custom Monthly Amounts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              ...List.generate(_customAmounts.length, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: TextField(
                  controller: _customAmounts[i],
                  decoration: InputDecoration(
                    labelText: 'Month ${i + 1} (₹)',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
              )),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: accent),
          onPressed: () {
            final total = double.tryParse(_amountController.text) ?? 0;
            final count = int.tryParse(_countController.text) ?? 0;
            final title = _titleController.text.trim();
            final provider = _providerController.text.trim();
            
            if (total > 0 && count > 0 && title.isNotEmpty && provider.isNotEmpty) {
              final customVals = _isEven ? null : _customAmounts.map((c) => double.tryParse(c.text) ?? 0.0).toList();
              
              // Validate custom sum
              if (customVals != null) {
                double sum = customVals.fold(0, (a, b) => a + b);
                if ((sum - total).abs() > 0.1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Custom amounts (₹$sum) must equal total (₹$total)'))
                  );
                  return;
                }
              }

              ref.read(emiProvider.notifier).addEMIPlan(
                provider: provider,
                title: title,
                totalAmount: total,
                installmentCount: count,
                startDate: _startDate,
                type: _type == TransactionType.credit ? 'credit' : 'debit',
                customAmounts: customVals,
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Create EMI'),
        ),
      ],
    );
  }
}
