import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:reset_flow/models/goal.dart';
import 'package:reset_flow/models/daily_log.dart';
import 'package:reset_flow/models/rule.dart';
import 'package:reset_flow/models/due.dart';
import 'package:reset_flow/models/financial_transaction.dart';

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
      version: 6,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );

    // Double check column existence (failsafe for interrupted migrations)
    final tables = await db.rawQuery("PRAGMA table_info(financial_transactions)");
    final hasParentId = tables.any((column) => column['name'] == 'parentId');
    if (!hasParentId) {
      await db.execute('ALTER TABLE financial_transactions ADD COLUMN parentId TEXT');
    }

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
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE goals (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        isActionBased INTEGER NOT NULL,
        activeDays TEXT NOT NULL,
        createdAt TEXT NOT NULL
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
}
