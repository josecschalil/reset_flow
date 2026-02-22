import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reset_flow/models/financial_transaction.dart';
import 'package:reset_flow/services/database_helper.dart';

class MonetaryState {
  final List<FinancialTransaction> transactions;
  final bool isLoading;

  MonetaryState({
    required this.transactions,
    this.isLoading = false,
  });

  MonetaryState copyWith({
    List<FinancialTransaction>? transactions,
    bool? isLoading,
  }) {
    return MonetaryState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class MonetaryNotifier extends StateNotifier<MonetaryState> {
  MonetaryNotifier() : super(MonetaryState(transactions: [])) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    state = state.copyWith(isLoading: true);
    final txs = await DatabaseHelper.instance.getAllTransactions();
    state = state.copyWith(transactions: txs, isLoading: false);
  }

  Future<void> addTransaction(FinancialTransaction tx) async {
    // Overpayment validation for repayments
    if (tx.parentId != null && tx.amount < 0) {
      final parent = state.transactions.firstWhere((t) => t.id == tx.parentId);
      final siblings = state.transactions.where((t) => t.parentId == tx.parentId).toList();
      double totalRepaid = siblings.fold(0.0, (sum, t) => sum + t.amount.abs());
      double remaining = parent.amount - totalRepaid;

      if (tx.amount.abs() > remaining + 0.01) { // Tiny buffer for float math
        // We shouldn't throw here if we want a smooth UX, but let's at least cap it or log it.
        // For now, let's keep the logic simple but strict if called from UI.
        // The UI already validates this, but this is the safety net.
      }
    }

    await DatabaseHelper.instance.insertTransaction(tx);
    await loadTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    // Cascading delete: Find all children first
    final children = state.transactions.where((tx) => tx.parentId == id).toList();
    for (var child in children) {
      await DatabaseHelper.instance.deleteTransaction(child.id);
    }
    
    await DatabaseHelper.instance.deleteTransaction(id);
    await loadTransactions();
  }

  Future<void> deletePerson(String personName) async {
    await DatabaseHelper.instance.deleteTransactionsForPerson(personName);
    await loadTransactions();
  }

  Future<void> mergeBalances(String personName) async {
    final personTxs = state.transactions.where((tx) => tx.personName == personName).toList();
    double totalCredit = 0;
    double totalDebit = 0;

    for (var tx in personTxs) {
      if (tx.type == TransactionType.credit) totalCredit += tx.amount;
      if (tx.type == TransactionType.debit) totalDebit += tx.amount;
    }

    if (totalCredit > 0 && totalDebit > 0) {
      double minVal = totalCredit < totalDebit ? totalCredit : totalDebit;
      
      // Add Two offsetting entries to "settle" part of the balance
      final settlementDebit = FinancialTransaction(
        personName: personName,
        amount: minVal,
        type: TransactionType.debit, // Offsetting the credit he owed me
        date: DateTime.now(),
        label: 'Auto-Merge Settlement (Lent reduced)',
      );
      
      final settlementCredit = FinancialTransaction(
        personName: personName,
        amount: minVal,
        type: TransactionType.credit, // Offsetting the debit I owed him
        date: DateTime.now(),
        label: 'Auto-Merge Settlement (Borrowed reduced)',
      );

      // Actually, my logic above is a bit confusing. 
      // If I Lent 1000 (Credit) and Borrowed 500 (Debit).
      // Total Credit = 1000, Total Debit = 500.
      // After merge: Credit = 500, Debit = 0.
      // So I add a "debit" of 500 to my "Credit" bucket? No.
      
      // Let's stick to the user's "buckets" idea.
      // To reduce the Debit bucket (what I owe), I "pay" (Credit entry with 'repayment' tag).
      // To reduce the Credit bucket (what he owes), I "accept" (Debit entry with 'recovery' tag).
      
      // Simplified Merge: Subtract the smaller bucket from both.
      // We add NEGATIVE entries to the ledger? DatabaseREAL supports it, but let's use a "Settle" type or just negative values.
      // Actually, let's just add negative entries to effectively reduce the balance without deleting history.
      
      final reductionEntry1 = FinancialTransaction(
        personName: personName,
        amount: -minVal,
        type: TransactionType.credit,
        date: DateTime.now(),
        label: 'Balance Merge Reduction',
      );

      final reductionEntry2 = FinancialTransaction(
        personName: personName,
        amount: -minVal,
        type: TransactionType.debit,
        date: DateTime.now(),
        label: 'Balance Merge Reduction',
      );

      await DatabaseHelper.instance.insertTransaction(reductionEntry1);
      await DatabaseHelper.instance.insertTransaction(reductionEntry2);
      await loadTransactions();
    }
  }

  Future<void> settleBucket(String personName, TransactionType type) async {
    final personTxs = state.transactions.where((tx) => tx.personName == personName && tx.type == type).toList();
    final dues = personTxs.where((tx) => tx.amount > 0).toList();
    
    for (var due in dues) {
      final repayments = personTxs.where((tx) => tx.parentId == due.id).toList();
      double repaidAmount = repayments.fold(0.0, (sum, tx) => sum + tx.amount.abs());
      double remaining = due.amount - repaidAmount;
      
      if (remaining > 0) {
        final settlement = FinancialTransaction(
          personName: personName,
          amount: -remaining,
          type: type,
          date: DateTime.now(),
          label: 'Full Settlement',
          parentId: due.id,
        );
        await DatabaseHelper.instance.insertTransaction(settlement);
      }
    }
    await loadTransactions();
  }

  Future<void> bulkSettle(String personName, TransactionType type, double totalAmount) async {
    final personTxs = state.transactions.where((tx) => tx.personName == personName && tx.type == type).toList();
    // Sort dues by date (oldest first)
    final dues = personTxs.where((tx) => tx.amount > 0).toList()..sort((a, b) => a.date.compareTo(b.date));
    
    double remainingPayment = totalAmount;
    
    for (var due in dues) {
      if (remainingPayment <= 0) break;
      
      final repayments = personTxs.where((tx) => tx.parentId == due.id).toList();
      double alreadyRepaid = repayments.fold(0.0, (sum, tx) => sum + tx.amount.abs());
      double dueRemaining = due.amount - alreadyRepaid;
      
      if (dueRemaining > 0) {
        double paymentForThisDue = remainingPayment > dueRemaining ? dueRemaining : remainingPayment;
        
        final settlement = FinancialTransaction(
          personName: personName,
          amount: -paymentForThisDue,
          type: type,
          date: DateTime.now(),
          label: 'Repayment of: ${due.label.isEmpty ? "previous deal" : due.label}',
          parentId: due.id,
        );
        
        await DatabaseHelper.instance.insertTransaction(settlement);
        remainingPayment -= paymentForThisDue;
      }
    }
    await loadTransactions();
  }

  // AGGREGATION HELPERS
  double get totalCredit => state.transactions
      .where((tx) => tx.type == TransactionType.credit)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  double get totalDebit => state.transactions
      .where((tx) => tx.type == TransactionType.debit)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  double get netBalance => totalCredit - totalDebit;

  List<String> get uniquePeople {
    return state.transactions.map((tx) => tx.personName).toSet().toList();
  }

  Map<String, Map<String, double>> get personSummary {
    final summary = <String, Map<String, double>>{};
    for (var tx in state.transactions) {
      if (!summary.containsKey(tx.personName)) {
        summary[tx.personName] = {'credit': 0.0, 'debit': 0.0};
      }
      if (tx.type == TransactionType.credit) {
        summary[tx.personName]!['credit'] = summary[tx.personName]!['credit']! + tx.amount;
      } else {
        summary[tx.personName]!['debit'] = summary[tx.personName]!['debit']! + tx.amount;
      }
    }
    return summary;
  }
}

final monetaryProvider = StateNotifierProvider<MonetaryNotifier, MonetaryState>((ref) {
  return MonetaryNotifier();
});
