// lib/pages/select_part_page.dart

import 'package:flutter/material.dart';

// 引用我們上面確認過的 model 檔案
import 'package:test_app/models/exercise_model.dart';
import './select_exercise_page.dart';

class SelectPartPage extends StatelessWidget {
  const SelectPartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final bodyParts = BodyPart.values;

    return Scaffold(
      appBar: AppBar(
        title: const Text('選擇訓練部位'),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: bodyParts.length,
        itemBuilder: (context, index) {
          final part = bodyParts[index];
          return _buildPartCard(context, part);
        },
      ),
    );
  }

  Widget _buildPartCard(BuildContext context, BodyPart part) {
    return InkWell(
      onTap: () {
    // 【修改】
        // 當使用者點擊卡片時，我們執行頁面導航。
        Navigator.push(
          context,
          // `MaterialPageRoute` 是 Flutter 提供的標準頁面切換效果。
          MaterialPageRoute(
            // `builder` 會建立目標頁面的實例。
            // 我們把使用者點擊的 `part` 作為參數，傳遞給 `SelectExercisePage`。
            builder: (context) => SelectExercisePage(bodyPart: part),
       ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(part.icon, size: 48, color: Theme.of(context).primaryColor),
            const SizedBox(height: 12),
            Text(
              part.displayName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
