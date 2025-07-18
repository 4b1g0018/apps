// 定義「單筆體重紀錄」的資料結構。

class WeightLog {
  final int? id;
  final double weight;
  final DateTime createdAt;

  WeightLog({
    this.id,
    required this.weight,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'weight': weight,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WeightLog.fromMap(Map<String, dynamic> map) {
    return WeightLog(
      id: map['id'],
      weight: map['weight'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}