import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:reset_flow/models/emi_model.dart';
import 'package:reset_flow/models/financial_transaction.dart';
import 'package:reset_flow/providers/emi_provider.dart';
import 'package:reset_flow/providers/monetary_provider.dart';
import 'package:reset_flow/screens/emi_details_screen.dart';

class CashRequirementsScreen extends ConsumerWidget {
  const CashRequirementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _CashRequirementsBody();
  }
}

class _CashRequirementsBody extends ConsumerStatefulWidget {
  const _CashRequirementsBody();

  @override
  ConsumerState<_CashRequirementsBody> createState() =>
      _CashRequirementsBodyState();
}

class _CashRequirementsBodyState extends ConsumerState<_CashRequirementsBody> {
  int _selectedTab = 0; // 0: Monthly Schedule, 1: By Lender, 2: Personal Dues
  int _personalSubFilter =
      0; // 0: All, 1: Lent (Receivables), 2: Borrowed (Payables)
  final Set<DateTime> _expandedMonths = {};
  bool _initializedExpanded = false;

  // ── Palette Tokens: Clean white surfaces with navy and slate accents
  // Brand
// Brand — Ink Navy
  static const Color _primary = Color(0xFF1E3A5F);
  static const Color _primarySoft = Color(0xFFEEF2F7);

  // Surfaces
  static const Color _bg = Color(0xFFF5F6F8);
  static const Color _bgTop = Color(0xFFEBEEF3);
  static const Color _surface = Colors.white;
  static const Color _panel = Color(0xFFF8F9FB);
  static const Color _border = Color(0xFFDFE3E9);
  static const Color _divider = Color(0xFFEBEEF2);
  static const Color _track = Color(0xFFE3E7ED);

  // Text
  static const Color _textPrimary = Color(0xFF14202E);
  static const Color _textSecondary = Color(0xFF3D4A5A);
  static const Color _textMuted = Color(0xFF5F6B7A);
  static const Color _textSubtle = Color(0xFF8892A0);

  // Semantic (desaturated so they read as status, not decoration)
  static const Color _danger = Color(0xFFB4352F); // Brick
  static const Color _dangerLight = Color(0xFFFBEFEE);
  static const Color _dangerBorder = Color(0x40B4352F);
  static const Color _emerald = Color(0xFF2F6B4F); // Forest
  static const Color _emeraldLight = Color(0xFFECF4EF);
  static const Color _amber = Color(0xFFA8690F); // Ochre
  static const Color _amberLight = Color(0xFFFAF3E6);

  // Single-hue gradient with a small shift, no hue jump
  static const LinearGradient _brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E3A5F), Color(0xFF2F5580)],
  );

  static const List<BoxShadow> _cardShadow = [
    BoxShadow(
      color: Color(0x0D14202E),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
    BoxShadow(
      color: Color(0x0A14202E),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  // Accent set used to give each lender / person its own colour identity
  static const List<_Accent> _accents = [
    _Accent(
      Color(0xFF1E3A5F), // Navy
      Color(0xFFEEF2F7),
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4A6A94), Color(0xFF1E3A5F)],
      ),
    ),
    _Accent(
      Color(0xFF3A6EA5), // Steel blue
      Color(0xFFEBF1F8),
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF6C97C4), Color(0xFF3A6EA5)],
      ),
    ),
    _Accent(
      Color(0xFF1F6F78), // Deep teal
      Color(0xFFEAF4F5),
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4E9AA3), Color(0xFF1F6F78)],
      ),
    ),
    _Accent(
      Color(0xFF2F6B4F), // Forest
      Color(0xFFECF4EF),
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF5C9A7C), Color(0xFF2F6B4F)],
      ),
    ),
    _Accent(
      Color(0xFFA8690F), // Ochre
      Color(0xFFFAF3E6),
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFD09A3F), Color(0xFFA8690F)],
      ),
    ),
    _Accent(
      Color(0xFF356F78), // Muted teal
      Color(0xFFEAF4F5),
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF5BA5AD), Color(0xFF356F78)],
      ),
    ),
  ];

  _Accent _accentFor(String key) {
    final hash = key.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    return _accents[hash % _accents.length];
  }

  String _formatCurrency(double amount) {
    final hasDecimals = amount % 1 != 0;
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: hasDecimals ? 2 : 0,
    );
    return formatter.format(amount);
  }

  BoxDecoration _cardDecoration({
    double radius = 20,
    Color? borderColor,
    double borderWidth = 1,
    List<BoxShadow>? shadow,
  }) {
    return BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor ?? _border, width: borderWidth),
      boxShadow: shadow ?? _cardShadow,
    );
  }

  @override
  Widget build(BuildContext context) {
    final emiState = ref.watch(emiProvider);
    final monetaryState = ref.watch(monetaryProvider);
    final monetaryNotifier = ref.read(monetaryProvider.notifier);

    // Personal funds: Borrowed (You owe / Liabilities)
    final peopleYouOwe = monetaryNotifier.personSummary.entries
        .where((entry) => (entry.value['debit'] ?? 0) > 0)
        .toList()
      ..sort(
          (a, b) => (b.value['debit'] ?? 0).compareTo(a.value['debit'] ?? 0));

    final personalBorrowedTotal = monetaryState.transactions
        .where((transaction) => transaction.type == TransactionType.debit)
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
    final personalBorrowed =
        personalBorrowedTotal > 0 ? personalBorrowedTotal : 0.0;

    // Personal funds: Lended (Owed to you / Receivables / Recoverable)
    final peopleWhoOweYou = monetaryNotifier.personSummary.entries
        .where((entry) => (entry.value['credit'] ?? 0) > 0)
        .toList()
      ..sort(
          (a, b) => (b.value['credit'] ?? 0).compareTo(a.value['credit'] ?? 0));

    final personalLentTotal = monetaryState.transactions
        .where((transaction) => transaction.type == TransactionType.credit)
        .fold(0.0, (sum, transaction) => sum + transaction.amount);
    final personalLent = personalLentTotal > 0 ? personalLentTotal : 0.0;

    // All active personal contacts
    final allPersonalContacts = monetaryNotifier.personSummary.entries
        .where((entry) =>
            (entry.value['debit'] ?? 0) > 0 || (entry.value['credit'] ?? 0) > 0)
        .toList()
      ..sort((a, b) {
        final aMax = math.max(a.value['debit'] ?? 0, a.value['credit'] ?? 0);
        final bMax = math.max(b.value['debit'] ?? 0, b.value['credit'] ?? 0);
        return bMax.compareTo(aMax);
      });

    final plansById = {for (final plan in emiState.plans) plan.id: plan};
    final monthlyInstallments = <DateTime, List<EMIInstallment>>{};
    final lenderSummaries = <String, _LenderEmiSummary>{};

    var totalEmiAmount = 0.0;
    var totalEmiPaid = 0.0;
    var totalPendingEmis = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endOfCurrentMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    var dueThisMonthAmount = 0.0;
    var overdueCount = 0;
    var overdueAmount = 0.0;

    for (final plan in emiState.plans.where((plan) => plan.type == 'debit')) {
      final installments = emiState.installments[plan.id] ?? [];
      final lender =
          plan.provider.trim().isEmpty ? 'Other Lender' : plan.provider.trim();
      final lenderSummary = lenderSummaries.putIfAbsent(
        lender,
        () => _LenderEmiSummary(lender),
      );
      lenderSummary.plans.add(plan);

      final planAmount = installments.isEmpty
          ? plan.totalAmount
          : installments.fold(
              0.0, (sum, installment) => sum + installment.amount);
      final paidAmount = installments
          .where((installment) => installment.isPaid)
          .fold(0.0, (sum, installment) => sum + installment.amount);
      final pendingCount =
          installments.where((installment) => !installment.isPaid).length;

      totalEmiAmount += planAmount;
      totalEmiPaid += paidAmount;
      totalPendingEmis += pendingCount;
      lenderSummary.totalAmount += planAmount;
      lenderSummary.paidAmount += paidAmount;
      lenderSummary.pendingCount += pendingCount;

      for (final installment in installments) {
        if (installment.isPaid) continue;

        if (installment.dueDate.isBefore(today)) {
          overdueCount++;
          overdueAmount += installment.amount;
        }

        if (!installment.dueDate.isAfter(endOfCurrentMonth)) {
          dueThisMonthAmount += installment.amount;
        }

        final month =
            DateTime(installment.dueDate.year, installment.dueDate.month);
        monthlyInstallments.putIfAbsent(month, () => []).add(installment);
      }
    }

    final months = monthlyInstallments.keys.toList()..sort();

    // Sort installments in each month by dueDate
    for (final monthKey in monthlyInstallments.keys) {
      monthlyInstallments[monthKey]!
          .sort((a, b) => a.dueDate.compareTo(b.dueDate));
    }

    // Default to expanding all months initially
    if (!_initializedExpanded && months.isNotEmpty) {
      _expandedMonths.addAll(months);
      _initializedExpanded = true;
    }

    final totalEmiRemaining =
        (totalEmiAmount - totalEmiPaid).clamp(0.0, double.infinity);
    final grandTotalCashNeeded = totalEmiRemaining + personalBorrowed;
    final netCashNeeded =
        (grandTotalCashNeeded - personalLent).clamp(0.0, double.infinity);
    final emiProgress = totalEmiAmount > 0
        ? (totalEmiPaid / totalEmiAmount).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bgTop,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cash Requirements',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 1),
            Text(
              'Liquidity planner & liability schedule',
              style: TextStyle(
                color: _textMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: _border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x141E1B4B),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.info_outline_rounded,
                    color: _primary,
                    size: 20,
                  ),
                  tooltip: 'About Cash Requirements',
                  onPressed: () => _showCashRequirementsInfo(context),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bg],
            stops: [0.0, 0.3],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // ── Bento Dashboard Summary
            _buildBentoSummary(
              grandTotal: grandTotalCashNeeded,
              totalEmiRemaining: totalEmiRemaining,
              personalBorrowed: personalBorrowed,
              personalLent: personalLent,
              netCashNeeded: netCashNeeded,
              dueThisMonth: dueThisMonthAmount,
              totalPendingEmis: totalPendingEmis,
              personalContactsCount: allPersonalContacts.length,
              totalEmiPaid: totalEmiPaid,
              totalEmiAmount: totalEmiAmount,
              emiProgress: emiProgress,
              overdueCount: overdueCount,
              overdueAmount: overdueAmount,
            ),
            const SizedBox(height: 18),

            // ── Segmented Navigation Bar
            _buildSegmentedTabs(
              scheduleCount: months.length,
              lenderCount: lenderSummaries.length,
              personalCount: allPersonalContacts.length,
            ),
            const SizedBox(height: 18),

            // ── Tab Content
            if (_selectedTab == 0)
              _buildScheduleTab(
                months: months,
                monthlyInstallments: monthlyInstallments,
                plansById: plansById,
              )
            else if (_selectedTab == 1)
              _buildLenderTab(
                lenderSummaries: lenderSummaries.values.toList()
                  ..sort((a, b) => (b.totalAmount - b.paidAmount)
                      .compareTo(a.totalAmount - a.paidAmount)),
              )
            else
              _buildPersonalDuesTab(
                peopleYouOwe: peopleYouOwe,
                peopleWhoOweYou: peopleWhoOweYou,
                allContacts: allPersonalContacts,
                totalPersonalBorrowed: personalBorrowed,
                totalPersonalLent: personalLent,
              ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SHARED SMALL BUILDING BLOCKS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSectionLabel(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3.5,
          height: 14,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3A6EA5), Color(0xFF1E3A5F)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
            color: _textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildGlow(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildGradientBar({
    required double value,
    LinearGradient gradient = _brandGradient,
    double height = 7,
  }) {
    final clamped = value.clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth * clamped;
        return SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: _track,
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: width,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BENTO DASHBOARD SUMMARY (HERO TILE + REPAYMENT RING + METRIC TILES)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildBentoSummary({
    required double grandTotal,
    required double totalEmiRemaining,
    required double personalBorrowed,
    required double personalLent,
    required double netCashNeeded,
    required double dueThisMonth,
    required int totalPendingEmis,
    required int personalContactsCount,
    required double totalEmiPaid,
    required double totalEmiAmount,
    required double emiProgress,
    required int overdueCount,
    required double overdueAmount,
  }) {
    final netPersonal = personalBorrowed - personalLent;
    final String personalDisplay;
    final Color? personalColor;
    if (netPersonal < 0) {
      personalDisplay = '-${_formatCurrency(netPersonal.abs())}';
      personalColor = const Color(0xFF6EE7B7);
    } else {
      personalDisplay = _formatCurrency(netPersonal);
      personalColor = null;
    }

    return Column(
      children: [
        // ── Row 1: Primary Liability Hero Tile + Circular Repayment Ring Tile
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tile 1 (Left): Total Cash Required
              Expanded(
                flex: 11,
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    gradient: _brandGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x403A6EA5),
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -28,
                        top: -28,
                        child: _buildGlow(96, const Color(0x1FFFFFFF)),
                      ),
                      Positioned(
                        left: -20,
                        bottom: -40,
                        child: _buildGlow(86, const Color(0x14FFFFFF)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          color: const Color(0x33FFFFFF),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.account_balance_wallet_rounded,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Flexible(
                                        child: Text(
                                          'Total required',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xCCFFFFFF),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (overdueCount > 0)
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _dangerLight,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.warning_amber_rounded,
                                          size: 12,
                                          color: _danger,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '$overdueCount',
                                          style: const TextStyle(
                                            color: _danger,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _formatCurrency(netCashNeeded),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1,
                                  height: 1.05,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 9),
                              decoration: BoxDecoration(
                                color: const Color(0x26FFFFFF),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                children: [
                                  _buildHeroLine(
                                    'EMI',
                                    _formatCurrency(totalEmiRemaining),
                                  ),
                                  const SizedBox(height: 6),
                                  _buildHeroLine(
                                    'Personal',
                                    personalDisplay,
                                    valueColor: personalColor,
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
              ),
              const SizedBox(width: 10),

              // Tile 2 (Right): Circular Repayment Ring Gauge
              Expanded(
                flex: 7,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                  decoration: _cardDecoration(radius: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: CustomPaint(
                          painter: _RingPainter(
                            progress: emiProgress,
                            strokeWidth: 7,
                            trackColor: _track,
                            colors: const [
                              Color(0xFF34D399),
                              Color(0xFF059669),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${(emiProgress * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'EMI cleared',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _emeraldLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _formatCurrency(totalEmiPaid),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: _emerald,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // ── Row 2: 3 Interactive Metric Cards
        Row(
          children: [
            Expanded(
              child: _buildBentoStatPill(
                icon: Icons.event_available_rounded,
                label: 'Due this month',
                value: _formatCurrency(dueThisMonth),
                accent: dueThisMonth > 0 ? _amber : _textMuted,
                accentLight: dueThisMonth > 0 ? _amberLight : _panel,
                onTap: () => setState(() => _selectedTab = 0),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildBentoStatPill(
                icon: Icons.credit_card_rounded,
                label: 'Pending EMIs',
                value: '$totalPendingEmis Due',
                accent: _primary,
                accentLight: _primarySoft,
                onTap: () => setState(() => _selectedTab = 1),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildBentoStatPill(
                icon: Icons.people_outline_rounded,
                label: 'Personal funds',
                value:
                    '$personalContactsCount ${personalContactsCount == 1 ? "Person" : "People"}',
                accent: personalContactsCount > 0 ? _primary : _textMuted,
                accentLight: personalContactsCount > 0
                    ? const Color(0xFFEEF2FF)
                    : _panel,
                onTap: () => setState(() => _selectedTab = 2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroLine(
    String label,
    String value, {
    Color? valueColor,
    bool isHighlight = false,
  }) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: valueColor ?? const Color(0xB3FFFFFF),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            color: isHighlight ? Colors.white : const Color(0xCCFFFFFF),
            fontSize: 11,
            fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  color: valueColor ?? Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBentoStatPill({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
    required Color accentLight,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: _cardDecoration(radius: 18),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: accentLight,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(icon, size: 15, color: accent),
                    ),
                    const Icon(
                      Icons.north_east_rounded,
                      size: 12,
                      color: _textSubtle,
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: _textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: accent == _textMuted ? _textPrimary : accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SEGMENTED TAB SELECTOR
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSegmentedTabs({
    required int scheduleCount,
    required int lenderCount,
    required int personalCount,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1E1B4B),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildTabPill(
            index: 0,
            title: 'Schedule',
            count: scheduleCount,
            icon: Icons.calendar_month_outlined,
          ),
          _buildTabPill(
            index: 1,
            title: 'Lenders',
            count: lenderCount,
            icon: Icons.account_balance_outlined,
          ),
          _buildTabPill(
            index: 2,
            title: 'Personal',
            count: personalCount,
            icon: Icons.people_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill({
    required int index,
    required String title,
    required int count,
    required IconData icon,
  }) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected ? _brandGradient : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x403A6EA5),
                      blurRadius: 12,
                      offset: Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : _textMuted,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    maxLines: 1,
                    style: TextStyle(
                      color: isSelected ? Colors.white : _textMuted,
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0x33FFFFFF) : _primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : _primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 1: MONTHLY SCHEDULE
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildScheduleTab({
    required List<DateTime> months,
    required Map<DateTime, List<EMIInstallment>> monthlyInstallments,
    required Map<String, EMIPlan> plansById,
  }) {
    if (months.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'All Clear!',
        subtitle:
            'You have no pending EMI installments scheduled for upcoming months.',
      );
    }

    var cumulative = 0.0;
    final cumulativeByMonth = <DateTime, double>{};
    for (final m in months) {
      final monthlyTotal =
          monthlyInstallments[m]!.fold(0.0, (sum, item) => sum + item.amount);
      cumulative += monthlyTotal;
      cumulativeByMonth[m] = cumulative;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row with Expand/Collapse toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildSectionLabel('Upcoming timeline'),
                const SizedBox(width: 8),
                Text(
                  '${months.length} ${months.length == 1 ? 'month' : 'months'}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: _textSubtle,
                  ),
                ),
              ],
            ),
            Material(
              color: _primarySoft,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (_expandedMonths.length == months.length) {
                      _expandedMonths.clear();
                    } else {
                      _expandedMonths.addAll(months);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  child: Text(
                    _expandedMonths.length == months.length
                        ? 'Collapse all'
                        : 'Expand all',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Month Cards List
        ...months.map((month) {
          final installments = monthlyInstallments[month]!;
          final monthlyTotal =
              installments.fold(0.0, (sum, item) => sum + item.amount);
          final monthCumulative = cumulativeByMonth[month] ?? monthlyTotal;
          final isExpanded = _expandedMonths.contains(month);

          return _buildMonthCard(
            month: month,
            monthlyTotal: monthlyTotal,
            cumulative: monthCumulative,
            installments: installments,
            plansById: plansById,
            isExpanded: isExpanded,
            onToggleExpand: () {
              setState(() {
                if (isExpanded) {
                  _expandedMonths.remove(month);
                } else {
                  _expandedMonths.add(month);
                }
              });
            },
          );
        }),
      ],
    );
  }

  Widget _buildMonthCard({
    required DateTime month,
    required double monthlyTotal,
    required double cumulative,
    required List<EMIInstallment> installments,
    required Map<String, EMIPlan> plansById,
    required bool isExpanded,
    required VoidCallback onToggleExpand,
  }) {
    final now = DateTime.now();
    final isCurrentMonth = now.year == month.year && now.month == month.month;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: _cardDecoration(
          radius: 20,
          borderColor: isCurrentMonth ? const Color(0x663A6EA5) : _border,
          borderWidth: isCurrentMonth ? 1.5 : 1,
          shadow: isCurrentMonth
              ? const [
                  BoxShadow(
                    color: Color(0x223A6EA5),
                    blurRadius: 22,
                    offset: Offset(0, 8),
                  ),
                ]
              : _cardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              // Month Header Row (Tappable to expand/collapse)
              InkWell(
                onTap: onToggleExpand,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  child: Row(
                    children: [
                      // Month Calendar Badge
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: isCurrentMonth ? _brandGradient : null,
                          color: isCurrentMonth ? null : _primarySoft,
                          borderRadius: BorderRadius.circular(13),
                          boxShadow: isCurrentMonth
                              ? const [
                                  BoxShadow(
                                    color: Color(0x403A6EA5),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('MMM').format(month).toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                                color: isCurrentMonth
                                    ? const Color(0xCCFFFFFF)
                                    : _primary,
                              ),
                            ),
                            Text(
                              DateFormat('yy').format(month),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isCurrentMonth
                                    ? Colors.white
                                    : _textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Month Name & Count
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    DateFormat('MMMM yyyy').format(month),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                if (isCurrentMonth) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _primarySoft,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Current',
                                      style: TextStyle(
                                        color: _primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 9.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${installments.length} installment${installments.length == 1 ? '' : 's'} scheduled',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _textMuted,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Amounts & Chevron
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _formatCurrency(monthlyTotal),
                              style: TextStyle(
                                color: isCurrentMonth ? _primary : _textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Cumul: ${_formatCurrency(cumulative)}',
                              style: const TextStyle(
                                color: _textSubtle,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: _panel,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: _textMuted,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Expanded Installments List (Bullet Pointed)
              if (isExpanded) ...[
                const Divider(height: 1, thickness: 1, color: _divider),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                  child: Column(
                    children: [
                      for (int i = 0; i < installments.length; i++) ...[
                        if (i > 0)
                          const Divider(
                            height: 1,
                            thickness: 0.8,
                            indent: 20,
                            endIndent: 4,
                            color: _divider,
                          ),
                        _buildInstallmentBulletItem(
                          context: context,
                          installment: installments[i],
                          plan: plansById[installments[i].planId],
                          now: now,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstallmentBulletItem({
    required BuildContext context,
    required EMIInstallment installment,
    required EMIPlan? plan,
    required DateTime now,
  }) {
    final isOverdue =
        installment.dueDate.isBefore(DateTime(now.year, now.month, now.day));
    final accent = _accentFor(plan?.title ?? installment.planId);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: plan != null
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EMIDetailScreen(planId: plan.id),
                  ),
                )
            : null,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Bullet Point Dot
              Container(
                width: 6.5,
                height: 6.5,
                decoration: BoxDecoration(
                  color: isOverdue ? _danger : accent.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),

              // Title, provider, and due date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            plan?.title ?? 'EMI Installment',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isOverdue ? _danger : _textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                        if (isOverdue) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: _dangerLight,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _dangerBorder),
                            ),
                            child: const Text(
                              'Overdue',
                              style: TextStyle(
                                color: _danger,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${plan?.provider ?? 'Provider'}  •  Due ${DateFormat('d MMM').format(installment.dueDate)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isOverdue ? _danger.withAlpha(200) : _textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Amount & link chevron
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatCurrency(installment.amount),
                    style: TextStyle(
                      color: isOverdue ? _danger : _textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 15,
                    color: _textSubtle,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 2: BY LENDER
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildLenderTab({
    required List<_LenderEmiSummary> lenderSummaries,
  }) {
    if (lenderSummaries.isEmpty) {
      return _buildEmptyState(
        icon: Icons.account_balance_outlined,
        title: 'No Active Lenders',
        subtitle:
            'You do not have any registered debit EMI loan plans or financing partners.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionLabel('Financiers & lenders'),
            Text(
              '${lenderSummaries.length} ${lenderSummaries.length == 1 ? 'Lender' : 'Lenders'}',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: _textSubtle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...lenderSummaries.map((summary) {
          final remaining = summary.totalAmount - summary.paidAmount;
          final progress = summary.totalAmount > 0
              ? (summary.paidAmount / summary.totalAmount).clamp(0.0, 1.0)
              : 0.0;
          final accent = _accentFor(summary.lender);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: _cardDecoration(radius: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lender Header
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: accent.gradient,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: accent.color.withAlpha(60),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_balance_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              summary.lender,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${summary.plans.length} plan${summary.plans.length == 1 ? '' : 's'} registered',
                              style: const TextStyle(
                                color: _textMuted,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: summary.pendingCount > 0
                              ? _amberLight
                              : _emeraldLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: summary.pendingCount > 0
                                    ? _amber
                                    : _emerald,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              summary.pendingCount > 0
                                  ? '${summary.pendingCount} pending'
                                  : 'Cleared',
                              style: TextStyle(
                                color: summary.pendingCount > 0
                                    ? _amber
                                    : _emerald,
                                fontWeight: FontWeight.w700,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Amount Stats Panel
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: _panel,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _divider),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            label: 'Remaining',
                            value: _formatCurrency(remaining),
                            valueColor: accent.color,
                            isBold: true,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildMetricTile(
                            label: 'Paid',
                            value: _formatCurrency(summary.paidAmount),
                            valueColor: _emerald,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildMetricTile(
                            label: 'Total loan',
                            value: _formatCurrency(summary.totalAmount),
                            alignEnd: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Progress Bar
                  Row(
                    children: [
                      Expanded(
                        child: _buildGradientBar(
                          value: progress,
                          gradient: accent.gradient,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${(progress * 100).toInt()}% paid',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),

                  // Associated Plans Pills (Clickable to jump to plan)
                  if (summary.plans.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: summary.plans.map((plan) {
                        return Container(
                          decoration: BoxDecoration(
                            color: accent.light,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: accent.color.withAlpha(46),
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EMIDetailScreen(planId: plan.id),
                                ),
                              ),
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 5),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      plan.title,
                                      style: TextStyle(
                                        color: accent.color,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 14,
                                      color: accent.color,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 3: PERSONAL FUNDS & DEBTS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildPersonalDuesTab({
    required List<MapEntry<String, Map<String, double>>> peopleYouOwe,
    required List<MapEntry<String, Map<String, double>>> peopleWhoOweYou,
    required List<MapEntry<String, Map<String, double>>> allContacts,
    required double totalPersonalBorrowed,
    required double totalPersonalLent,
  }) {
    if (allContacts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.sentiment_satisfied_alt_rounded,
        title: 'No Personal Transactions',
        subtitle:
            'You do not have any borrowed debts or lended funds recorded in your personal ledger.',
      );
    }

    final List<MapEntry<String, Map<String, double>>> displayedContacts;
    if (_personalSubFilter == 1) {
      displayedContacts = peopleWhoOweYou;
    } else if (_personalSubFilter == 2) {
      displayedContacts = peopleYouOwe;
    } else {
      displayedContacts = allContacts;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionLabel('Personal funds & debts'),
            Text(
              '${allContacts.length} ${allContacts.length == 1 ? 'Contact' : 'Contacts'}',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: _textSubtle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Net Liquidity Position Banner
        Builder(
          builder: (context) {
            final netBalance = totalPersonalLent - totalPersonalBorrowed;
            final isSurplus = netBalance > 0;
            final isEven = netBalance == 0;
            final bannerColor =
                isSurplus ? _emerald : (isEven ? _textSecondary : _danger);
            final bannerBg = isSurplus
                ? const Color(0xFFF0FDF4)
                : (isEven ? const Color(0xFFF8FAFC) : const Color(0xFFFFF1F2));
            final bannerBorder = isSurplus
                ? const Color(0xFFA7F3D0)
                : (isEven ? _border : const Color(0xFFFECDD3));

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: bannerBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: bannerBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isSurplus
                          ? _emeraldLight
                          : (isEven ? _track : _dangerLight),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSurplus
                          ? Icons.savings_outlined
                          : (isEven
                              ? Icons.balance_rounded
                              : Icons.account_balance_wallet_outlined),
                      color: bannerColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSurplus
                              ? 'Net Personal Surplus'
                              : (isEven
                                  ? 'Even Personal Balance'
                                  : 'Net Personal Deficit'),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: bannerColor,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          isSurplus
                              ? 'Lended funds offset your debts with ${_formatCurrency(netBalance)} surplus.'
                              : (isEven
                                  ? 'Receivables match your personal borrowings.'
                                  : 'You owe ${_formatCurrency(netBalance.abs())} more than you are owed.'),
                          style: const TextStyle(
                            fontSize: 11,
                            color: _textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      isSurplus
                          ? '+${_formatCurrency(netBalance)}'
                          : (isEven
                              ? _formatCurrency(0)
                              : '-${_formatCurrency(netBalance.abs())}'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: bannerColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 14),

        // Sub-filter tabs: All | Lent | Borrowed
        Container(
          padding: const EdgeInsets.all(3.5),
          decoration: BoxDecoration(
            color: _panel,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              _buildSubFilterPill(
                index: 0,
                label: 'All',
                count: allContacts.length,
              ),
              _buildSubFilterPill(
                index: 1,
                label: 'Lent',
                count: peopleWhoOweYou.length,
              ),
              _buildSubFilterPill(
                index: 2,
                label: 'Borrowed',
                count: peopleYouOwe.length,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Contacts list or filter empty state
        if (displayedContacts.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            alignment: Alignment.center,
            decoration: _cardDecoration(radius: 20),
            child: Text(
              _personalSubFilter == 1
                  ? 'No contacts owe you money'
                  : 'No contacts you owe money to',
              style: const TextStyle(
                color: _textMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: _cardDecoration(radius: 22),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayedContacts.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                thickness: 1,
                indent: 66,
                endIndent: 14,
                color: _divider,
              ),
              itemBuilder: (context, index) {
                final entry = displayedContacts[index];
                final personName = entry.key;
                final credit = entry.value['credit'] ?? 0.0;
                final debit = entry.value['debit'] ?? 0.0;
                final initial =
                    personName.isNotEmpty ? personName[0].toUpperCase() : '?';
                final accent = _accentFor(personName);

                final bool hasCredit = credit > 0;
                final bool hasDebit = debit > 0;

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: accent.gradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accent.color.withAlpha(50),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              personName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                letterSpacing: -0.1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (hasCredit && hasDebit)
                              Text(
                                'Lent ${_formatCurrency(credit)} • Borrowed ${_formatCurrency(debit)}',
                                style: const TextStyle(
                                  color: _textMuted,
                                  fontSize: 11,
                                ),
                              )
                            else if (hasCredit)
                              const Row(
                                children: [
                                  Icon(
                                    Icons.call_received_rounded,
                                    size: 11,
                                    color: _emerald,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'He owes you (Receivable)',
                                    style: TextStyle(
                                      color: _emerald,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              )
                            else
                              const Row(
                                children: [
                                  Icon(
                                    Icons.call_made_rounded,
                                    size: 11,
                                    color: _danger,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'You owe him (Payable)',
                                    style: TextStyle(
                                      color: _danger,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (hasCredit && !hasDebit)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _emeraldLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '+${_formatCurrency(credit)}',
                            style: const TextStyle(
                              color: _emerald,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                              letterSpacing: -0.2,
                            ),
                          ),
                        )
                      else if (!hasCredit && hasDebit)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _dangerLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '-${_formatCurrency(debit)}',
                            style: const TextStyle(
                              color: _danger,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                              letterSpacing: -0.2,
                            ),
                          ),
                        )
                      else ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '+${_formatCurrency(credit)}',
                              style: const TextStyle(
                                color: _emerald,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '-${_formatCurrency(debit)}',
                              style: const TextStyle(
                                color: _danger,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSubFilterPill({
    required int index,
    required String label,
    required int count,
  }) {
    final isSelected = _personalSubFilter == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _personalSubFilter = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 4,
                      offset: Offset(0, 1.5),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? _textPrimary : _textMuted,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? _primarySoft : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? _primary : _textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildMetricTile({
    required String label,
    required String value,
    Color valueColor = _textPrimary,
    bool isBold = false,
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            textAlign: alignEnd ? TextAlign.end : TextAlign.start,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: _textMuted,
            ),
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
              fontSize: 13.5,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: _cardDecoration(radius: 24),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: _primarySoft,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  gradient: _brandGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x403A6EA5),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textMuted,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  void _showCashRequirementsInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9DEEA),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: _brandGradient,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.insights_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Understanding Cash Requirements',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildInfoItem(
                icon: Icons.event_available_rounded,
                title: 'Due This Month',
                description:
                    'Installments due in the current calendar month plus any overdue payments requiring immediate cash.',
                accent: _amber,
                accentLight: _amberLight,
              ),
              _buildInfoItem(
                icon: Icons.timeline_rounded,
                title: 'Cumulative Timeline',
                description:
                    'Shows both the monthly cash needed and the running cumulative requirement up to that month.',
                accent: _primary,
                accentLight: _primarySoft,
              ),
              _buildInfoItem(
                icon: Icons.call_made_rounded,
                title: 'Borrowed Debts (Payables)',
                description:
                    'Personal debts owed to individuals that need to be settled alongside your EMIs.',
                accent: _danger,
                accentLight: _dangerLight,
              ),
              _buildInfoItem(
                icon: Icons.call_received_rounded,
                title: 'Lended Funds (Receivables)',
                description:
                    'Money you lent to friends/family. These are expected cash inflows that offset your gross liabilities.',
                accent: _emerald,
                accentLight: _emeraldLight,
              ),
              const SizedBox(height: 10),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: _brandGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x403A6EA5),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'Got it',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
    required Color accent,
    required Color accentLight,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accentLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Gradient ring used for the "EMI cleared" gauge
class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.colors,
  });

  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final sweep = 2 * math.pi * progress;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: sweep < 0.01 ? 0.01 : sweep,
        colors: colors,
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);

    canvas.drawArc(rect, -math.pi / 2, sweep, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.trackColor != trackColor;
  }
}

class _Accent {
  const _Accent(this.color, this.light, this.gradient);

  final Color color;
  final Color light;
  final LinearGradient gradient;
}

class _LenderEmiSummary {
  _LenderEmiSummary(this.lender);

  final String lender;
  double totalAmount = 0;
  double paidAmount = 0;
  int pendingCount = 0;
  final List<EMIPlan> plans = [];
}
