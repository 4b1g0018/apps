// lib/pages/main_menu_page.dart

import 'package:flutter/material.dart';
import 'package:test_app/pages/select_part_page.dart';

import './workout_history_page.dart';
import './settings_page.dart';
import './profile_page.dart';

// 主選單頁面
class MainMenuPage extends StatelessWidget {
  // 【新增】宣告一個 final 變數來接收從登入頁傳來的帳號
  final String account;
  const MainMenuPage({super.key, required this.account});

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


              ElevatedButton(
              onPressed: () {
                // 歷史紀錄頁面
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WorkoutHistoryPage()),
                );
              },
              child: const Text('訓練紀錄'),
            ),
                const SizedBox(height: 12),
              ElevatedButton(
              onPressed: () {
                // 導航到個人資料頁面時，把帳號再傳下去
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage(account: account)),
                );
              },
              child: const Text('個人資料修改'),
            ),
                  const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                // 詳細設定頁面
                  Navigator.push(
                  context,
                    MaterialPageRoute(builder: (context) => const SettingsPage()),
                  );
                },
                    child: const Text('詳細設定'),
                ),
       ],
        ),
      ),
    );
  }
}
