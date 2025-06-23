// lib/pages/exercise_setup_page.dart

import 'package:flutter/cupertino.dart'; // 引入 
import 'package:flutter/material.dart';
import '../models/exercise_model.dart';
import './training_session_page.dart'; 

// --- 頁面主體：ExerciseSetupPage (與之前相同) ---
class ExerciseSetupPage extends StatefulWidget {
  final Exercise exercise;
  const ExerciseSetupPage({super.key, required this.exercise});

  @override
  State<ExerciseSetupPage> createState() => _ExerciseSetupPageState();
}

// --- 頁面狀態管理：_ExerciseSetupPageState (有修改) ---
class _ExerciseSetupPageState extends State<ExerciseSetupPage> {
  // --- State Variables (狀態變數) ---
  int _sets = 3; // 訓練組數，預設 3 組
  int _restMinutes = 1; // 【新增】休息時間（分鐘），預設 1 分
  int _restSeconds = 0;  // 【新增】休息時間（秒），預設 0 秒

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise.name),
        centerTitle: true,
      ),
      // 我們改用 ListView，這樣當滾輪內容比較多時，整個頁面可以滾動，避免畫面出錯。
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // --- 動作示意圖與名稱 ---
          Text(
            '動作設定',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  color: Colors.grey.shade200,
                  child: Icon(Icons.image, color: Colors.grey.shade500, size: 50),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      widget.exercise.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // --- 【修改】參數設定區塊 ---
          Text(
            '訓練參數',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // --- 組數設定器 (全新版本) ---
          Row(
            // 我們用 Row 來將標籤和滾輪並排。
            children: [
              const Text('訓練組數：', style: TextStyle(fontSize: 16)),
              const Spacer(), // Spacer 會推開兩邊的元件
              // 顯示目前選擇的組數
              Text('$_sets 組', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          // 這是滾輪選擇器本體
          _buildPicker(
            itemCount: 20, // 我們假設最多可以選 20 組
            onSelectedItemChanged: (index) {
              // 當使用者滾動選擇器時，這個函式會被觸發。
              // `index` 是被選中的項目索引（從 0 開始）。
              setState(() {
                // 我們將索引 `index` + 1 作為實際的組數，並更新狀態。
                _sets = index + 1;
              });
            },
            initialItem: _sets - 1, // 設定滾輪的初始位置
          ),

          const SizedBox(height: 16),

          // --- 休息時間設定器 (全新版本) ---
          const Text('休息時間：', style: TextStyle(fontSize: 16)),
          // 我們用一個 Row 將「分鐘滾輪」和「秒鐘滾輪」並排。
          Row(
            children: [
              // 分鐘滾輪
              Expanded( // Expanded 讓每個滾輪都佔用一半的寬度
                child: _buildPicker(
                  itemCount: 10, // 假設最多休息 9 分鐘
                  onSelectedItemChanged: (index) => setState(() => _restMinutes = index),
                  initialItem: _restMinutes,
                  suffix: '分', // 在數字後面加上單位
                ),
              ),
              // 秒鐘滾輪
              Expanded(
                child: _buildPicker(
                  itemCount: 6, // 秒數的選項是 0, 10, 20, 30, 40, 50
                  onSelectedItemChanged: (index) => setState(() => _restSeconds = index * 10),
                  initialItem: _restSeconds ~/ 10, // ~/除法
                  isSeconds: true, // 標記這是秒鐘滾輪，用來顯示不同的文字
                  suffix: '秒',
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // --- 開始訓練按鈕  ---
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // 【新增】防呆檢查：檢查總休息時間是否為 0
                if (_restMinutes == 0 && _restSeconds == 0) {
                  // 如果休息時間為 0，就跳出一個提示訊息，並且不往下執行。
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('休息時間不能為 0 秒，請重新設定！'),
                      backgroundColor: Colors.red, // 用紅色來強調這是一個錯誤提示
                    ),
                  );
                  return; // 中斷函式的執行
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TrainingSessionPage(
                      exercise: widget.exercise,
                      totalSets: _sets,
                      restTimeInSeconds: (_restMinutes * 60) + _restSeconds,
                    ),
                  ),
                );
              },
              
             style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('開始訓練', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  // --- 【新增】Helper 方法：_buildPicker ---
  // 我們將建立滾輪選擇器的邏輯抽出來，方便重複使用。
  Widget _buildPicker({
    required int itemCount, // 總共有幾個選項
    required ValueChanged<int> onSelectedItemChanged, // 滾動時要執行的函式
    required int initialItem, // 初始選項的索引
    String suffix = '',      // 單位後綴，例如 "分" 或 "秒"
    bool isSeconds = false,  // 是否為秒鐘滾輪的特殊標記
  }) {
    // 我們用一個固定高度的 SizedBox 來包裹滾輪，避免它無限伸展。
    return SizedBox(
      height: 150, // 滾輪的高度
      child: CupertinoPicker(
        // `itemExtent` 是每個選項的高度，這是必要屬性。
        itemExtent: 40.0,
        // `onSelectedItemChanged` 是當選項改變時的回呼函式。
        onSelectedItemChanged: onSelectedItemChanged,
        // `scrollController` 可以用來設定滾輪的初始位置。
        scrollController: FixedExtentScrollController(initialItem: initialItem),
        // `children` 是滾輪中要顯示的所有選項列表。
        // 我們用 `List.generate` 來動態產生這個列表。
        children: List<Widget>.generate(itemCount, (index) {
          // 根據是否為秒鐘滾輪，來決定要顯示的文字
          final text = isSeconds ? '${index * 10}' : '${index + (suffix == '分' ? 0 : 1)}';
          return Center(
            child: Text('$text $suffix', style: const TextStyle(fontSize: 20)),
          );
        }),
      ),
    );
  }
}
