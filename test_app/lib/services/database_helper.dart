// lib/services/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' show join;

// 【修正】只導入需要的 model
import '../models/workout_log_model.dart';
import '../models/user_model.dart';
import '../models/weight_log_model.dart';

// SQLite 輔助類別，處理初始化與基本 CRUD
class DatabaseHelper {
  // 單例模式，確保整個 App 只有一個 DatabaseHelper 實例
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();
  static Database? _db;

  Future<Database> get db async => _db ??= await initDB();

  // 初始化資料庫
  Future<Database> initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'data.db');
    return await openDatabase(
      path,
      version: 4, // 【修改】版本號提升至 4
      onCreate: (db, version) async {
        return await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // 舊有的升級邏輯保留
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE workout_logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          exerciseName TEXT,
          totalSets INTEGER,
          completedAt TEXT,
          bodyPart TEXT
            )
          ''');
        }
        if (oldVersion == 2) {
      await db.execute('ALTER TABLE workout_logs ADD COLUMN bodyPart TEXT');
    }
        // 【新增】新的升級邏輯：當從舊版本升到 4 時，建立 weight_logs 資料表
       if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE weight_logs(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          weight REAL NOT NULL,
          createdAt TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }

  // 將建立資料表的邏輯抽出來，方便重複使用
  Future<void> _createTables(Database db) async {
    // 建立 users 資料表
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account TEXT UNIQUE, password TEXT, height TEXT,
        weight TEXT, age TEXT, bmi TEXT, fat TEXT,
        gender TEXT, bmr TEXT
      )
    ''');
    // 建立 workout_logs 資料表
    await db.execute('''
      CREATE TABLE workout_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exerciseName TEXT,
        totalSets INTEGER,
        completedAt TEXT,
        bodyPart TEXT 
      )
    ''');
    // 【新增】建立 weight_logs 資料表
    await db.execute('''
      CREATE TABLE weight_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        weight REAL NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    // 【新增】預設建立一位 admin 帳號
    await db.insert('users', {
      'account': 'admin',
      'password': 'admin123',
      'height': '170',
      'weight': '60',
      'age': '30',
      'bmi': '20.76',
      'fat': '15',
      'gender': 'male',
      'bmr': '1502.5',
    });
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
  Future<void> insertWorkoutLog(WorkoutLog log) async {
    final db = await instance.db;
    await db.insert('workout_logs', log.toMap());
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

  // --- WeightLog 相關方法 (新增) ---
  Future<void> insertWeightLog(WeightLog log) async {
    final db = await instance.db;
    await db.insert('weight_logs', log.toMap());
  }

  Future<List<WeightLog>> getWeightLogs() async {
    final db = await instance.db;
    final List<Map<String, dynamic>> maps = await db.query('weight_logs', orderBy: 'createdAt DESC');
    return List.generate(maps.length, (i) => WeightLog.fromMap(maps[i]));
  }
}