// 單次訓練完成後的成果摘要頁面。

import 'package:flutter/material.dart';
// 引入我們剛剛建立的訓練紀錄模型
import '../models/workout_log_model.dart';
// 引入 intl 套件來格式化日期，讓它看起來更友善
// 你可能需要在終端機執行 `flutter pub add intl` 來安裝這個套件
import 'package:intl/intl.dart';

// 這是一個 StatelessWidget，因為它只是單純地顯示傳入的紀錄資訊。
class TrainingSummaryPage extends StatelessWidget {
  // 接收從訓練頁面傳過來的訓練紀錄物件
  final WorkoutLog log;

  const TrainingSummaryPage({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    // 使用 DateFormat 來將 DateTime 物件轉換成我們想要的格式，例如 "yyyy/MM/dd HH:mm"
    final formattedDate = DateFormat('yyyy/MM/dd HH:mm').format(log.completedAt);

    return Scaffold(
      appBar: AppBar(
        title: const Text('訓練總結'),
        // 隱藏返回按鈕，我們希望使用者透過下方的按鈕離開
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            // `mainAxisAlignment` 設為 center 會讓所有子元件垂直置中
            mainAxisAlignment: MainAxisAlignment.center,
            // `crossAxisAlignment` 設為 stretch 會讓子元件在水平方向上填滿可用空間
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.green,
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                '做得好！',
                textAlign: TextAlign.center, // 文字置中
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '你已完成本次訓練',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 40),

              // --- 顯示訓練成果的卡片 ---
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildSummaryRow('訓練項目：', log.exerciseName),
                      const SizedBox(height: 12),
                      _buildSummaryRow('完成組數：', '${log.totalSets} 組'),
                      const SizedBox(height: 12),
                      _buildSummaryRow('完成時間：', formattedDate),
                    ],
                  ),
                ),
              ),

              const Spacer(), // Spacer 會把按鈕推到最底下

              // --- 返回主選單按鈕 ---
              ElevatedButton(
                onPressed: () {
                  // `popUntil` 會一直關閉頁面，直到滿足指定的條件為止。
                  // `route.isFirst` 的意思就是「直到第一個頁面」，也就是我們的主選單。
                  // 這樣可以一次性地清除掉所有訓練相關的頁面（設定、計時、總結），
                  // 直接乾淨地返回主選單。
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('返回主選單', style: TextStyle(fontSize: 18)),
              )
            ],
          ),
        ),
      ),
    );
  }

  // Helper 方法，用來建立一行行的總結文字，讓程式碼更整齊
  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 16, color: Colors.grey.shade800)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
