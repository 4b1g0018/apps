// lib/services/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' show join;

import '../models/workout_log_model.dart';
import '../models/user_model.dart';
import '../models/weight_log_model.dart';
import '../models/set_log_model.dart'; 

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();
  static Database? _db;

  Future<Database> get db async => _db ??= await initDB();

  Future<Database> initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'data.db');
    return await openDatabase(
      path,
      version: 8, // 我們最新的版本號
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  // onCreate 專門處理第一次建立
  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account TEXT UNIQUE, password TEXT, height TEXT, weight TEXT,
        age TEXT, bmi TEXT, fat TEXT, gender TEXT, bmr TEXT,
        goalWeight TEXT, fitnessLevel TEXT 
      )
    ''');
    await db.execute('''
      CREATE TABLE workout_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exerciseName TEXT, totalSets INTEGER,
        completedAt TEXT, bodyPart TEXT 
      )
    ''');
    await db.execute('''
      CREATE TABLE weight_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        weight REAL NOT NULL, createdAt TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE set_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workoutLogId INTEGER, setNumber INTEGER,
        weight REAL, reps INTEGER
      )
    ''');
  }

  // onUpgrade 專門處理版本間的升級
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 這裡的邏輯是，如果舊版本比某個版本號小，就執行對應的更新
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE workout_logs ADD COLUMN bodyPart TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE weight_logs(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          weight REAL NOT NULL, createdAt TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE users ADD COLUMN goalWeight TEXT');
    }
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE users ADD COLUMN fitnessLevel TEXT');
    }
    // 從 v7 (我們上次加 goalWeight 時不小心跳過的版本) 升到 v8
    if (oldVersion < 8) { 
      await db.execute('''
        CREATE TABLE set_logs(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          workoutLogId INTEGER, setNumber INTEGER,
          weight REAL, reps INTEGER
        )
      ''');
    }
  }
  

  // --- User 相關方法 ---
  Future<void> insertUser(Map<String, dynamic> data) async {
    final db = await instance.db;
    await db.insert('users', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<bool> validateUser(String account, String password) async {
    final db = await instance.db;
    final result = await db.query('users', where: 'account = ? AND password = ?', whereArgs: [account, password]);
    return result.isNotEmpty;
  }

  Future<User?> getUserByAccount(String account) async {
    final db = await instance.db;
    final List<Map<String, dynamic>> maps = await db.query('users', where: 'account = ?', whereArgs: [account], limit: 1);
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateUser(User user) async {
    final db = await instance.db;
    return await db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  // --- WorkoutLog 相關方法 ---
  // 【修正】只保留一個 insertWorkoutLog 方法，並且它的回傳型別是 Future<int>
  Future<int> insertWorkoutLog(WorkoutLog log) async {
    final db = await instance.db;
    return await db.insert('workout_logs', log.toMap());
  }

  Future<List<WorkoutLog>> getWorkoutLogs() async {
    final db = await instance.db;
    final List<Map<String, dynamic>> maps = await db.query('workout_logs', orderBy: 'completedAt DESC');
    return List.generate(maps.length, (i) => WorkoutLog.fromMap(maps[i]));
  }

  Future<int> deleteAllWorkoutLogs() async {
    final db = await instance.db;
    return await db.delete('workout_logs');
  }

  // --- WeightLog 相關方法 ---
  Future<void> insertWeightLog(WeightLog log) async {
    final db = await instance.db;
    await db.insert('weight_logs', log.toMap());
  }

  Future<List<WeightLog>> getWeightLogs() async {
    final db = await instance.db;
    final List<Map<String, dynamic>> maps = await db.query('weight_logs', orderBy: 'createdAt DESC');
    return List.generate(maps.length, (i) => WeightLog.fromMap(maps[i]));
  }

  // 【新增】SetLog 相關方法 (放在這裡)
  Future<void> insertSetLog(SetLog log) async {
    final db = await instance.db;
    await db.insert('set_logs', log.toMap());
  }

  Future<List<SetLog>> getSetLogsForWorkout(int workoutLogId) async {
    final db = await instance.db;
    final List<Map<String, dynamic>> maps = await db.query(
      'set_logs',
      where: 'workoutLogId = ?',
      whereArgs: [workoutLogId],
      orderBy: 'setNumber ASC',
    );
    return List.generate(maps.length, (i) {
      return SetLog.fromMap(maps[i]);
    });
  }
}