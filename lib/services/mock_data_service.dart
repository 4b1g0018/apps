// lib/services/mock_data_service.dart

import 'dart:math';
import '../models/exercise_model.dart';
import '../models/weight_log_model.dart';
import '../models/workout_log_model.dart';
import '../models/set_log_model.dart';
import '../services/database_helper.dart';

class MockDataService {
  // 1. OpenPose 支援的動作 (用於選單顯示)
  static final Map<BodyPart, List<Exercise>> _exercises = {
    BodyPart.chest: [
      const Exercise(name: '槓鈴臥推', description: '胸大肌主要訓練動作', imagePath: 'image/icon/胸.png'),
      const Exercise(name: '伏地挺身', description: '經典徒手胸肌訓練', imagePath: 'image/icon/胸.png'),
    ],
    BodyPart.back: [
      const Exercise(name: '引體向上', description: '背闊肌寬度主要訓練', imagePath: 'image/icon/背.png'),
    ],
    BodyPart.legs: [
      const Exercise(name: '槓鈴深蹲', description: '腿部綜合力量之王', imagePath: 'image/icon/腿.png'),
      const Exercise(name: '羅馬尼亞硬舉', description: '股二頭肌與臀部訓練', imagePath: 'image/icon/腿.png'),
    ],
    BodyPart.shoulders: [
      const Exercise(name: '啞鈴肩推', description: '三角肌前束與中束訓練', imagePath: 'image/icon/肩.png'),
      const Exercise(name: '啞鈴側平舉', description: '三角肌中束寬度訓練', imagePath: 'image/icon/肩.png'),
    ],
    BodyPart.biceps: [
      const Exercise(name: '啞鈴彎舉', description: '肱二頭肌經典訓練', imagePath: 'image/icon/二頭.png'),
    ],
    BodyPart.triceps: [
      const Exercise(name: '三頭下壓', description: '肱三頭肌經典訓練', imagePath: 'image/icon/三頭.png'),
    ],
    BodyPart.abs: [
      const Exercise(name: '捲腹', description: '腹直肌上部訓練', imagePath: 'image/icon/腹.png'),
    ],
  };

  // 2. 【新增】擴充對照表：用來反查部位的字典 (包含您的所有動作)
  static final Map<String, BodyPart> _nameToPartMap = {
    // 腹部
    '懸吊抬腿': BodyPart.abs,
    '俄羅斯轉體': BodyPart.abs,
    '捲腹': BodyPart.abs,
    // 二頭
    '鎚式彎舉': BodyPart.biceps,
    '啞鈴彎舉': BodyPart.biceps,
    // 三頭
    '三頭下壓': BodyPart.triceps,
    // 胸
    '槓鈴臥推': BodyPart.chest,
    '伏地挺身': BodyPart.chest,
    '啞鈴臥推': BodyPart.chest,
    // 背
    '引體向上': BodyPart.back,
    '槓鈴划船': BodyPart.back,
    // 腿
    '槓鈴深蹲': BodyPart.legs,
    '羅馬尼亞硬舉': BodyPart.legs,
    // 肩
    '啞鈴肩推': BodyPart.shoulders,
    '啞鈴側平舉': BodyPart.shoulders,
  };

  static List<Exercise> getExercisesForBodyPart(BodyPart bodyPart) {
    return _exercises[bodyPart] ?? [];
  }

  static List<String> getAllExerciseNames() {
    // 合併 _exercises 和 _nameToPartMap 的所有名稱
    final names = _exercises.values.expand((e) => e).map((e) => e.name).toSet();
    names.addAll(_nameToPartMap.keys);
    return names.toList();
  }

  // 【核心修正】智慧反查部位
  static BodyPart? getBodyPartByName(String name) {
    // 1. 先查擴充字典 (最快)
    if (_nameToPartMap.containsKey(name)) {
      return _nameToPartMap[name];
    }
    // 2. 再查 OpenPose 列表
    for (var entry in _exercises.entries) {
      if (entry.value.any((exercise) => exercise.name == name)) {
        return entry.key;
      }
    }
    return null;
  }

  // --- Mock Data Generation ---
  
  static Future<void> generateGuestData(String account) async {
    final now = DateTime.now();
    final random = Random();
    
    // 1. 生成過去 30 天的體重資料 (模擬波動)
    double currentWeight = 60.0;
    for (int i = 30; i >= 0; i--) {
       if (i % 3 == 0) { // 每 3 天紀錄一次
         final date = now.subtract(Duration(days: i));
         // 隨機波動 -0.5 ~ +0.5
         currentWeight += (random.nextDouble() - 0.5); 
         await DatabaseHelper.instance.insertWeightLog(
           WeightLog(
             weight: double.parse(currentWeight.toStringAsFixed(1)),
             createdAt: date,
             account: account,
           ),
           syncToCloud: false, // 訪客不需同步雲端
         );
       }
    }

    // 2. 生成過去 14 天的運動紀錄
    final exercises = [
      '槓鈴臥推', '深蹲', '硬舉', '啞鈴肩推', '引體向上'
    ];
    
    for (int i = 14; i >= 0; i--) {
      // 每一天有 50% 機率有運動
      if (random.nextBool()) {
        final date = now.subtract(Duration(days: i));
        final exerciseName = exercises[random.nextInt(exercises.length)];
        final bodyPart = getBodyPartByName(exerciseName) ?? BodyPart.chest;
        
        // 建立 WorkoutLog
        final workoutLog = WorkoutLog(
           exerciseName: exerciseName,
           totalSets: 3,
           completedAt: date,
           bodyPart: bodyPart, // 【修正】直接傳入 BodyPart enum
           account: account,
           calories: 100 + random.nextInt(200).toDouble(),
           avgHeartRate: 110 + random.nextInt(40),
           maxHeartRate: 150 + random.nextInt(40),
        );
        
        int logId = await DatabaseHelper.instance.insertWorkoutLog(workoutLog, syncToCloud: false);
        
        // 建立 SetLog (3組)
        for (int set = 1; set <= 3; set++) {
          await DatabaseHelper.instance.insertSetLog(
            SetLog(
              workoutLogId: logId, 
              setNumber: set, 
              weight: 20.0 + random.nextInt(40), 
              reps: 8 + random.nextInt(5)
            )
          );
        }
      }
    }
  }

}