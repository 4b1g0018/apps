// 訓練紀錄資料模型，保存動作名稱、組數、完成時間等訓練資訊。


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

  WorkoutLog copyWith({
    int? id,
    String? exerciseName,
    int? totalSets,
    DateTime? completedAt,
    BodyPart? bodyPart,
  }) {
    return WorkoutLog(
      id: id ?? this.id,
      exerciseName: exerciseName ?? this.exerciseName,
      totalSets: totalSets ?? this.totalSets,
      completedAt: completedAt ?? this.completedAt,
      bodyPart: bodyPart ?? this.bodyPart,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exerciseName': exerciseName,
      'totalSets': totalSets,
      'completedAt': completedAt.toIso8601String(),
      'bodyPart': bodyPart.name,
    };
  }

  factory WorkoutLog.fromMap(Map<String, dynamic> map) {
    BodyPart part = BodyPart.shoulders; 
    final bodyPartString = map['bodyPart'] as String?;
    
    if (bodyPartString != null && bodyPartString.isNotEmpty) {
      try {
        part = BodyPart.values.firstWhere((e) => e.name == bodyPartString);
      } catch (e) {
        // 如果發生任何錯誤，就使用預設值 part
      }
    }

    return WorkoutLog(
      id: map['id'],
      exerciseName: map['exerciseName'],
      totalSets: map['totalSets'],
      completedAt: DateTime.parse(map['completedAt']),
      bodyPart: part, 
    );
  }
}