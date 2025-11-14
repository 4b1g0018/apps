// 預設選擇部位後動作的假資料 

// 引入我們定義好的資料模型
import '../models/exercise_model.dart';


// 我們建立一個 MockDataService 類別，專門用來提供假資料。
// 我們建立一個靜態類別來存放所有預設的訓練動作
class MockDataService {
  // 這是一個 Map，Key 是肌群部位 (BodyPart)，Value 是該部位對應的訓練動作 List
  static final Map<BodyPart, List<Exercise>> _exercises = {
    BodyPart.chest: [
      const Exercise(name: '槓鈴臥推', description: '胸大肌主要訓練動作'),
      const Exercise(name: '啞鈴飛鳥', description: '胸大肌外側與中縫訓練'),
      const Exercise(name: '伏地挺身', description: '經典徒手胸肌訓練'),
      const Exercise(name: '繩索夾胸', description: '持續張力，刺激胸肌中縫'),
    ],
    BodyPart.back: [
      const Exercise(name: '引體向上', description: '背闊肌寬度主要訓練'),
      const Exercise(name: '槓鈴划船', description: '背部厚度主要訓練'),
      const Exercise(name: '坐姿划船', description: '中背部肌群訓練'),
      const Exercise(name: '滑輪下拉', description: '模擬引體向上的器械動作'),
    ],
    BodyPart.legs: [
      const Exercise(name: '槓鈴深蹲', description: '腿部綜合力量之王'),
      const Exercise(name: '腿推舉', description: '大重量刺激腿部肌群'),
      const Exercise(name: '羅馬尼亞硬舉', description: '股二頭肌與臀部訓練'),
      const Exercise(name: '腿伸屈', description: '股四頭肌孤立訓練'),
    ],
    BodyPart.shoulders: [
      const Exercise(name: '啞鈴肩推', description: '三角肌前束與中束訓練'),
      const Exercise(name: '啞鈴側平舉', description: '三角肌中束寬度訓練'),
      const Exercise(name: '臉拉', description: '三角肌後束與上背健康'),
      const Exercise(name: '槓鈴聳肩', description: '斜方肌訓練'),
    ],
    BodyPart.biceps: [
      const Exercise(name: '啞鈴彎舉', description: '肱二頭肌經典訓練'),
      const Exercise(name: '鎚式彎舉', description: '肱肌與肱橈肌訓練'),
    ],
    BodyPart.triceps: [
      const Exercise(name: '三頭下壓', description: '肱三頭肌經典訓練'),
      const Exercise(name: '過頭啞鈴臂屈伸', description: '肱三頭肌長頭訓練'),
    ],
    BodyPart.abs: [
      const Exercise(name: '捲腹', description: '腹直肌上部訓練'),
      const Exercise(name: '懸吊抬腿', description: '腹直肌下部與核心'),
      const Exercise(name: '俄羅斯轉體', description: '腹內外斜肌訓練'),
    ],
  };

  // 一個公開的方法，讓其他頁面可以根據傳入的 bodyPart，取得對應的動作列表
  static List<Exercise> getExercisesForBodyPart(BodyPart bodyPart) {
    return _exercises[bodyPart] ?? []; // 如果找不到，就回傳一個空列表
  }
}
