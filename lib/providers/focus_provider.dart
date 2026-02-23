import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reset_flow/models/focus_session.dart';
import 'package:reset_flow/services/database_helper.dart';

class FocusState {
  final List<FocusSession> sessions;
  final bool isLoading;

  FocusState({
    required this.sessions,
    this.isLoading = false,
  });

  FocusState copyWith({
    List<FocusSession>? sessions,
    bool? isLoading,
  }) {
    return FocusState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final focusProvider = StateNotifierProvider<FocusNotifier, FocusState>((ref) {
  return FocusNotifier(DatabaseHelper.instance);
});

class FocusNotifier extends StateNotifier<FocusState> {
  final DatabaseHelper dbHelper;

  FocusNotifier(this.dbHelper) : super(FocusState(sessions: [], isLoading: true)) {
    loadSessions();
  }

  Future<void> loadSessions() async {
    state = state.copyWith(isLoading: true);
    final sessions = await dbHelper.getAllFocusSessions();
    state = state.copyWith(sessions: sessions, isLoading: false);
  }

  Future<void> addSession(FocusSession session) async {
    await dbHelper.insertFocusSession(session);
    await loadSessions();
  }

  Future<void> deleteSessionsByMonth(int year, int month) async {
    await dbHelper.deleteFocusSessionsByMonth(year, month);
    await loadSessions();
  }

  Future<void> deleteSessionsByDay(String dayStr) async {
    await dbHelper.deleteFocusSessionsByDay(dayStr);
    await loadSessions();
  }

  Future<void> clearAllSessions() async {
    await dbHelper.clearAllFocusSessions();
    await loadSessions();
  }
}
