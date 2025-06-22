// lib/models/exercise_model.dart

// icondata
import 'package:flutter/material.dart';

// 定義身體部位的枚舉 (enum)
enum BodyPart {
  chest,
  legs,
  abs,
  shoulders,
  biceps,
  triceps,
}

// 為枚舉添加擴充，方便取得顯示名稱和圖示
extension BodyPartExtension on BodyPart {
  String get displayName {
    switch (this) {
      case BodyPart.chest:
        return '胸';
      case BodyPart.legs:
        return '腿';
      case BodyPart.abs:
        return '腹';
      case BodyPart.shoulders:
        return '肩';
      case BodyPart.biceps:
        return '二頭肌';
      case BodyPart.triceps:
        return '三頭肌';
    }
  }

  IconData get icon {
    // 這裡我們使用 Material Icons 作為範例
    switch (this) {
      case BodyPart.chest:
        return Icons.line_weight;
      case BodyPart.legs:
        return Icons.airline_seat_legroom_extra;
      case BodyPart.abs:
        return Icons.fitness_center;
      case BodyPart.shoulders:
        return Icons.arrow_upward;
      case BodyPart.biceps:
        return Icons.local_mall;
      case BodyPart.triceps:
        return Icons.arrow_downward;
    }
  }
}



// --- 【新增】訓練動作類別 ---
// 我們定義一個 `Exercise` 類別，來標準化「一個訓練動作」所需要包含的資訊。
// 就像是一個模具，未來每個訓練動作物件都會根據這個模具來建立。
class Exercise {
  // `final` 表示這些屬性在物件被建立後，就不能再被修改，增加了程式的穩定性。
  final String name;        // 動作的名稱，例如 "槓鈴臥推"
  final String description; // 動作的簡易文字說明
  final String imagePath;   // 動作示意圖的圖片路徑 (我們先用假路徑)

  // 這是 `Exercise` 類別的建構子 (Constructor)。
  // 當我們要建立一個新的 Exercise 物件時，就會呼叫它。
  // `required` 關鍵字表示這些參數在建立物件時，都必須要提供。
  const Exercise({
    required this.name,
    required this.description,
    required this.imagePath,
  });
}
