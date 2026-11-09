import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:reset_flow/models/emi_model.dart';
import 'package:reset_flow/providers/emi_provider.dart';
import 'package:reset_flow/screens/monetary_dealings_screen.dart';

class EMIDetailScreen extends ConsumerStatefulWidget {
  final String planId;
  const EMIDetailScreen({super.key, required this.planId});

  @override
  ConsumerState<EMIDetailScreen> createState() => _EMIDetailScreenState();
}

class _EMIDetailScreenState extends ConsumerState<EMIDetailScreen> {
  int _filterIndex = 0; // 0: All, 1: Unpaid, 2: Paid

  // ── Palette Tokens: Pure White Theme + Ink Navy & Slate Accents ──
  static const Color _primary = Color(0xFF1E3A5F);
  static const Color _primarySoft = Color(0xFFF1F5F9);

  static const Color _bg = Colors.white;
  static const Color _panel = Color(0xFFF8FAFC);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _divider = Color(0xFFF1F5F9);
  static const Color _track = Color(0xFFE2E8F0);

  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF334155);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _textSubtle = Color(0xFF94A3B8);

  static const Color _emerald = Color(0xFF16A34A);
  static const Color _emeraldLight = Color(0xFFF0FDF4);
  static const Color _emeraldBorder = Color(0x3316A34A);

  static const Color _danger = Color(0xFFDC2626);
  static const Color _dangerLight = Color(0xFFFEF2F2);
  static const Color _dangerBorder = Color(0x33DC2626);

  static const Color _amber = Color(0xFFD97706);
  static const Color _amberLight = Color(0xFFFFFBEB);
  static const Color _amberBorder = Color(0x33D97706);

  @override
  Widget build(BuildContext context) {
    final emiState = ref.watch(emiProvider);
    final planList = emiState.plans.where((p) => p.id == widget.planId);
    if (planList.isEmpty) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final plan = planList.first;
    final allInstallments = emiState.installments[widget.planId] ?? [];

    // Sort chronologically
    final sortedInstallments = [...allInstallments]
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final totalCount = sortedInstallments.length;
    final paidCount = sortedInstallments.where((i) => i.isPaid).length;
    final unpaidCount = totalCount - paidCount;

    final paidAmount = sortedInstallments
        .where((i) => i.isPaid)
        .fold(0.0, (sum, i) => sum + i.amount);
    final calculatedTotal =
        sortedInstallments.fold(0.0, (sum, i) => sum + i.amount);
    final effectiveTotal =
        calculatedTotal > 0 ? calculatedTotal : plan.totalAmount;
    final remainingAmount = math.max(0.0, effectiveTotal - paidAmount);
    final progress =
        totalCount == 0 ? 0.0 : (paidCount / totalCount).clamp(0.0, 1.0);
    final isFullySettled = totalCount > 0 && paidCount == totalCount;

    // Next due installment (first unpaid)
    final nextDue =
        sortedInstallments.where((i) => !i.isPaid).firstOrNull;

    // Filtered installments
    List<EMIInstallment> displayedInstallments;
    if (_filterIndex == 1) {
      displayedInstallments =
          sortedInstallments.where((i) => !i.isPaid).toList();
    } else if (_filterIndex == 2) {
      displayedInstallments =
          sortedInstallments.where((i) => i.isPaid).toList();
    } else {
      displayedInstallments = sortedInstallments;
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(context, plan, remainingAmount, allInstallments),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Clean Typography Header (No Hero Card)
            _buildPlanHeader(
              plan: plan,
              effectiveTotal: effectiveTotal,
              remainingAmount: remainingAmount,
              paidAmount: paidAmount,
              paidCount: paidCount,
              totalCount: totalCount,
              progress: progress,
              isFullySettled: isFullySettled,
            ),

            // ── UX Enhancement: Next Due Action Card
            if (nextDue != null) ...[
              const SizedBox(height: 20),
              _buildNextDueCard(context, nextDue, plan),
            ],

            const SizedBox(height: 28),

            // ── Filter Segmented Tabs
            _buildSegmentedFilter(
              totalCount: totalCount,
              unpaidCount: unpaidCount,
              paidCount: paidCount,
            ),
            const SizedBox(height: 16),

            // ── Installments Clean Timeline List
            if (displayedInstallments.isEmpty)
              _buildEmptyState()
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayedInstallments.length,
                  separatorBuilder: (context, _) => const Divider(
                    height: 1,
                    thickness: 1,
                    color: _divider,
                  ),
                  itemBuilder: (context, index) {
                    final inst = displayedInstallments[index];
                    final originalIndex = sortedInstallments.indexOf(inst);
                    return _buildInstallmentRow(
                      context: context,
                      inst: inst,
                      plan: plan,
                      monthNumber: originalIndex + 1,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Clean Transparent AppBar ─────────────────────────────────────
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    EMIPlan plan,
    double remainingAmount,
    List<EMIInstallment> allInstallments,
  ) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Center(
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: _textPrimary,
            ),
            tooltip: 'Back',
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      actions: [
        if (remainingAmount > 0)
          TextButton(
            onPressed: () => _confirmPreclose(context, ref),
            child: const Text(
              'Preclose',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _emerald,
              ),
            ),
          ),
        PopupMenuButton<String>(
          icon: const Icon(
            Icons.more_horiz_rounded,
            color: _textPrimary,
            size: 22,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: _border),
          ),
          elevation: 4,
          surfaceTintColor: Colors.transparent,
          color: Colors.white,
          onSelected: (value) {
            if (value == 'edit_plan') {
              showDialog(
                context: context,
                builder: (context) => AddEMIDialog(
                  existingPlan: plan,
                  existingInstallments: allInstallments,
                ),
              );
            } else if (value == 'edit_date') {
              _editStartDate(context, ref, plan);
            } else if (value == 'preclose') {
              _confirmPreclose(context, ref);
            } else if (value == 'delete') {
              _confirmDelete(context, ref);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit_plan',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 16, color: _primary),
                  SizedBox(width: 10),
                  Text('Edit Plan',
                      style: TextStyle(fontSize: 13, color: _textPrimary)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit_date',
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 16, color: _textSecondary),
                  SizedBox(width: 10),
                  Text('Change Start Date',
                      style: TextStyle(fontSize: 13, color: _textPrimary)),
                ],
              ),
            ),
            if (remainingAmount > 0)
              const PopupMenuItem(
                value: 'preclose',
                child: Row(
                  children: [
                    Icon(Icons.done_all_rounded, size: 16, color: _emerald),
                    SizedBox(width: 10),
                    Text('Preclose Plan',
                        style: TextStyle(fontSize: 13, color: _textPrimary)),
                  ],
                ),
              ),
            const PopupMenuDivider(height: 1),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline_rounded,
                      size: 16, color: _danger),
                  SizedBox(width: 10),
                  Text('Delete Plan',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _danger)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  // ── Clean Typography Header (Airy & Natural) ──────────────────────
  Widget _buildPlanHeader({
    required EMIPlan plan,
    required double effectiveTotal,
    required double remainingAmount,
    required double paidAmount,
    required int paidCount,
    required int totalCount,
    required double progress,
    required bool isFullySettled,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Provider Eyebrow & Status
        Row(
          children: [
            Text(
              plan.provider.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: _textMuted,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isFullySettled ? _emeraldLight : _primarySoft,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isFullySettled ? _emeraldBorder : _border,
                ),
              ),
              child: Text(
                isFullySettled ? 'COMPLETED' : 'ACTIVE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: isFullySettled ? _emerald : _primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Plan Title
        Text(
          plan.title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        // Balance Big Typography
        const Text(
          'REMAINING BALANCE',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: _textSubtle,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '₹${remainingAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                color: _textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'of ₹${effectiveTotal.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Slender Progress Track
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Container(
            height: 5,
            color: _track,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  color: isFullySettled ? _emerald : _primary,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Progress Details & Start Date Subtitle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$paidCount of $totalCount paid (${(progress * 100).toInt()}%)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _textMuted,
              ),
            ),
            InkWell(
              onTap: () => _editStartDate(context, ref, plan),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 11,
                      color: _textSubtle,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Since ${DateFormat('MMM yyyy').format(plan.startDate)}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── UX Enhancement: Direct Next Due Card ─────────────────────────
  Widget _buildNextDueCard(
      BuildContext context, EMIInstallment nextDue, EMIPlan plan) {
    final now = DateTime.now();
    final isCurrentMonth =
        nextDue.dueDate.year == now.year && nextDue.dueDate.month == now.month;
    final isOverdue = nextDue.dueDate
            .isBefore(DateTime(now.year, now.month, now.day)) &&
        !isCurrentMonth;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: Icon(
              isOverdue
                  ? Icons.error_outline_rounded
                  : (isCurrentMonth
                      ? Icons.timelapse_rounded
                      : Icons.event_repeat_rounded),
              color: isOverdue
                  ? _danger
                  : (isCurrentMonth ? _amber : _primary),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isOverdue
                          ? 'OVERDUE INSTALLMENT'
                          : (isCurrentMonth
                              ? 'DUE THIS MONTH'
                              : 'UPCOMING INSTALLMENT'),
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.9,
                        color: isOverdue
                            ? _danger
                            : (isCurrentMonth ? _amber : _textMuted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('MMMM yyyy').format(nextDue.dueDate)} • ₹${nextDue.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () =>
                ref.read(emiProvider.notifier).payInstallment(nextDue, plan),
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Mark Paid',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Segmented Control Filter ─────────────────────────────────────
  Widget _buildSegmentedFilter({
    required int totalCount,
    required int unpaidCount,
    required int paidCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _primarySoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _buildSegmentItem(0, 'All ($totalCount)'),
          _buildSegmentItem(1, 'Unpaid ($unpaidCount)'),
          _buildSegmentItem(2, 'Paid ($paidCount)'),
        ],
      ),
    );
  }

  Widget _buildSegmentItem(int index, String label) {
    final isSelected = _filterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filterIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x0F0F172A),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? _textPrimary : _textMuted,
            ),
          ),
        ),
      ),
    );
  }

  // ── Clean Installment Row ────────────────────────────────────────
  Widget _buildInstallmentRow({
    required BuildContext context,
    required EMIInstallment inst,
    required EMIPlan plan,
    required int monthNumber,
  }) {
    final now = DateTime.now();
    final isCurrentMonth =
        inst.dueDate.year == now.year && inst.dueDate.month == now.month;
    final isOverdue = !inst.isPaid &&
        inst.dueDate
            .isBefore(DateTime(now.year, now.month, now.day)) &&
        !isCurrentMonth;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          // Indicator Bullet
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: inst.isPaid
                  ? _emeraldLight
                  : (isOverdue
                      ? _dangerLight
                      : (isCurrentMonth ? _amberLight : _panel)),
              shape: BoxShape.circle,
              border: Border.all(
                color: inst.isPaid
                    ? _emeraldBorder
                    : (isOverdue
                        ? _dangerBorder
                        : (isCurrentMonth ? _amberBorder : _border)),
              ),
            ),
            child: Center(
              child: inst.isPaid
                  ? const Icon(Icons.check_rounded,
                      size: 15, color: _emerald)
                  : Text(
                      '$monthNumber',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isOverdue
                            ? _danger
                            : (isCurrentMonth ? _amber : _textMuted),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Date & Contextual Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(inst.dueDate),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: inst.isPaid ? _textMuted : _textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                if (inst.isPaid)
                  const Text(
                    'Paid',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _emerald,
                    ),
                  )
                else if (isOverdue)
                  const Text(
                    'Overdue',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _danger,
                    ),
                  )
                else if (isCurrentMonth)
                  const Text(
                    'Due this month',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _amber,
                    ),
                  )
                else
                  Text(
                    'Due ${DateFormat('dd MMM').format(inst.dueDate)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: _textSubtle,
                    ),
                  ),
              ],
            ),
          ),

          // Amount & Inline Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '₹${inst.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: inst.isPaid ? _textMuted : _textPrimary,
                ),
              ),
              const SizedBox(width: 10),

              // Action: Pay or Unpay
              if (inst.isPaid)
                InkWell(
                  onTap: () => ref
                      .read(emiProvider.notifier)
                      .unpayInstallment(inst),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: _panel,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _border),
                    ),
                    child: const Text(
                      'Unpay',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: _textMuted,
                      ),
                    ),
                  ),
                )
              else
                FilledButton(
                  onPressed: () => ref
                      .read(emiProvider.notifier)
                      .payInstallment(inst, plan),
                  style: FilledButton.styleFrom(
                    backgroundColor: _emerald,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  child: const Text(
                    'Pay',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Empty State ──────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.verified_outlined,
            color: _emerald,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            _filterIndex == 1
                ? 'All Caught Up!'
                : 'No Installments to Display',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _filterIndex == 1
                ? 'All monthly installments for this plan are marked as paid.'
                : 'Installments will show up here once configured.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: _textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ── Clean Preclose Dialog ────────────────────────────────────────
  void _confirmPreclose(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: _border),
        ),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Preclose Plan',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This will mark all remaining unpaid installments as paid. Individual transactions will not be recorded for prior months.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: _textMuted,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(
                            color: _textMuted, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      ref
                          .read(emiProvider.notifier)
                          .preclosePlan(widget.planId);
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _emerald,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Preclose All',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Clean Delete Dialog ──────────────────────────────────────────
  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: _border),
        ),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Delete Plan',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _danger,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This will permanently remove this plan and its installment schedule. Any existing ledger transactions will remain safe.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: _textMuted,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(
                            color: _textMuted, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      ref
                          .read(emiProvider.notifier)
                          .deletePlan(widget.planId);
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Close screen
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: _danger,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Delete Plan',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Edit Start Date ──────────────────────────────────────────────
  Future<void> _editStartDate(
      BuildContext context, WidgetRef ref, EMIPlan plan) async {
    final date = await showDatePicker(
      context: context,
      initialDate: plan.startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primary,
              onPrimary: Colors.white,
              onSurface: _textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      await ref.read(emiProvider.notifier).updatePlanStartDate(plan, date);
    }
  }

}
