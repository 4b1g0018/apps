// lib/services/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' show join;
import '../models/workout_log_model.dart';

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
      version: 3, //更改版本
      onCreate: (db, version) async {
        return await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // 當我們提升 `version` 號時，這個函式會被呼叫。
        // 這讓我們可以在不刪除舊有使用者資料的情況下，新增新的資料表。
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE workout_logs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              exerciseName TEXT,
              totalSets INTEGER,
              completedAt TEXT
          )
          ''');
        }
         // 【新增】新的升級邏輯：當從版本 2 升到 3 時，為 workout_logs 表新增 bodyPart 欄位
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE workout_logs ADD COLUMN bodyPart TEXT');
      }
      },
    );
  }

  // 將建立資料表的邏輯抽出來，方便重複使用
Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account TEXT UNIQUE, password TEXT, height TEXT,
        weight TEXT, age TEXT, bmi TEXT, fat TEXT
      )
    ''');
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

  //註冊用戶資料
  Future<void> insertUser(Map<String, dynamic> data) async {
    final database = await db;
    await database.insert(
      'users',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 驗證帳號密碼是否正確（登入用）
  Future<bool> validateUser(String account, String password) async {
    final database = await db;
    final result = await database.query(
      'users',
      where: 'account = ? AND password = ?',
      whereArgs: [account, password],
    );
    return result.isNotEmpty;
  }

  // 儲存一筆訓練紀錄
  Future<void> insertWorkoutLog(WorkoutLog log) async {
    final database = await db;
    await database.insert('workout_logs', log.toMap());
  }

  //  取得所有訓練紀錄
  Future<List<WorkoutLog>> getWorkoutLogs() async {
    final database = await db;
    final List<Map<String, dynamic>> maps = await database.query(
      'workout_logs',
      orderBy: 'completedAt DESC',
    );
    return List.generate(maps.length, (i) {
      return WorkoutLog.fromMap(maps[i]);
    });
  }
}
