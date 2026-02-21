import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reset_flow/models/rule.dart';
import 'package:reset_flow/services/database_helper.dart';
import 'package:uuid/uuid.dart';

final ruleProvider = StateNotifierProvider<RuleNotifier, List<AppRule>>((ref) {
  return RuleNotifier(DatabaseHelper.instance);
});

class RuleNotifier extends StateNotifier<List<AppRule>> {
  final DatabaseHelper dbHelper;
  final _uuid = const Uuid();

  RuleNotifier(this.dbHelper) : super([]) {
    loadRules();
  }

  Future<void> loadRules() async {
    final rules = await dbHelper.getAllRules();
    state = rules;
  }

  Future<void> addRule(String title, List<String> solutions) async {
    final newRule = AppRule(
      id: _uuid.v4(),
      title: title,
      solutions: solutions,
      createdAt: DateTime.now(),
    );
    await dbHelper.insertRule(newRule);
    await loadRules();
  }

  Future<void> updateRule(AppRule rule) async {
    await dbHelper.updateRule(rule);
    await loadRules();
  }

  Future<void> deleteRule(String id) async {
    await dbHelper.deleteRule(id);
    await loadRules();
  }
}
