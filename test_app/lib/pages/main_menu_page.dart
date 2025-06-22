// lib/pages/main_menu_page.dart

import 'package:flutter/material.dart';
// 【修正】改用 package-relative 路徑，這會更穩定
import 'package:test_app/pages/select_part_page.dart';

// 主選單頁面
class MainMenuPage extends StatelessWidget {
  const MainMenuPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('主選單')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SelectPartPage()),
                );
              },
              child: const Text('開始訓練'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () {}, child: const Text('訓練紀錄')),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () {}, child: const Text('個人資料修改')),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: () {}, child: const Text('詳細設定')),
          ],
        ),
      ),
    );
  }
}
