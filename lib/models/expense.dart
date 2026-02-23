import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ExpenseCategory {
  final String id;
  final String name;
  final int iconCodePoint;
  final int colorValue;

  ExpenseCategory({
    String? id,
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
    };
  }

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) {
    return ExpenseCategory(
      id: map['id'],
      name: map['name'],
      iconCodePoint: map['iconCodePoint'],
      colorValue: map['colorValue'],
    );
  }

  ExpenseCategory copyWith({
    String? name,
    int? iconCodePoint,
    int? colorValue,
  }) {
    return ExpenseCategory(
      id: id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}

class Expense {
  final String id;
  final String categoryId;
  final double amount;
  final DateTime date;
  final String label;

  Expense({
    String? id,
    required this.categoryId,
    required this.amount,
    required this.date,
    this.label = '',
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryId': categoryId,
      'amount': amount,
      'date': date.toIso8601String(),
      'label': label,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      categoryId: map['categoryId'],
      amount: map['amount']?.toDouble() ?? 0.0,
      date: DateTime.parse(map['date']),
      label: map['label'] ?? '',
    );
  }

  Expense copyWith({
    String? categoryId,
    double? amount,
    DateTime? date,
    String? label,
  }) {
    return Expense(
      id: id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      label: label ?? this.label,
    );
  }
}
