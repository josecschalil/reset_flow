import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:reset_flow/models/goal.dart';
import 'package:reset_flow/models/daily_log.dart';
import 'package:reset_flow/models/rule.dart';
import 'package:reset_flow/models/due.dart';
import 'package:reset_flow/models/financial_transaction.dart';
import 'package:reset_flow/models/expense.dart';
import 'package:reset_flow/models/focus_session.dart';
import 'package:flutter/material.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('reset_flow.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    final db = await openDatabase(
      path,
      version: 10,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );

    // Double check column existence (failsafe for interrupted migrations)
    final ftTables = await db.rawQuery("PRAGMA table_info(financial_transactions)");
    if (!ftTables.any((column) => column['name'] == 'parentId')) {
      await db.execute('ALTER TABLE financial_transactions ADD COLUMN parentId TEXT');
    }

    final goalTables = await db.rawQuery("PRAGMA table_info(goals)");
    if (!goalTables.any((column) => column['name'] == 'orderIndex')) {
      await db.execute('ALTER TABLE goals ADD COLUMN orderIndex INTEGER DEFAULT 0');
    }
    if (!goalTables.any((column) => column['name'] == 'isOneTime')) {
      await db.execute('ALTER TABLE goals ADD COLUMN isOneTime INTEGER DEFAULT 0');
    }

    // Failsafe: create focus_sessions table if not exists (e.g., skipped migration)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS focus_sessions (
        id TEXT PRIMARY KEY,
        startTime TEXT NOT NULL,
        durationMinutes INTEGER NOT NULL,
        status TEXT NOT NULL,
        rating INTEGER NOT NULL
      )
    ''');

    return db;
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS rules (
          id TEXT PRIMARY KEY,
          title TEXT,
          solutions TEXT,
          createdAt TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS dues (
          id TEXT PRIMARY KEY,
          title TEXT,
          deadline TEXT,
          isCompleted INTEGER,
          createdAt TEXT
        )
      ''');
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS financial_transactions (
          id TEXT PRIMARY KEY,
          personName TEXT,
          amount REAL,
          type TEXT,
          date TEXT,
          label TEXT
        )
      ''');
    }

    if (oldVersion < 5) {
      await db.execute('ALTER TABLE financial_transactions ADD COLUMN parentId TEXT');
    }

    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE emi_plans (
          id TEXT PRIMARY KEY,
          personName TEXT,
          title TEXT,
          totalAmount REAL,
          installmentCount INTEGER,
          startDate TEXT,
          status TEXT,
          type TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE emi_installments (
          id TEXT PRIMARY KEY,
          planId TEXT,
          amount REAL,
          dueDate TEXT,
          isPaid INTEGER,
          transactionId TEXT,
          FOREIGN KEY(planId) REFERENCES emi_plans(id) ON DELETE CASCADE
        )
      ''');
    }

    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE expense_categories (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          iconCodePoint INTEGER NOT NULL,
          colorValue INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE expenses (
          id TEXT PRIMARY KEY,
          categoryId TEXT NOT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          label TEXT,
          FOREIGN KEY(categoryId) REFERENCES expense_categories(id) ON DELETE CASCADE
        )
      ''');

      // Populate default categories
      final defaultCategories = [
        ['Food', Icons.restaurant.codePoint, Colors.orange.value],
        ['Rent', Icons.home.codePoint, Colors.blue.value],
        ['Travel', Icons.flight.codePoint, Colors.green.value],
        ['Health', Icons.medical_services.codePoint, Colors.red.value],
        ['Entertainment', Icons.movie.codePoint, Colors.purple.value],
        ['Shopping', Icons.shopping_bag.codePoint, Colors.pink.value],
        ['Others', Icons.more_horiz.codePoint, Colors.grey.value],
      ];

      for (var cat in defaultCategories) {
        await db.insert('expense_categories', {
          'id': DateTime.now().millisecondsSinceEpoch.toString() + cat[0].toString(),
          'name': cat[0],
          'iconCodePoint': cat[1],
          'colorValue': cat[2],
        });
      }
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE goals (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        isActionBased INTEGER NOT NULL,
        activeDays TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        orderIndex INTEGER DEFAULT 0,
        isOneTime INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_logs (
        id TEXT PRIMARY KEY,
        goalId TEXT NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        completedAt TEXT,
        FOREIGN KEY(goalId) REFERENCES goals(id)
      )
    ''');

    // Tab 3: Rules
    await db.execute('''
      CREATE TABLE rules (
        id TEXT PRIMARY KEY,
        title TEXT,
        solutions TEXT,
        createdAt TEXT
      )
    ''');

    // Tab 4: Dues (Deadlines)
    await db.execute('''
      CREATE TABLE dues (
        id TEXT PRIMARY KEY,
        title TEXT,
        deadline TEXT,
        isCompleted INTEGER,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE financial_transactions (
        id TEXT PRIMARY KEY,
        personName TEXT,
        amount REAL,
        type TEXT,
        date TEXT,
        label TEXT,
        parentId TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE emi_plans (
        id TEXT PRIMARY KEY,
        personName TEXT,
        title TEXT,
        totalAmount REAL,
        installmentCount INTEGER,
        startDate TEXT,
        status TEXT,
        type TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE emi_installments (
        id TEXT PRIMARY KEY,
        planId TEXT,
        amount REAL,
        dueDate TEXT,
        isPaid INTEGER,
        transactionId TEXT,
        FOREIGN KEY(planId) REFERENCES emi_plans(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE expense_categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        iconCodePoint INTEGER NOT NULL,
        colorValue INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        categoryId TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        label TEXT,
        FOREIGN KEY(categoryId) REFERENCES expense_categories(id) ON DELETE CASCADE
      )
    ''');

    // Populate default categories
    final defaultCategories = [
      ['Food', Icons.restaurant.codePoint, Colors.orange.value],
      ['Rent', Icons.home.codePoint, Colors.blue.value],
      ['Travel', Icons.flight.codePoint, Colors.green.value],
      ['Health', Icons.medical_services.codePoint, Colors.red.value],
      ['Entertainment', Icons.movie.codePoint, Colors.purple.value],
      ['Shopping', Icons.shopping_bag.codePoint, Colors.pink.value],
      ['Others', Icons.more_horiz.codePoint, Colors.grey.value],
    ];

    for (var cat in defaultCategories) {
      await db.insert('expense_categories', {
        'id': DateTime.now().millisecondsSinceEpoch.toString() + cat[0].toString(),
        'name': cat[0],
        'iconCodePoint': cat[1],
        'colorValue': cat[2],
      });
    }

    // Tab Focus: Constellations
    await db.execute('''
      CREATE TABLE focus_sessions (
        id TEXT PRIMARY KEY,
        startTime TEXT NOT NULL,
        durationMinutes INTEGER NOT NULL,
        status TEXT NOT NULL,
        rating INTEGER NOT NULL
      )
    ''');
  }

  // --- GOAL CRUD ---
  Future<int> insertGoal(Goal goal) async {
    final db = await instance.database;
    return await db.insert('goals', goal.toMap());
  }

  Future<List<Goal>> getAllGoals() async {
    final db = await instance.database;
    final maps = await db.query('goals');
    return maps.map((map) => Goal.fromMap(map)).toList();
  }

  Future<int> updateGoal(Goal goal) async {
    final db = await instance.database;
    return await db.update(
      'goals',
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<int> deleteGoal(String id) async {
    final db = await instance.database;
    return await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  // --- DAILY LOG CRUD ---
  Future<int> insertLog(DailyLog log) async {
    final db = await instance.database;
    return await db.insert('daily_logs', log.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<DailyLog>> getLogsByDate(String date) async {
    final db = await instance.database;
    final maps = await db.query(
      'daily_logs',
      where: 'date = ?',
      whereArgs: [date],
    );
    return maps.map((map) => DailyLog.fromMap(map)).toList();
  }

  Future<int> updateLogStatus(String id, String status, DateTime? completedAt) async {
    final db = await instance.database;
    return await db.update(
      'daily_logs',
      {
        'status': status,
        'completedAt': completedAt?.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<List<DailyLog>> getLogsForGoal(String goalId) async {
    final db = await instance.database;
    final maps = await db.query(
      'daily_logs',
      where: 'goalId = ?',
      whereArgs: [goalId],
    );
    return maps.map((map) => DailyLog.fromMap(map)).toList();
  }

  Future<int> deleteLogsForGoal(String goalId) async {
    final db = await instance.database;
    return await db.delete(
      'daily_logs',
      where: 'goalId = ?',
      whereArgs: [goalId],
    );
  }

  // --- RULES CRUD ---
  Future<int> insertRule(AppRule rule) async {
    final db = await instance.database;
    return await db.insert('rules', rule.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<AppRule>> getAllRules() async {
    final db = await instance.database;
    final maps = await db.query('rules', orderBy: 'createdAt DESC');
    return maps.map((map) => AppRule.fromMap(map)).toList();
  }

  Future<int> updateRule(AppRule rule) async {
    final db = await instance.database;
    return await db.update('rules', rule.toMap(), where: 'id = ?', whereArgs: [rule.id]);
  }

  Future<int> deleteRule(String id) async {
    final db = await instance.database;
    return await db.delete('rules', where: 'id = ?', whereArgs: [id]);
  }

  // --- DUES CRUD ---
  Future<int> insertDue(Due due) async {
    final db = await instance.database;
    return await db.insert('dues', due.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Due>> getAllDues() async {
    final db = await instance.database;
    final maps = await db.query('dues', orderBy: 'deadline ASC'); // Sorted by deadline
    return maps.map((map) => Due.fromMap(map)).toList();
  }

  Future<int> updateDue(Due due) async {
    final db = await instance.database;
    return await db.update('dues', due.toMap(), where: 'id = ?', whereArgs: [due.id]);
  }

  Future<int> deleteDue(String id) async {
    final db = await instance.database;
    return await db.delete('dues', where: 'id = ?', whereArgs: [id]);
  }

  // --- FINANCIAL TRANSACTIONS CRUD ---
  Future<int> insertTransaction(FinancialTransaction tx) async {
    final db = await instance.database;
    try {
      return await db.insert('financial_transactions', tx.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      if (e.toString().contains('no column named parentId')) {
        await db.execute('ALTER TABLE financial_transactions ADD COLUMN parentId TEXT');
        return await db.insert('financial_transactions', tx.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      rethrow;
    }
  }

  Future<List<FinancialTransaction>> getAllTransactions() async {
    final db = await instance.database;
    final maps = await db.query('financial_transactions', orderBy: 'date DESC');
    return maps.map((map) => FinancialTransaction.fromMap(map)).toList();
  }

  Future<int> deleteTransaction(String id) async {
    final db = await instance.database;
    return await db.delete('financial_transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTransactionsForPerson(String personName) async {
    final db = await instance.database;
    return await db.delete('financial_transactions', where: 'personName = ?', whereArgs: [personName]);
  }

  // --- EMI CRUD ---
  Future<int> insertEMIPlan(Map<String, dynamic> plan) async {
    final db = await instance.database;
    return await db.insert('emi_plans', plan);
  }

  Future<int> insertEMIInstallment(Map<String, dynamic> installment) async {
    final db = await instance.database;
    return await db.insert('emi_installments', installment);
  }

  Future<List<Map<String, dynamic>>> getEMIPlans() async {
    final db = await instance.database;
    return await db.query('emi_plans');
  }

  Future<List<Map<String, dynamic>>> getInstallmentsForPlan(String planId) async {
    final db = await instance.database;
    return await db.query('emi_installments', where: 'planId = ?', whereArgs: [planId], orderBy: 'dueDate ASC');
  }

  Future<int> updateEMIInstallment(Map<String, dynamic> installment) async {
    final db = await instance.database;
    return await db.update('emi_installments', installment, where: 'id = ?', whereArgs: [installment['id']]);
  }

  Future<int> deleteEMIPlan(String id) async {
    final db = await instance.database;
    await db.delete('emi_installments', where: 'planId = ?', whereArgs: [id]);
    return await db.delete('emi_plans', where: 'id = ?', whereArgs: [id]);
  }

  // --- EXPENSE CATEGORIES CRUD ---
  Future<int> insertExpenseCategory(ExpenseCategory category) async {
    final db = await instance.database;
    return await db.insert('expense_categories', category.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ExpenseCategory>> getAllExpenseCategories() async {
    final db = await instance.database;
    final maps = await db.query('expense_categories', orderBy: 'name ASC');
    return maps.map((map) => ExpenseCategory.fromMap(map)).toList();
  }

  Future<int> updateExpenseCategory(ExpenseCategory category) async {
    final db = await instance.database;
    return await db.update('expense_categories', category.toMap(), where: 'id = ?', whereArgs: [category.id]);
  }

  Future<int> deleteExpenseCategory(String id) async {
    final db = await instance.database;
    return await db.delete('expense_categories', where: 'id = ?', whereArgs: [id]);
  }

  // --- EXPENSES CRUD ---
  Future<int> insertExpense(Expense expense) async {
    final db = await instance.database;
    return await db.insert('expenses', expense.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await instance.database;
    final maps = await db.query('expenses', orderBy: 'date DESC');
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await instance.database;
    return await db.update('expenses', expense.toMap(), where: 'id = ?', whereArgs: [expense.id]);
  }

  Future<int> deleteExpense(String id) async {
    final db = await instance.database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // --- FOCUS SESSIONS (CONSTELLATIONS) ---
  Future<void> insertFocusSession(FocusSession session) async {
    final db = await instance.database;
    await db.insert('focus_sessions', session.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<FocusSession>> getAllFocusSessions() async {
    final db = await instance.database;
    final maps = await db.query('focus_sessions', orderBy: 'startTime DESC');
    return maps.map((map) => FocusSession.fromMap(map)).toList();
  }

  /// Delete all sessions for a given year+month
  Future<int> deleteFocusSessionsByMonth(int year, int month) async {
    final db = await instance.database;
    final prefix = '${year.toString().padLeft(4,'0')}-${month.toString().padLeft(2,'0')}';
    return await db.delete(
      'focus_sessions',
      where: "startTime LIKE ?",
      whereArgs: ['$prefix%'],
    );
  }

  /// Delete all sessions for a given date string (yyyy-MM-dd)
  Future<int> deleteFocusSessionsByDay(String dayStr) async {
    final db = await instance.database;
    return await db.delete(
      'focus_sessions',
      where: "startTime LIKE ?",
      whereArgs: ['$dayStr%'],
    );
  }

  /// Clear every focus session
  Future<int> clearAllFocusSessions() async {
    final db = await instance.database;
    return await db.delete('focus_sessions');
  }
}
