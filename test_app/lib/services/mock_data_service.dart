// lib/services/mock_data_service.dart

// 引入我們定義好的資料模型
import '../models/exercise_model.dart';

// 我們建立一個 MockDataService 類別，專門用來提供假資料。
class MockDataService {

  // 這是一個靜態 (static) 方法，代表我們可以不用建立 MockDataService 的物件，
  // 就可以直接透過 `MockDataService.getExercisesFor(...)` 來呼叫它。
  static List<Exercise> getExercisesFor(BodyPart part) {
    // 根據選擇得部位switch 顯示的物件
    switch (part) {

      // 如果傳入的是胸部
      case BodyPart.chest:
        return [
          // 我們傳出單或多個 Exercise 物件
          // ！!!!：imagepath是假固定路徑 之後圖片要放入assets/images
          const Exercise(
            name: '槓鈴臥推',
            description: '胸大肌的主要訓練動作，能有效增加胸部厚度與力量。',
            imagePath: 'assets/images/bench_press.png',
          ),
          const Exercise(
            name: '啞鈴飛鳥',
            description: '針對胸大肌外側與中縫的孤立訓練，著重伸展與肌肉感受度。',
            imagePath: 'assets/images/dumbbell_fly.png',
          ),
           const Exercise(
            name: '伏地挺身',
            description: '經典的自體重量訓練，能鍛鍊胸、肩、三頭肌的綜合力量。',
            imagePath: 'assets/images/push_up.png',
          ),
        ];
      
      case BodyPart.legs:
        return [
          const Exercise(
            name: '深蹲',
            description: '最全面的腿部訓練動作，能刺激股四頭肌、臀大肌與腿後腱肌群。',
            imagePath: 'assets/images/squat.png',
          ),
          const Exercise(
            name: '弓箭步',
            description: '能有效訓練單邊腿部的穩定性與力量，同時鍛鍊臀部。',
            imagePath: 'assets/images/lunge.png',
          ),
        ];

      // 對於其他部位，我們先回傳一個空的列表。
      // 你可以依照這個格式，未來自行擴充其他部位的訓練動作。
      default:
        return [];
    }
  }
}
