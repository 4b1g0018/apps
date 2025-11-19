// lib/services/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' show join;

// 導入所有需要的模型
import '../models/workout_log_model.dart';
import '../models/user_model.dart';
import '../models/weight_log_model.dart';
import '../models/set_log_model.dart';
import '../models/custom_exercise.dart';
import '../models/exercise_model.dart';
import '../models/plan_item_model.dart'; 

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
      version: 11, 
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account TEXT UNIQUE, password TEXT, height TEXT, weight TEXT,
        age TEXT, bmi TEXT, fat TEXT, gender TEXT, bmr TEXT,
        goalWeight TEXT, fitnessLevel TEXT, trainingDays TEXT,
        nickname TEXT, hometown TEXT
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
    await db.execute('''
      CREATE TABLE custom_exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bodyPart INTEGER,
        name TEXT NOT NULL,
        description TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE plan_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dayOfWeek INTEGER NOT NULL,
        exerciseName TEXT NOT NULL,
        sets TEXT NOT NULL,
        weight TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
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
    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE set_logs(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          workoutLogId INTEGER, setNumber INTEGER,
          weight REAL, reps INTEGER
        )
      ''');
    }
    if (oldVersion < 9) {
      await db.execute('''
        CREATE TABLE custom_exercises (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          bodyPart INTEGER,
          name TEXT NOT NULL,
          description TEXT
        )
      ''');
      await db.execute('ALTER TABLE users ADD COLUMN trainingDays TEXT');
    }
    if (oldVersion < 10) {
      await db.execute('''
        CREATE TABLE plan_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          dayOfWeek INTEGER NOT NULL,
          exerciseName TEXT NOT NULL,
          sets TEXT NOT NULL,
          weight TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 11) {
      await db.execute('ALTER TABLE users ADD COLUMN nickname TEXT');
      
      await db.execute('ALTER TABLE users ADD COLUMN hometown TEXT');
     
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

  // --- CustomExercise 相關 ---
  Future<int> insertCustomExercise(CustomExercise exercise) async {
    final db = await instance.db;
    return await db.insert('custom_exercises', exercise.toMap());
  }

  Future<List<CustomExercise>> getCustomExercisesForBodyPart(BodyPart bodyPart) async {
    final db = await instance.db;
    final List<Map<String, dynamic>> maps = await db.query('custom_exercises', where: 'bodyPart = ?', whereArgs: [bodyPart.index]);
    return List.generate(maps.length, (i) => CustomExercise.fromMap(maps[i]));
  }

  Future<int> deleteCustomExercise(int id) async {
    final db = await instance.db;
    return await db.delete('custom_exercises', where: 'id = ?', whereArgs: [id]);
  }

  // --- WorkoutLog 相關方法 ---
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

  // --- SetLog 相關方法 ---
  Future<void> insertSetLog(SetLog log) async {
    final db = await instance.db;
    await db.insert('set_logs', log.toMap());
  }

  Future<List<SetLog>> getSetLogsForWorkout(int workoutLogId) async {
    final db = await instance.db;
    final List<Map<String, dynamic>> maps = await db.query('set_logs', where: 'workoutLogId = ?', whereArgs: [workoutLogId], orderBy: 'setNumber ASC');
    return List.generate(maps.length, (i) => SetLog.fromMap(maps[i]));
  }

  // --- PlanItem 相關方法 ---
  Future<int> insertPlanItem(PlanItem item) async {
    final db = await instance.db;
    return await db.insert('plan_items', item.toMap());
  }

  Future<List<PlanItem>> getPlanItemsForDay(int dayOfWeek) async {
    final db = await instance.db;
    final List<Map<String, dynamic>> maps = await db.query(
      'plan_items',
      where: 'dayOfWeek = ?',
      whereArgs: [dayOfWeek],
    );
    return List.generate(maps.length, (i) => PlanItem.fromMap(maps[i]));
  }

  Future<int> deletePlanItem(int id) async {
    final db = await instance.db;
    return await db.delete('plan_items', where: 'id = ?', whereArgs: [id]);
  }
}