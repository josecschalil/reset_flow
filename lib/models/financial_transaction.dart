import 'package:uuid/uuid.dart';

enum TransactionType { credit, debit }

class FinancialTransaction {
  final String id;
  final String personName;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String label;
  final String? parentId;

  FinancialTransaction({
    String? id,
    required this.personName,
    required this.amount,
    required this.type,
    required this.date,
    this.label = '',
    this.parentId,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'personName': personName,
      'amount': amount,
      'type': type.name,
      'date': date.toIso8601String(),
      'label': label,
      'parentId': parentId,
    };
  }

  factory FinancialTransaction.fromMap(Map<String, dynamic> map) {
    return FinancialTransaction(
      id: map['id'],
      personName: map['personName'],
      amount: map['amount']?.toDouble() ?? 0.0,
      type: TransactionType.values.byName(map['type']),
      date: DateTime.parse(map['date']),
      label: map['label'] ?? '',
      parentId: map['parentId'],
    );
  }

  FinancialTransaction copyWith({
    String? personName,
    double? amount,
    TransactionType? type,
    DateTime? date,
    String? label,
    String? parentId,
  }) {
    return FinancialTransaction(
      id: id,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      label: label ?? this.label,
      parentId: parentId ?? this.parentId,
    );
  }
}
