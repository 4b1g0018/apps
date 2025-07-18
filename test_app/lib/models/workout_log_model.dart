// 定義「單筆訓練紀錄」的資料結構。

import './exercise_model.dart';

class WorkoutLog {
  final int? id;
  final String exerciseName;
  final int totalSets;
  final DateTime completedAt;
  final BodyPart bodyPart;

  const WorkoutLog({
    this.id,
    required this.exerciseName,
    required this.totalSets,
    required this.completedAt,
    required this.bodyPart,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exerciseName': exerciseName,
      'totalSets': totalSets,
      'completedAt': completedAt.toIso8601String(),
      'bodyPart': bodyPart.name,
    };
  }

  // --- 【修改】寫法更安全的 fromMap 工廠建構子 ---
  factory WorkoutLog.fromMap(Map<String, dynamic> map) {
    // 先宣告一個預設值
    BodyPart part = BodyPart.shoulders; 
    // 從 map 中取得 bodyPart 的字串，如果不存在，則為 null
    final bodyPartString = map['bodyPart'] as String?;

    // 只有在 bodyPartString 確實存在且不是空字串時，才去尋找對應的枚舉
    if (bodyPartString != null && bodyPartString.isNotEmpty) {
      // 使用 try-catch 來處理，即使 firstWhere 找不到也會有預設值，更安全
      try {
        part = BodyPart.values.firstWhere((e) => e.name == bodyPartString);
      } catch (e) {
        // 如果發生任何錯誤，就使用預設值 part。
        // 我們移除了這裡的 print() 語句來解決警告。
      }
    }

    return WorkoutLog(
      id: map['id'],
      exerciseName: map['exerciseName'],
      totalSets: map['totalSets'],
      completedAt: DateTime.parse(map['completedAt']),
      bodyPart: part, // 使用我們安全處理過的 part
    );
  }
}
