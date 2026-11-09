import 'package:uuid/uuid.dart';

class AccountBalance {
  final String id;
  final String name;
  final double balance;

  AccountBalance({String? id, required this.name, required this.balance})
      : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'balance': balance,
      };

  factory AccountBalance.fromMap(Map<String, dynamic> map) => AccountBalance(
        id: map['id'],
        name: map['name'] ?? '',
        balance: map['balance']?.toDouble() ?? 0.0,
      );
}
