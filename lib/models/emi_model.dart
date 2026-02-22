import 'package:uuid/uuid.dart';

enum EMIStatus { active, completed, cancelled }

class EMIPlan {
  final String id;
  final String provider; // General name (Bank, Person, etc.)
  final String title;
  final double totalAmount;
  final int installmentCount;
  final DateTime startDate;
  final EMIStatus status;
  final String type; // 'credit' (he owes me) or 'debit' (I owe)

  EMIPlan({
    String? id,
    required this.provider,
    required this.title,
    required this.totalAmount,
    required this.installmentCount,
    required this.startDate,
    this.status = EMIStatus.active,
    required this.type,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'personName': provider, // Keep DB column name as personName for compatibility
      'title': title,
      'totalAmount': totalAmount,
      'installmentCount': installmentCount,
      'startDate': startDate.toIso8601String(),
      'status': status.name,
      'type': type,
    };
  }

  factory EMIPlan.fromMap(Map<String, dynamic> map) {
    return EMIPlan(
      id: map['id'],
      provider: map['personName'] ?? 'Unknown',
      title: map['title'] ?? '',
      totalAmount: map['totalAmount']?.toDouble() ?? 0.0,
      installmentCount: map['installmentCount'] ?? 0,
      startDate: DateTime.parse(map['startDate']),
      status: EMIStatus.values.byName(map['status']),
      type: map['type'] ?? 'debit',
    );
  }
}

class EMIInstallment {
  final String id;
  final String planId;
  final double amount;
  final DateTime dueDate;
  final bool isPaid;
  final String? transactionId;

  EMIInstallment({
    String? id,
    required this.planId,
    required this.amount,
    required this.dueDate,
    this.isPaid = false,
    this.transactionId,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'planId': planId,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'isPaid': isPaid ? 1 : 0,
      'transactionId': transactionId,
    };
  }

  factory EMIInstallment.fromMap(Map<String, dynamic> map) {
    return EMIInstallment(
      id: map['id'],
      planId: map['planId'],
      amount: map['amount']?.toDouble() ?? 0.0,
      dueDate: DateTime.parse(map['dueDate']),
      isPaid: (map['isPaid'] ?? 0) == 1,
      transactionId: map['transactionId'],
    );
  }
}
