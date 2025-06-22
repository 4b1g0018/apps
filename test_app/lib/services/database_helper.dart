// lib/services/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' show join;

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
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            account TEXT UNIQUE,
            password TEXT,
            height TEXT,
            weight TEXT,
            age TEXT,
            bmi TEXT,
            fat TEXT
          )
        ''');
        // 預設建立一位 admin 帳號方便測試 demo
        await db.insert('users', {
          'account': 'admin',
          'password': 'admin123',
          'height': '170',
          'weight': '60',
          'age': '30',
          'bmi': '20.76',
          'fat': '15',
        });
      },
    );
  }

  // 註冊用戶資料
  Future<void> insertUser(Map<String, dynamic> data) async {
    final database = await db;
    await database.insert('users', data);
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
}
