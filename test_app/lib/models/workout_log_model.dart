// lib/models/workout_log_model.dart

// 我們建立一個 WorkoutLog 類別，來標準化「一份訓練紀錄」的資料結構。
// 未來當我們要將紀錄儲存到資料庫時，也會使用這個模型。
class WorkoutLog {
  // 訓練動作的名稱
  final String exerciseName;
  // 完成的總組數
  final int totalSets;
  // 訓練完成的日期與時間
  final DateTime completedAt;
  // （未來可以擴充：總次數、總重量、花費時間等等）

  // WorkoutLog 的建構子
  const WorkoutLog({
    required this.exerciseName,
    required this.totalSets,
    required this.completedAt,
  });
}
