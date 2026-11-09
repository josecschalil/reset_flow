import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:reset_flow/models/financial_transaction.dart';
import 'package:reset_flow/models/account_balance.dart';
import 'package:reset_flow/providers/monetary_provider.dart';
import 'package:reset_flow/providers/emi_provider.dart';
import 'package:reset_flow/models/emi_model.dart';
import 'package:reset_flow/screens/emi_details_screen.dart';
import 'package:reset_flow/screens/cash_requirements_screen.dart';
import 'package:reset_flow/providers/expense_provider.dart';
import 'package:reset_flow/models/expense.dart';
import 'package:reset_flow/widgets/expense_dialogs.dart';
import 'package:reset_flow/screens/category_expense_detail_screen.dart';
import 'package:reset_flow/widgets/daily_spend_chart.dart';

class MonetaryDealingsScreen extends ConsumerStatefulWidget {
  const MonetaryDealingsScreen({super.key});

  @override
  ConsumerState<MonetaryDealingsScreen> createState() =>
      _MonetaryDealingsScreenState();
}

// ── Palette Complementing Cash Requirements Screen ─────────────────────────
const Color _primary = Color(0xFF1E3A5F); // Ink Navy
const Color _primarySoft = Color(0xFFEEF2F7);
const Color _bg = Color(0xFFF5F6F8);
const Color _border = Color(0xFFDFE3E9);
const Color _divider = Color(0xFFEBEEF2);
const Color _textPrimary = Color(0xFF14202E);
const Color _textMuted = Color(0xFF5F6B7A);
const Color _textSubtle = Color(0xFF8892A0);
const Color _danger = Color(0xFFB4352F);
const Color _dangerLight = Color(0xFFFBEFEE);
const Color _emerald = Color(0xFF2F6B4F);
const Color _emeraldLight = Color(0xFFECF4EF);

const LinearGradient _brandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF1E3A5F), Color(0xFF2F5580)],
);

const List<BoxShadow> _cardShadow = [
  BoxShadow(
    color: Color(0x0A14202E),
    blurRadius: 14,
    offset: Offset(0, 4),
  ),
  BoxShadow(
    color: Color(0x0614202E),
    blurRadius: 2,
    offset: Offset(0, 1),
  ),
];

const List<LinearGradient> _avatarGradients = [
  LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E3A5F), Color(0xFF2F5580)],
  ),
  LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF28536B), Color(0xFF3E6F8E)],
  ),
  LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF38405F), Color(0xFF4F5A82)],
  ),
  LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2F6B4F), Color(0xFF428E6A)],
  ),
  LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFA8690F), Color(0xFFC7811B)],
  ),
  LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8A3C52), Color(0xFFA84E69)],
  ),
];

LinearGradient _avatarGradientFor(String name) {
  if (name.isEmpty) return _avatarGradients[0];
  final code = name.codeUnits.fold(0, (acc, c) => acc + c);
  return _avatarGradients[code % _avatarGradients.length];
}

class _MonetaryDealingsScreenState
    extends ConsumerState<MonetaryDealingsScreen> {
  late final PageController _summaryPageController;
  int _summaryPage = 0;

  @override
  void initState() {
    super.initState();
    _summaryPageController = PageController();
  }

  @override
  void dispose() {
    _summaryPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(monetaryProvider);
    final notifier = ref.read(monetaryProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Finance',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            color: _textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Personal ledger & liquidity overview',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w400,
                            color: _textMuted,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: _border),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A14202E),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.receipt_long_rounded,
                            size: 19, color: _primary),
                        tooltip: 'Cash Requirements',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CashRequirementsScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const TabBar(
                labelColor: _primary,
                unselectedLabelColor: _textMuted,
                indicatorColor: _primary,
                indicatorSize: TabBarIndicatorSize.label,
                indicatorWeight: 3,
                labelStyle:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                unselectedLabelStyle:
                    TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                dividerColor: _border,
                tabs: [
                  Tab(text: 'Ledger'),
                  Tab(text: 'Expenses'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildLedgerView(state, notifier, colorScheme),
                    _buildExpensesView(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLedgerView(
      MonetaryState state, MonetaryNotifier notifier, ColorScheme colorScheme) {
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

                // 4. People List (header moved inside)
                _buildPeopleList(state, notifier, colorScheme),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
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
            child: _buildSwipeableMonthCard(
                expenseState, expenseNotifier, colorScheme),
          ),
          if (expenseState.isCurrentMonth)
            SliverToBoxAdapter(
              child: _buildExpenseActionCards(expenseNotifier, colorScheme),
            ),
          // Daily spend chart for selected month
          if (expenseState.selectedMonthExpenses.isNotEmpty)
            SliverToBoxAdapter(
              child: DailySpendChart(
                expenses: expenseState.selectedMonthExpenses,
                title: 'DAILY SPENDING THIS MONTH',
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text(
                'SPENDING BY CATEGORY',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: _textMuted,
                ),
              ),
            ),
          ),
          _buildExpenseGrid(expenseState, expenseNotifier, colorScheme),
        ],
      ),
    );
  }

  Widget _buildActionCards(BuildContext context, MonetaryNotifier notifier,
      ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 4),
      child: Row(
        children: [
          Expanded(
            child: _buildActionCard(
              context,
              'New Dealing',
              Icons.handshake,
              () => _showAddTransactionDialog(context, notifier),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _buildActionCard(
              context,
              'Add EMI',
              Icons.credit_card,
              () => _showAddEMIDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: _cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: _primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: _primary, size: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEMISection(ColorScheme colorScheme) {
    final emiState = ref.watch(emiProvider);
    if (emiState.plans.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Text(
              'EMI & LIABILITIES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: _textMuted,
              ),
            ),
          ),
          ...emiState.plans.map((plan) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _border),
                    boxShadow: _cardShadow,
                  ),
                  child: _buildEMIPlanTile(
                      context, plan, ref.read(monetaryProvider.notifier), ref),
                ),
              )),
        ],
      ),
    );
  }

  void _showAddEMIDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const AddEMIDialog());
  }

  Widget _buildEMIPlanTile(BuildContext context, EMIPlan plan,
      MonetaryNotifier notifier, WidgetRef ref) {
    final installments = ref.watch(emiProvider).installments[plan.id] ?? [];
    int paidCount = installments.where((i) => i.isPaid).length;
    double paidAmount =
        installments.where((i) => i.isPaid).fold(0, (sum, i) => sum + i.amount);
    double progress =
        installments.isEmpty ? 0 : paidCount / installments.length;

    final isCredit = plan.type == 'credit';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => EMIDetailScreen(planId: plan.id))),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 42,
                    height: 42,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 3.5,
                      backgroundColor: _divider,
                      valueColor: AlwaysStoppedAnimation(
                          isCredit ? _emerald : _primary),
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: _textPrimary,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plan.provider,
                      style: const TextStyle(fontSize: 11.5, color: _textMuted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${(plan.totalAmount - paidAmount).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: isCredit ? _emerald : _textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'REMAINING',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: _textSubtle,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, size: 18, color: _textSubtle),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryDashboard(
      MonetaryNotifier notifier, ColorScheme colorScheme) {
    return Column(
      children: [
        SizedBox(
          height: 286,
          child: PageView(
            controller: _summaryPageController,
            onPageChanged: (index) => setState(() => _summaryPage = index),
            children: [
              _buildNetWorthCard(notifier, colorScheme),
              _buildCashPlannerCard(notifier),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            2,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
              width: _summaryPage == index ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _summaryPage == index ? _primary : _border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNetWorthCard(
      MonetaryNotifier notifier, ColorScheme colorScheme) {
    final emiState = ref.watch(emiProvider);
    double credit = notifier.totalCredit;
    double debit = notifier.totalDebit;
    double net = notifier.netBalance;

    double emiRemainingLiability = 0;
    double emiRemainingAsset = 0;

    for (var plan in emiState.plans) {
      final insts = emiState.installments[plan.id] ?? [];
      double unpaid =
          insts.where((i) => !i.isPaid).fold(0, (sum, i) => sum + i.amount);
      if (plan.type == 'debit') {
        emiRemainingLiability += unpaid;
      } else {
        emiRemainingAsset += unpaid;
      }
    }

    double totalNet = net + emiRemainingAsset - emiRemainingLiability;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 20, 24, 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: _brandGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x331E3A5F),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x1AFFFFFF),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -32,
            child: Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x12FFFFFF),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: const Color(0x33FFFFFF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'TOTAL NET WORTH',
                          style: TextStyle(
                            color: Color(0xCCFFFFFF),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0x26FFFFFF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF6EE7B7),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '₹${totalNet.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 34,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Current Cash: ₹${net.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xB3FFFFFF),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0x1AFFFFFF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.arrow_upward_rounded,
                                    size: 13, color: Color(0xFF6EE7B7)),
                                SizedBox(width: 4),
                                Text(
                                  'ASSETS',
                                  style: TextStyle(
                                    color: Color(0xCCFFFFFF),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '₹${(credit + emiRemainingAsset).toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: const Color(0x2EFFFFFF),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.arrow_downward_rounded,
                                    size: 13, color: Color(0xFFFCA5A5)),
                                SizedBox(width: 4),
                                Text(
                                  'LIABILITIES',
                                  style: TextStyle(
                                    color: Color(0xCCFFFFFF),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '₹${(debit + emiRemainingLiability).toStringAsFixed(0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashPlannerCard(MonetaryNotifier notifier) {
    final emiState = ref.watch(emiProvider);
    final accounts = ref.watch(monetaryProvider).accounts;
    final now = DateTime.now();
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    double emiNeededThisMonth = 0;
    for (final plan in emiState.plans.where((plan) => plan.type == 'debit')) {
      for (final installment in emiState.installments[plan.id] ?? []) {
        if (installment.isPaid) continue;
        if (!installment.dueDate.isAfter(monthEnd)) {
          emiNeededThisMonth += installment.amount;
        }
      }
    }

    final personalDealingsNeeded =
        notifier.totalDebit > 0 ? notifier.totalDebit : 0.0;

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const CashRequirementsScreen())),
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 20, 24, 14),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF162D4A), Color(0xFF24446A)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2614202E),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -24,
              top: -24,
              child: Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x14FFFFFF),
                ),
              ),
            ),
            Positioned(
              left: -20,
              bottom: -32,
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x0EFFFFFF),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: const Color(0x33FFFFFF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.insights_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'CASH PLANNER',
                        style: TextStyle(
                          color: Color(0xCCFFFFFF),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      Tooltip(
                        message: 'Manage account balances',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showAccountBalancesDialog(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: const Color(0x26FFFFFF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.account_balance_wallet_outlined,
                                      size: 12, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'Accounts',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 12, color: Color(0x99FFFFFF)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '₹${notifier.totalAccountBalance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 30,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        accounts.isEmpty
                            ? 'Tap to manage account balances'
                            : accounts.map((account) => account.name).join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xB3FFFFFF),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0x1AFFFFFF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildCashRequirement(
                            'EMI THIS MONTH',
                            emiNeededThisMonth,
                            Icons.calendar_month_outlined,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: const Color(0x2EFFFFFF),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildCashRequirement(
                            'PERSONAL DUES',
                            personalDealingsNeeded,
                            Icons.people_outline_rounded,
                          ),
                        ),
                      ],
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

  Widget _buildCashRequirement(String label, double amount, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0x22FFFFFF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xCCFFFFFF),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '₹${amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAccountBalancesDialog(BuildContext context) {
    showDialog(
        context: context, builder: (context) => const AccountBalancesDialog());
  }

  Widget _buildPeopleList(
      MonetaryState state, MonetaryNotifier notifier, ColorScheme colorScheme) {
    final summary = notifier.personSummary;

    // Header added here so we can include it safely
    const header = SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
        child: Text(
          'PEOPLE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: _textMuted,
          ),
        ),
      ),
    );

    if (summary.isEmpty) {
      return SliverMainAxisGroup(slivers: [
        header,
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _border),
                  boxShadow: _cardShadow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: _primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.people_outline_rounded,
                          color: _primary, size: 28),
                    ),
                    const SizedBox(height: 16),
                    const Text('No Dealings Yet',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: _textPrimary)),
                    const SizedBox(height: 8),
                    const Text(
                      'Use the action cards above\nto add your first dealing.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: _textMuted,
                          fontSize: 13,
                          height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]);
    }

    return SliverMainAxisGroup(slivers: [
      header,
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              String person = summary.keys.elementAt(index);
              double pCredit = summary[person]!['credit']!;
              double pDebit = summary[person]!['debit']!;
              final isSettled = pCredit == 0 && pDebit == 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _border),
                  boxShadow: _cardShadow,
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: _avatarGradientFor(person),
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1414202E),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          person.isEmpty ? '?' : person[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      person,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5,
                        color: _textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: isSettled
                          ? Wrap(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: _primarySoft,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: _border),
                                  ),
                                  child: const Text('SETTLED',
                                      style: TextStyle(
                                          color: _textMuted,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 9.5,
                                          letterSpacing: 0.6)),
                                ),
                              ],
                            )
                          : Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                if (pCredit > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3.5),
                                    decoration: BoxDecoration(
                                      color: _emeraldLight,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: const Color(0x332F6B4F)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.arrow_upward_rounded,
                                            size: 11, color: _emerald),
                                        const SizedBox(width: 3),
                                        Text('₹${pCredit.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                                color: _emerald,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 11.5)),
                                      ],
                                    ),
                                  ),
                                if (pDebit > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3.5),
                                    decoration: BoxDecoration(
                                      color: _dangerLight,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: const Color(0x33B4352F)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.arrow_downward_rounded,
                                            size: 11, color: _danger),
                                        const SizedBox(width: 3),
                                        Text('₹${pDebit.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                                color: _danger,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 11.5)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: _textSubtle),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: _border),
                      ),
                      elevation: 4,
                      onSelected: (val) {
                        if (val == 'lent') {
                          _showAddTransactionDialog(context, notifier,
                              initialPerson: person,
                              initialType: TransactionType.credit);
                        } else if (val == 'borrowed') {
                          _showAddTransactionDialog(context, notifier,
                              initialPerson: person,
                              initialType: TransactionType.debit);
                        } else if (val == 'delete') {
                          _showDeletePersonConfirm(person, notifier);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'lent',
                          child: Row(
                            children: [
                              Icon(Icons.add_circle_outline_rounded,
                                  color: _emerald, size: 18),
                              SizedBox(width: 10),
                              Text(
                                'Quick Lent',
                                style: TextStyle(
                                  color: _textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'borrowed',
                          child: Row(
                            children: [
                              Icon(Icons.remove_circle_outline_rounded,
                                  color: _danger, size: 18),
                              SizedBox(width: 10),
                              Text(
                                'Quick Borrowed',
                                style: TextStyle(
                                  color: _textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded,
                                  color: _danger, size: 18),
                              SizedBox(width: 10),
                              Text(
                                'Delete Person',
                                style: TextStyle(
                                  color: _danger,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _showPersonDetail(person),
                    onLongPress: () => _showDeletePersonConfirm(person, notifier),
                  ),
                ),
              );
            },
            childCount: summary.length,
          ),
        ),
      ),
    ]);
  }

  void _showPersonDetail(String person) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => PersonDetailScreen(personName: person)),
    );
  }

  void _showDeletePersonConfirm(String person, MonetaryNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Person?'),
        content: Text(
            'This will delete all transaction history for $person. This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              notifier.deletePerson(person);
              Navigator.pop(context);
            },
            child: Text('Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionDialog(
      BuildContext context, MonetaryNotifier notifier,
      {String? initialPerson, TransactionType? initialType}) {
    showDialog(
      context: context,
      builder: (context) => AddTransactionDialog(
        initialPerson: initialPerson,
        initialType: initialType,
      ),
    );
  }

  // --- EXPENSES UI HELPERS ---

  Widget _buildSwipeableMonthCard(
      ExpenseState state, ExpenseNotifier notifier, ColorScheme colorScheme) {
    final sel = state.selectedMonth;
    final monthLabel = DateFormat('MMMM yyyy').format(sel);
    final total = state.totalForSelectedMonth;
    final txCount = state.selectedMonthExpenses.length;

    final now = DateTime.now();
    final isCurrentMonth = state.isCurrentMonth;
    // Can go back if there are older months in the data
    final canGoBack = state.availableMonths
        .any((m) => m.isBefore(DateTime(sel.year, sel.month)));

    double todayTotal = 0;
    if (isCurrentMonth) {
      final todayExpenses = state.selectedMonthExpenses.where((e) =>
          e.date.year == now.year &&
          e.date.month == now.month &&
          e.date.day == now.day);
      todayTotal = todayExpenses.fold(0.0, (sum, e) => sum + e.amount);
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 20, 24, 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: _brandGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x331E3A5F),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x1AFFFFFF),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -32,
            child: Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x12FFFFFF),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                // Month navigation row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: canGoBack
                            ? () => notifier.goToPreviousMonth()
                            : null,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: canGoBack
                                ? const Color(0x24FFFFFF)
                                : const Color(0x0FFFFFFF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: canGoBack
                                  ? const Color(0x33FFFFFF)
                                  : const Color(0x14FFFFFF),
                            ),
                          ),
                          child: Icon(
                            Icons.chevron_left_rounded,
                            color: canGoBack ? Colors.white : Colors.white30,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0x26FFFFFF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0x33FFFFFF)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  size: 11, color: Colors.white70),
                              const SizedBox(width: 6),
                              Text(
                                monthLabel.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isCurrentMonth) ...[
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0x1AFFFFFF),
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: const Color(0x24FFFFFF)),
                            ),
                            child: const Text(
                              'Archive',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isCurrentMonth
                            ? null
                            : () => notifier.goToNextMonth(),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: !isCurrentMonth
                                ? const Color(0x24FFFFFF)
                                : const Color(0x0FFFFFFF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: !isCurrentMonth
                                  ? const Color(0x33FFFFFF)
                                  : const Color(0x14FFFFFF),
                            ),
                          ),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            color: !isCurrentMonth
                                ? Colors.white
                                : Colors.white30,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'TOTAL MONTHLY SPEND',
                  style: TextStyle(
                    color: Color(0xCCFFFFFF),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$txCount transaction${txCount == 1 ? '' : 's'} this month',
                  style: const TextStyle(
                    color: Color(0xB3FFFFFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isCurrentMonth) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6.5),
                    decoration: BoxDecoration(
                      color: const Color(0x1EFFFFFF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0x2EFFFFFF)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.today_rounded,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Today: ₹${todayTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseActionCards(
      ExpenseNotifier notifier, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildActionCard(
              context,
              'Add Expense',
              Icons.receipt_long,
              () => _showAddExpenseDialog(context, notifier),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _buildActionCard(
              context,
              'Categories',
              Icons.category_outlined,
              () => _showManageCategoriesDialog(context, notifier),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseGrid(
      ExpenseState state, ExpenseNotifier notifier, ColorScheme colorScheme) {
    if (state.categories.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text('No categories found.',
              style: TextStyle(color: Colors.grey.shade500)),
        ),
      );
    }

    final monthExpenses = state.selectedMonthExpenses;
    final totalMonthly = monthExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final now = DateTime.now();

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.95,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final category = state.categories[index];
            final categoryExpenses = monthExpenses
                .where((e) => e.categoryId == category.id)
                .toList();
            
            final todayExpenses = categoryExpenses.where((e) =>
                e.date.year == now.year &&
                e.date.month == now.month &&
                e.date.day == now.day);

            final double total =
                categoryExpenses.fold(0.0, (sum, e) => sum + e.amount);
            final double totalShare =
                totalMonthly > 0 ? total / totalMonthly : 0;
            final double todayTotal = 
                todayExpenses.fold(0.0, (sum, e) => sum + e.amount);

            return _buildCategoryCard(
                category, total, categoryExpenses.length, totalShare, todayTotal);
          },
          childCount: state.categories.length,
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
      ExpenseCategory category, double total, int count, double share, double todayTotal) {
    final categoryColor = Color(category.colorValue);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CategoryExpenseDetailScreen(category: category),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    IconData(category.iconCodePoint,
                        fontFamily: 'MaterialIcons'),
                    color: categoryColor,
                    size: 22,
                  ),
                ),
                if (share > 0)
                  Text(
                    '${(share * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: categoryColor,
                    ),
                  )
                else
                  Text(
                    '0%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade400,
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              category.name,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF1A1A2E)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${total.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: total > 0 ? const Color(0xFF1A1A2E) : Colors.grey.shade400,
                  ),
                ),
                Text(
                  'Today: ₹${todayTotal.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: share > 0 ? share : 0,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
                minHeight: 4,
              ),
            ),
          ],
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
    final personTxs =
        state.transactions.where((tx) => tx.personName == personName).toList();
    final colorScheme = Theme.of(context).colorScheme;

    final creditTxs =
        personTxs.where((tx) => tx.type == TransactionType.credit).toList();
    final debitTxs =
        personTxs.where((tx) => tx.type == TransactionType.debit).toList();

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
              onPressed: () =>
                  _showDeletePersonConfirm(context, notifier, personName),
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
            _buildBucketList(context, personName, TransactionType.credit,
                notifier, colorScheme, Colors.green, ref),
            _buildBucketList(context, personName, TransactionType.debit,
                notifier, colorScheme, Colors.orange, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildBucketList(
      BuildContext context,
      String person,
      TransactionType type,
      MonetaryNotifier notifier,
      ColorScheme colorScheme,
      Color accent,
      WidgetRef ref) {
    final allTxs = notifier.state.transactions;
    final txs = allTxs
        .where((tx) => tx.personName == person && tx.type == type)
        .toList();

    double totalLent = txs
        .where((tx) => tx.amount > 0)
        .fold(0.0, (sum, tx) => sum + tx.amount);
    double totalRepaid = txs
        .where((tx) => tx.amount < 0)
        .fold(0.0, (sum, tx) => sum + tx.amount)
        .abs();
    double remaining = totalLent - totalRepaid;

    final items = txs
        .where((tx) =>
            tx.amount > 0 ||
            (tx.amount < 0 &&
                (tx.parentId == null || !txs.any((p) => p.id == tx.parentId))))
        .toList();

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
                            Text('REMAINING',
                                style: TextStyle(
                                    color: accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2)),
                            Text('₹${remaining.toStringAsFixed(2)}',
                                style: TextStyle(
                                    color: accent,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),
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
                              onPressed: () => _showBulkPaymentDialog(
                                  context, notifier, person, type, remaining),
                              icon: const Icon(Icons.payment, size: 16),
                              label: const Text('Add Payment',
                                  style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: accent,
                                side: BorderSide(color: accent),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                minimumSize: const Size(0, 36),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _showSettleAllConfirm(
                                  context, notifier, person, type, remaining),
                              icon: const Icon(Icons.check_circle_outline,
                                  size: 16),
                              label: const Text('Settle',
                                  style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
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
                  _buildMiniStat(
                      'Total Dealing',
                      '₹${totalLent.toStringAsFixed(0)}',
                      colorScheme.onSurfaceVariant),
                  _buildMiniStat('Total Settled',
                      '₹${totalRepaid.toStringAsFixed(0)}', Colors.grey),
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
                      return _buildOrphanRepayment(
                          context, notifier, item, accent);
                    }
                    return _buildParentDealing(
                        context, notifier, item, txs, accent);
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildOrphanRepayment(BuildContext context, MonetaryNotifier notifier,
      FinancialTransaction item, Color accent) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          leading:
              const Icon(Icons.payment_outlined, color: Colors.grey, size: 20),
          title: Text(item.label.isEmpty ? 'Misc Payment' : item.label,
              style:
                  const TextStyle(fontStyle: FontStyle.italic, fontSize: 14)),
          subtitle: Text(DateFormat('MMM dd').format(item.date),
              style: const TextStyle(fontSize: 11)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('-₹${item.amount.abs().toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                      fontSize: 14)),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Colors.redAccent),
                onPressed: () =>
                    _showDeleteTransactionConfirm(context, notifier, item.id),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildParentDealing(
      BuildContext context,
      MonetaryNotifier notifier,
      FinancialTransaction parent,
      List<FinancialTransaction> allTxs,
      Color accent) {
    final children = allTxs.where((tx) => tx.parentId == parent.id).toList();
    double parentRemaining =
        parent.amount - children.fold(0.0, (sum, tx) => sum + tx.amount.abs());

    Widget buildTitle() => Text(
          parent.label.isEmpty ? 'Dealing' : parent.label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        );

    Widget buildSubtitle() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(DateFormat('MMM dd').format(parent.date),
                style: const TextStyle(fontSize: 11)),
            if (parentRemaining > 0)
              Text('Original: ₹${parent.amount.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey)),
            if (parentRemaining <= 0)
              const Text('FULLY SETTLED',
                  style: TextStyle(
                      fontSize: 9,
                      color: Colors.green,
                      fontWeight: FontWeight.bold)),
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
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: accent),
                  ),
                  const Text('REMAINING',
                      style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey)),
                ] else ...[
                  Text(
                    '₹${parent.amount.toStringAsFixed(0)}/${parent.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.green),
                  ),
                  const Text('SETTLED',
                      style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.green)),
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
                onPressed: () => _showRepaymentDialog(
                    context, notifier, parent, parentRemaining),
              ),
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              iconSize: 20,
              onSelected: (val) {
                if (val == 'delete')
                  _showDeleteTransactionConfirm(context, notifier, parent.id);
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: Icon(Icons.add_chart_outlined, color: accent, size: 22),
            title: buildTitle(),
            subtitle: buildSubtitle(),
            trailing: buildTrailing(),
            onLongPress: () =>
                _showDeleteTransactionConfirm(context, notifier, parent.id),
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
            children: children
                .map((child) => Padding(
                      padding: const EdgeInsets.only(left: 48),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        dense: true,
                        leading: const Icon(Icons.subdirectory_arrow_right,
                            size: 16, color: Colors.grey),
                        title: Text(
                            child.label.isEmpty ? 'Repayment' : child.label,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13)),
                        subtitle: Text(DateFormat('MMM dd').format(child.date),
                            style: const TextStyle(fontSize: 10)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('-₹${child.amount.abs().toStringAsFixed(2)}',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 13)),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 16, color: Colors.grey),
                              onPressed: () => _showDeleteTransactionConfirm(
                                  context, notifier, child.id),
                            ),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  void _showDeletePersonConfirm(
      BuildContext context, MonetaryNotifier notifier, String person) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Person?'),
        content: Text(
            'This will delete all transaction history for $person. This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              notifier.deletePerson(person);
              Navigator.pop(context); // Close dialog
              if (Navigator.canPop(context))
                Navigator.pop(context); // Close detail screen if open
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteTransactionConfirm(
      BuildContext context, MonetaryNotifier notifier, String txId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content:
            const Text('Are you sure you want to delete this specific entry?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
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
        Text(label,
            style: TextStyle(color: color.withOpacity(0.6), fontSize: 11)),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _showSettleAllConfirm(BuildContext context, MonetaryNotifier notifier,
      String person, TransactionType type, double amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settle Entire Bucket?'),
        content: Text(
            'This will add a repayment entry for ₹${amount.toStringAsFixed(2)} to clear the balance for $person.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
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

  void _showRepaymentDialog(BuildContext context, MonetaryNotifier notifier,
      FinancialTransaction originalTx, double bucketRemaining) {
    showDialog(
      context: context,
      builder: (context) => RepaymentDialog(
        originalTx: originalTx,
        maxAllowed: bucketRemaining > originalTx.amount
            ? originalTx.amount
            : bucketRemaining,
      ),
    );
  }

  void _showBulkPaymentDialog(BuildContext context, MonetaryNotifier notifier,
      String person, TransactionType type, double remaining) {
    showDialog(
      context: context,
      builder: (context) => BulkPaymentDialog(
        personName: person,
        type: type,
        maxAllowed: remaining,
      ),
    );
  }

  void _showMergeConfirm(
      BuildContext context, MonetaryNotifier notifier, String person) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Merge Balances?'),
        content: const Text(
            'This will offset what you owe against what is owed to you, reducing both buckets by the same amount.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
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

  const AddTransactionDialog({super.key, this.initialPerson, this.initialType});

  @override
  ConsumerState<AddTransactionDialog> createState() =>
      _AddTransactionDialogState();
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
    final isLent = _type == TransactionType.credit;
    final accentColor = isLent ? _emerald : _danger;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: _border),
      ),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _primarySoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.handshake_rounded,
                            color: _primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New Dealing',
                              style: TextStyle(
                                fontSize: 17.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                color: _textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Record money lent or borrowed',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w400,
                                color: _textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close_rounded,
                          size: 20, color: _textMuted),
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // ── Type Toggle (Lent vs Borrowed)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      // Lent (Credit)
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () =>
                                setState(() => _type = TransactionType.credit),
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color:
                                    isLent ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: isLent
                                    ? Border.all(
                                        color: const Color(0x332F6B4F))
                                    : null,
                                boxShadow: isLent
                                    ? const [
                                        BoxShadow(
                                          color: Color(0x0F14202E),
                                          blurRadius: 6,
                                          offset: Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_upward_rounded,
                                    size: 15,
                                    color: isLent ? _emerald : _textMuted,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Lent (Given)',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: isLent
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: isLent ? _emerald : _textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Borrowed (Debit)
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () =>
                                setState(() => _type = TransactionType.debit),
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color:
                                    !isLent ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: !isLent
                                    ? Border.all(
                                        color: const Color(0x33B4352F))
                                    : null,
                                boxShadow: !isLent
                                    ? const [
                                        BoxShadow(
                                          color: Color(0x0F14202E),
                                          blurRadius: 6,
                                          offset: Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.arrow_downward_rounded,
                                    size: 15,
                                    color: !isLent ? _danger : _textMuted,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Borrowed (Taken)',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: !isLent
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: !isLent ? _danger : _textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Amount Hero Input
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AMOUNT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: _textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '₹',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: _amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: accentColor,
                              ),
                              decoration: const InputDecoration(
                                hintText: '0',
                                hintStyle: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: _textSubtle,
                                ),
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Contact / Name Input
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 6),
                      child: Text(
                        'PERSON / CONTACT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: _textMuted,
                        ),
                      ),
                    ),
                    TextField(
                      controller: _personController,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _bg,
                        hintText: 'Enter contact name',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: _textSubtle,
                        ),
                        prefixIcon: const Icon(
                          Icons.person_outline_rounded,
                          color: _primary,
                          size: 19,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: _primary, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Date Selector
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 6),
                      child: Text(
                        'DATE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: _textMuted,
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setState(() => _selectedDate = date);
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: _bg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  size: 18, color: _primary),
                              const SizedBox(width: 10),
                              Text(
                                DateFormat('MMM dd, yyyy').format(_selectedDate),
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: _textPrimary,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _border),
                                ),
                                child: const Text(
                                  'Change',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Note / Label Input (optional)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 6),
                      child: Text(
                        'NOTE (OPTIONAL)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: _textMuted,
                        ),
                      ),
                    ),
                    TextField(
                      controller: _labelController,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _textPrimary,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _bg,
                        hintText: 'e.g., Dinner split, Rent share',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: _textSubtle,
                        ),
                        prefixIcon: const Icon(
                          Icons.sticky_note_2_outlined,
                          color: _textMuted,
                          size: 19,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: _primary, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // ── Action Buttons
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: const BorderSide(color: _border),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: _textMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 6,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          final amount =
                              double.tryParse(_amountController.text) ?? 0;
                          final person = _personController.text.trim();
                          if (amount > 0 && person.isNotEmpty) {
                            ref
                                .read(monetaryProvider.notifier)
                                .addTransaction(FinancialTransaction(
                                  personName: person,
                                  amount: amount,
                                  type: _type,
                                  date: _selectedDate,
                                  label: _labelController.text,
                                ));
                            Navigator.pop(context);
                          }
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_rounded, size: 17),
                            SizedBox(width: 6),
                            Text(
                              'Save Dealing',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Repayment Dialog ---
class RepaymentDialog extends ConsumerStatefulWidget {
  final FinancialTransaction originalTx;
  final double maxAllowed;
  const RepaymentDialog(
      {super.key, required this.originalTx, required this.maxAllowed});

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
    _amountController =
        TextEditingController(text: widget.maxAllowed.toStringAsFixed(2));
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
                setState(() => _error =
                    'Cannot exceed ₹${widget.maxAllowed.toStringAsFixed(2)}');
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
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: accent),
          onPressed: _error != null
              ? null
              : () {
                  final amount = double.tryParse(_amountController.text) ?? 0;
                  if (amount > 0 && amount <= widget.maxAllowed) {
                    ref
                        .read(monetaryProvider.notifier)
                        .addTransaction(FinancialTransaction(
                          personName: widget.originalTx.personName,
                          amount: -amount,
                          type: widget.originalTx.type,
                          date: _paymentDate,
                          label:
                              'Repayment of: ${widget.originalTx.label.isEmpty ? "previous deal" : widget.originalTx.label}',
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
  const BulkPaymentDialog(
      {super.key,
      required this.personName,
      required this.type,
      required this.maxAllowed});

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
          Text('Person: ${widget.personName}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Total Remaining: ₹${widget.maxAllowed.toStringAsFixed(2)}',
              style: TextStyle(color: Theme.of(context).colorScheme.outline)),
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
          const Text(
              'This amount will be allocated to open dues starting with the oldest.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: accent),
          onPressed: _error != null
              ? null
              : () {
                  final amount = double.tryParse(_amountController.text) ?? 0;
                  if (amount > 0 && amount <= widget.maxAllowed) {
                    ref
                        .read(monetaryProvider.notifier)
                        .bulkSettle(widget.personName, widget.type, amount);
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
  final EMIPlan? existingPlan;
  final List<EMIInstallment>? existingInstallments;

  const AddEMIDialog({
    super.key,
    this.initialProvider,
    this.existingPlan,
    this.existingInstallments,
  });

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
  DateTime _startDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final plan = widget.existingPlan;
    if (plan != null) {
      _providerController = TextEditingController(text: plan.provider);
      _amountController.text = plan.totalAmount.toStringAsFixed(0);
      _titleController.text = plan.title;
      _countController.text = plan.installmentCount.toString();
      _startDate = plan.startDate;

      if (widget.existingInstallments != null &&
          widget.existingInstallments!.isNotEmpty) {
        final sorted = [...widget.existingInstallments!]
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

        final firstAmt = sorted.first.amount;
        final hasVariation =
            sorted.any((i) => (i.amount - firstAmt).abs() > 1.0);
        if (hasVariation) {
          _isEven = false;
        }

        for (var inst in sorted) {
          _customAmounts.add(
            TextEditingController(text: inst.amount.toStringAsFixed(2)),
          );
        }
      } else {
        _updateCustomControllers();
      }
    } else {
      _providerController =
          TextEditingController(text: widget.initialProvider ?? '');
    }
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
    final total = double.tryParse(_amountController.text) ?? 0;
    final count = int.tryParse(_countController.text) ?? 0;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: _border),
      ),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _primarySoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.credit_card_rounded,
                            color: _primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.existingPlan != null
                                  ? 'Edit EMI Plan'
                                  : 'New EMI Plan',
                              style: const TextStyle(
                                fontSize: 17.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                color: _textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.existingPlan != null
                                  ? 'Update installment schedule & details'
                                  : 'Set up installment schedule & dues',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w400,
                                color: _textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close_rounded,
                          size: 20, color: _textMuted),
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // ── Total Amount Hero Input
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL AMOUNT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: _textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            '₹',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: _primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: _amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: _primary,
                              ),
                              decoration: const InputDecoration(
                                hintText: '0',
                                hintStyle: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: _textSubtle,
                                ),
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (_) {
                                if (_isEven) {
                                  setState(() => _updateCustomControllers());
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Provider (Bank / Person)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 6),
                      child: Text(
                        'PROVIDER / LENDER',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: _textMuted,
                        ),
                      ),
                    ),
                    TextField(
                      controller: _providerController,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _bg,
                        hintText: 'e.g. HDFC Bank, Apple, Friend',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: _textSubtle,
                        ),
                        prefixIcon: const Icon(
                          Icons.account_balance_rounded,
                          color: _primary,
                          size: 19,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: _primary, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── EMI Title
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 6),
                      child: Text(
                        'PLAN TITLE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: _textMuted,
                        ),
                      ),
                    ),
                    TextField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _bg,
                        hintText: 'e.g. iPhone 16 Pro, Bike Loan',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: _textSubtle,
                        ),
                        prefixIcon: const Icon(
                          Icons.bookmark_outline_rounded,
                          color: _primary,
                          size: 19,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: _primary, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Installment Count & Estimate
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 6),
                          child: Text(
                            'INSTALLMENTS (MONTHS)',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                              color: _textMuted,
                            ),
                          ),
                        ),
                        if (_isEven && total > 0 && count > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: _primarySoft,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: _border),
                              ),
                              child: Text(
                                '≈ ₹${(total / count).toStringAsFixed(0)} / mo',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _primary,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    TextField(
                      controller: _countController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _bg,
                        hintText: 'e.g. 12',
                        prefixIcon: const Icon(
                          Icons.repeat_rounded,
                          color: _primary,
                          size: 19,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: _border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: _primary, width: 1.5),
                        ),
                      ),
                      onChanged: (_) =>
                          setState(() => _updateCustomControllers()),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Start Date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 6),
                      child: Text(
                        'START DATE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: _textMuted,
                        ),
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            setState(() => _startDate = date);
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: _bg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  size: 18, color: _primary),
                              const SizedBox(width: 10),
                              Text(
                                DateFormat('MMM dd, yyyy').format(_startDate),
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: _textPrimary,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _border),
                                ),
                                child: const Text(
                                  'Change',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Even Distribution Switch
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Even Distribution',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Split total amount equally across months',
                            style: TextStyle(
                              fontSize: 11,
                              color: _textMuted,
                            ),
                          ),
                        ],
                      ),
                      Switch.adaptive(
                        value: _isEven,
                        activeTrackColor: _primary,
                        onChanged: (val) => setState(() {
                          _isEven = val;
                          _updateCustomControllers();
                        }),
                      ),
                    ],
                  ),
                ),

                // ── Custom amounts if not even
                if (!_isEven) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(builder: (context) {
                          final currentSum = _customAmounts.fold<double>(
                              0.0,
                              (acc, c) =>
                                  acc + (double.tryParse(c.text) ?? 0.0));
                          final isExact = (currentSum - total).abs() <= 0.1;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'CUSTOM AMOUNTS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                  color: _textMuted,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: isExact ? _emeraldLight : _dangerLight,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isExact
                                        ? const Color(0x332F6B4F)
                                        : const Color(0x33B4352F),
                                  ),
                                ),
                                child: Text(
                                  '₹${currentSum.toStringAsFixed(0)} / ₹${total.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isExact ? _emerald : _danger,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                        const SizedBox(height: 10),
                        ...List.generate(
                          _customAmounts.length,
                          (i) => Padding(
                            padding: EdgeInsets.only(
                              bottom: i == _customAmounts.length - 1 ? 0 : 8,
                            ),
                            child: TextField(
                              controller: _customAmounts[i],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: _textPrimary,
                              ),
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                prefixText: 'Month ${i + 1}:   ₹ ',
                                prefixStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _textMuted,
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: _border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                      color: _primary, width: 1.5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 22),

                // ── Action Buttons
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: const BorderSide(color: _border),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: _textMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 6,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          final totalAmt =
                              double.tryParse(_amountController.text) ?? 0;
                          final countVal =
                              int.tryParse(_countController.text) ?? 0;
                          final title = _titleController.text.trim();
                          final provider = _providerController.text.trim();

                          if (totalAmt > 0 &&
                              countVal > 0 &&
                              title.isNotEmpty &&
                              provider.isNotEmpty) {
                            final customVals = _isEven
                                ? null
                                : _customAmounts
                                    .map((c) =>
                                        double.tryParse(c.text) ?? 0.0)
                                    .toList();

                            // Validate custom sum
                            if (customVals != null) {
                              double sum =
                                  customVals.fold(0, (a, b) => a + b);
                              if ((sum - totalAmt).abs() > 0.1) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Custom amounts (₹${sum.toStringAsFixed(0)}) must equal total (₹${totalAmt.toStringAsFixed(0)})'),
                                  ),
                                );
                                return;
                              }
                            }

                            if (widget.existingPlan != null) {
                              ref.read(emiProvider.notifier).updateEMIPlan(
                                    planId: widget.existingPlan!.id,
                                    provider: provider,
                                    title: title,
                                    totalAmount: totalAmt,
                                    installmentCount: countVal,
                                    startDate: _startDate,
                                    type: 'debit',
                                    customAmounts: customVals,
                                  );
                            } else {
                              ref.read(emiProvider.notifier).addEMIPlan(
                                    provider: provider,
                                    title: title,
                                    totalAmount: totalAmt,
                                    installmentCount: countVal,
                                    startDate: _startDate,
                                    type: 'debit',
                                    customAmounts: customVals,
                                  );
                            }
                            Navigator.pop(context);
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.existingPlan != null
                                  ? Icons.check_circle_rounded
                                  : Icons.check_rounded,
                              size: 17,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.existingPlan != null
                                  ? 'Save Changes'
                                  : 'Create EMI',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AccountBalancesDialog extends ConsumerWidget {
  const AccountBalancesDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(monetaryProvider).accounts;

    return AlertDialog(
      title: const Text('Account Balances'),
      content: SizedBox(
        width: 360,
        child: accounts.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No accounts added yet.'),
              )
            : ListView.separated(
                shrinkWrap: true,
                itemCount: accounts.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final account = accounts[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.account_balance_wallet_outlined),
                    title: Text(account.name),
                    subtitle: Text('₹${account.balance.toStringAsFixed(2)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit balance',
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => AccountBalanceFormDialog(account: account),
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => const AccountBalanceFormDialog(),
          ),
          child: const Text('Add Account'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class AccountBalanceFormDialog extends ConsumerStatefulWidget {
  final AccountBalance? account;

  const AccountBalanceFormDialog({super.key, this.account});

  @override
  ConsumerState<AccountBalanceFormDialog> createState() =>
      _AccountBalanceFormDialogState();
}

class _AccountBalanceFormDialogState
    extends ConsumerState<AccountBalanceFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.account?.name ?? '');
    _balanceController = TextEditingController(
        text: widget.account?.balance.toStringAsFixed(2) ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.account != null;
    return AlertDialog(
      title: Text(isEditing ? 'Edit Account Balance' : 'Add Account Balance'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
                labelText: 'Account Name', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _balanceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Current Balance (₹)', border: OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final balance = double.tryParse(_balanceController.text);
            if (name.isEmpty || balance == null) return;

            if (widget.account == null) {
              ref.read(monetaryProvider.notifier).addAccountBalance(name, balance);
            } else {
              ref.read(monetaryProvider.notifier).updateAccountBalance(
                    AccountBalance(
                      id: widget.account!.id,
                      name: name,
                      balance: balance,
                    ),
                  );
            }
            Navigator.pop(context);
          },
          child: Text(isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
