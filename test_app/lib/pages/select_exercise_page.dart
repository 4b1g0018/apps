// lib/pages/select_exercise_page.dart

import 'package:flutter/material.dart';
// 引入我們的資料模型和假資料服務
import '../models/exercise_model.dart';
import '../services/mock_data_service.dart';

// 這個頁面也是一個 StatelessWidget，因為它顯示的內容
// 取決於從上一個頁面傳進來的 `bodyPart`。
class SelectExercisePage extends StatelessWidget {

  // 我們定義一個 `final` 的 `bodyPart` 變數，
  // 用來接收從 `SelectPartPage` 傳過來的身體部位。
  final BodyPart bodyPart;

  // 在建構子中，我們要求必須要傳入 `bodyPart`。
  const SelectExercisePage({super.key, required this.bodyPart});

  @override
  Widget build(BuildContext context) {
    // 呼叫我們的假資料服務，根據傳入的 bodyPart 取得對應的動作列表。
    final exercises = MockDataService.getExercisesFor(bodyPart);

    return Scaffold(
      appBar: AppBar(
        // 標題會動態顯示傳入的部位名稱，例如 "胸部 訓練動作"。
        title: Text('${bodyPart.displayName} 訓練動作'),
        centerTitle: true,
      ),
      // `ListView.builder` 是一個用來建立列表視圖的 Widget，
      // 效能很好，適合用來顯示長列表。
      body: ListView.builder(
        // `itemCount` 告訴 ListView 總共有多少個項目。
        itemCount: exercises.length,
        // `itemBuilder` 負責建立列表中的每一個項目。
        itemBuilder: (context, index) {
          // 根據索引 `index` 取得單一的訓練動作物件。
          final exercise = exercises[index];
          // 回傳一個卡片來顯示動作資訊。
          return Card(
            // `margin` 設定卡片的外邊距，讓卡片之間有空隙。
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            // `clipBehavior` 避免子元件超出卡片的圓角範圍。
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                // 在這裡我們可以導航到這個動作的詳細設定頁面
                // (例如設定組數、時間等等)。
              },
              // 這裡我們用 Row 佈局來實現「左圖右文」的效果。
              child: Row(
                children: [
                  // --- 左邊的圖片 ---
                  // 我們先用一個固定顏色的方塊來當作圖片的佔位符。
                  // 如果你有圖片，可以換成 `Image.asset(exercise.imagePath)`
                  Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey.shade300,
                    // 你也可以加上一個 Icon 來示意
                    child: Icon(Icons.image, color: Colors.grey.shade600, size: 40),
                  ),
                  
                  // --- 右邊的文字 ---
                  // `Expanded` 會讓它的子元件 (Column) 填滿 `Row` 中剩餘的所有空間。
                  Expanded(
                    // 我們用 `Padding` 來讓文字和圖片之間有一些內邊距。
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      // `Column` 讓標題和說明可以垂直排列。
                      child: Column(
                        // `crossAxisAlignment` 控制子元件在交叉軸（水平方向）上的對齊方式。
                        // `CrossAxisAlignment.start` 表示向左對齊。
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 動作名稱 (標題)
                          Text(
                            exercise.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8), // 標題和說明的間距
                          // 動作說明 (內文)
                          Text(
                            exercise.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
