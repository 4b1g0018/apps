// lib/pages/main_menu_page.dart

import 'package:flutter/material.dart';
import './select_part_page.dart';
import './workout_history_page.dart';
import './settings_page.dart';
import './profile_page.dart';
import './login_page.dart';

class MainMenuPage extends StatelessWidget {
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
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SelectPartPage()));
              },
              child: const Text('開始訓練')
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) => const WorkoutHistoryPage()));
              },
              child: const Text('訓練紀錄')
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage(account: account)),
                );
              },
              child: const Text('個人資料修改'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
              },
              child: const Text('詳細設定')
            ),
            
            const Spacer(),

            // --- 【新增】在登出按鈕上方加上一條分隔線 ---
            const Divider(),
            const SizedBox(height: 8), // 分隔線和按鈕之間的小間距

            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      titlePadding: EdgeInsets.zero,
                      contentPadding: EdgeInsets.zero,
                      actionsPadding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                      content: SizedBox(
                        width: 270,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24.0),
                              child: Text(
                                '是否確認登出？',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Divider(height: 1, color: Colors.grey.shade700),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: TextButton(
                                child: Text(
                                  '登出',
                                  style: TextStyle(
                                    color: Colors.red.shade400,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(dialogContext).pop();
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (context) => const LoginPage()),
                                    (Route<dynamic> route) => false,
                                  );
                                },
                              ),
                            ),
                            Divider(height: 1, color: Colors.grey.shade700),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: TextButton(
                                child: Text(
                                  '稍後再說',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontSize: 17,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(dialogContext).pop();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  '登出',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red.shade400,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
