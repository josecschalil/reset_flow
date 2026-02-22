import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reset_flow/models/emi_model.dart';
import 'package:reset_flow/models/financial_transaction.dart';
import 'package:reset_flow/services/database_helper.dart';
import 'package:reset_flow/providers/monetary_provider.dart';

class EMIState {
  final List<EMIPlan> plans;
  final Map<String, List<EMIInstallment>> installments; // planId -> List of installments
  final bool isLoading;

  EMIState({
    required this.plans,
    required this.installments,
    this.isLoading = false,
  });

  EMIState copyWith({
    List<EMIPlan>? plans,
    Map<String, List<EMIInstallment>>? installments,
    bool? isLoading,
  }) {
    return EMIState(
      plans: plans ?? this.plans,
      installments: installments ?? this.installments,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class EMINotifier extends StateNotifier<EMIState> {
  final Ref _ref;

  EMINotifier(this._ref) : super(EMIState(plans: [], installments: {})) {
    loadEMIs();
  }

  Future<void> loadEMIs() async {
    state = state.copyWith(isLoading: true);
    final plansMap = await DatabaseHelper.instance.getEMIPlans();
    final plans = plansMap.map((m) => EMIPlan.fromMap(m)).toList();
    
    final installmentsMap = <String, List<EMIInstallment>>{};
    for (var plan in plans) {
      final instsMap = await DatabaseHelper.instance.getInstallmentsForPlan(plan.id);
      installmentsMap[plan.id] = instsMap.map((m) => EMIInstallment.fromMap(m)).toList();
    }

    state = state.copyWith(plans: plans, installments: installmentsMap, isLoading: false);
  }

  Future<void> addEMIPlan({
    required String provider,
    required String title,
    required double totalAmount,
    required int installmentCount,
    required DateTime startDate,
    required String type,
    List<double>? customAmounts, // If null, distribute evenly
  }) async {
    final plan = EMIPlan(
      provider: provider,
      title: title,
      totalAmount: totalAmount,
      installmentCount: installmentCount,
      startDate: startDate,
      type: type,
    );

    await DatabaseHelper.instance.insertEMIPlan(plan.toMap());

    // Generate installments
    final installments = <EMIInstallment>[];
    if (customAmounts != null && customAmounts.length == installmentCount) {
      for (int i = 0; i < installmentCount; i++) {
        installments.add(EMIInstallment(
          planId: plan.id,
          amount: customAmounts[i],
          dueDate: DateTime(startDate.year, startDate.month + i, startDate.day),
        ));
      }
    } else {
      double baseAmount = (totalAmount / installmentCount).floorToDouble();
      double remainder = totalAmount - (baseAmount * installmentCount);
      for (int i = 0; i < installmentCount; i++) {
        double amount = baseAmount + (i == 0 ? remainder : 0);
        installments.add(EMIInstallment(
          planId: plan.id,
          amount: amount,
          dueDate: DateTime(startDate.year, startDate.month + i, startDate.day),
        ));
      }
    }

    for (var inst in installments) {
      await DatabaseHelper.instance.insertEMIInstallment(inst.toMap());
    }

    await loadEMIs();
    _ref.read(monetaryProvider.notifier).loadTransactions(); // To reflect in net balance
  }

  Future<void> payInstallment(EMIInstallment installment, EMIPlan plan) async {
    if (installment.isPaid) return;

    // 2. Update installment
    final updatedInstallment = EMIInstallment(
      id: installment.id,
      planId: installment.planId,
      amount: installment.amount,
      dueDate: installment.dueDate,
      isPaid: true,
      transactionId: 'EMI_PAID', // Generic marker
    );

    await DatabaseHelper.instance.updateEMIInstallment(updatedInstallment.toMap());
    await loadEMIs();
    _ref.read(monetaryProvider.notifier).loadTransactions(); // To refresh net balance
  }

  Future<void> unpayInstallment(EMIInstallment installment) async {
    if (!installment.isPaid) return;

    // 2. Update installment status
    final updatedInstallment = EMIInstallment(
      id: installment.id,
      planId: installment.planId,
      amount: installment.amount,
      dueDate: installment.dueDate,
      isPaid: false,
      transactionId: null,
    );

    await DatabaseHelper.instance.updateEMIInstallment(updatedInstallment.toMap());
    await loadEMIs();
    _ref.read(monetaryProvider.notifier).loadTransactions(); // To refresh net balance
  }

  Future<void> preclosePlan(String planId) async {
    final installments = state.installments[planId] ?? [];
    final unpaid = installments.where((i) => !i.isPaid).toList();
    
    if (unpaid.isEmpty) return;

    final plan = state.plans.firstWhere((p) => p.id == planId);

    // We simply mark all as paid without creating individual transactions
    // because preclosure usually involves a single bulk settlement which 
    // the user might track manually or we can add one big closure transaction.
    // For simplicity, let's just mark them as paid.
    for (var inst in unpaid) {
      final updated = EMIInstallment(
        id: inst.id,
        planId: inst.planId,
        amount: inst.amount,
        dueDate: inst.dueDate,
        isPaid: true,
        transactionId: 'PRECLOSED', // Pseudo ID for preclosure
      );
      await DatabaseHelper.instance.updateEMIInstallment(updated.toMap());
    }

    await loadEMIs();
  }

  Future<void> updateInstallmentAmount(String installmentId, double newAmount) async {
    // Find the installment to get its planId and other data
    EMIInstallment? target;
    for (var list in state.installments.values) {
      target = list.cast<EMIInstallment?>().firstWhere((i) => i?.id == installmentId, orElse: () => null);
      if (target != null) break;
    }

    if (target == null) return;

    final updated = EMIInstallment(
      id: target.id,
      planId: target.planId,
      amount: newAmount,
      dueDate: target.dueDate,
      isPaid: target.isPaid,
      transactionId: target.transactionId,
    );

    await DatabaseHelper.instance.updateEMIInstallment(updated.toMap());
    await loadEMIs();
  }

  Future<void> deletePlan(String planId) async {
    await DatabaseHelper.instance.deleteEMIPlan(planId);
    await loadEMIs();
    _ref.read(monetaryProvider.notifier).loadTransactions();
  }
}

final emiProvider = StateNotifierProvider<EMINotifier, EMIState>((ref) {
  return EMINotifier(ref);
});
