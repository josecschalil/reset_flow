import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reset_flow/models/due.dart';
import 'package:reset_flow/services/database_helper.dart';
import 'package:uuid/uuid.dart';

final dueProvider = StateNotifierProvider<DueNotifier, List<Due>>((ref) {
  return DueNotifier(DatabaseHelper.instance);
});

class DueNotifier extends StateNotifier<List<Due>> {
  final DatabaseHelper dbHelper;
  final _uuid = const Uuid();

  DueNotifier(this.dbHelper) : super([]) {
    loadDues();
  }

  Future<void> loadDues() async {
    final dues = await dbHelper.getAllDues();
    state = dues;
  }

  Future<void> addDue(String title, DateTime deadline) async {
    final newDue = Due(
      id: _uuid.v4(),
      title: title,
      deadline: deadline,
      isCompleted: false,
      createdAt: DateTime.now(),
    );
    await dbHelper.insertDue(newDue);
    await loadDues();
  }

  Future<void> toggleDueCompletion(Due due) async {
    final updatedDue = Due(
      id: due.id,
      title: due.title,
      deadline: due.deadline,
      isCompleted: !due.isCompleted,
      createdAt: due.createdAt,
    );
    await dbHelper.updateDue(updatedDue);
    await loadDues();
  }

  Future<void> updateDue(Due due) async {
    await dbHelper.updateDue(due);
    await loadDues();
  }

  Future<void> deleteDue(String id) async {
    await dbHelper.deleteDue(id);
    await loadDues();
  }
}
