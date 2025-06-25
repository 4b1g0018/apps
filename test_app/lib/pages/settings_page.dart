// lib/pages/settings_page.dart

import 'package:flutter/material.dart';

// --- 頁面主體：SettingsPage ---
// 我們使用 StatefulWidget，因為頁面上的「開關」狀態是會被使用者改變的。
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}


// --- 頁面狀態管理：_SettingsPageState ---
class _SettingsPageState extends State<SettingsPage> {

  // --- 狀態變數 ---
  // 我們用布林 (bool) 變數來記錄各個設定的開關狀態。
  bool _isReminderEnabled = true; // 體重提醒，預設開啟
  bool _isSoundEnabled = true;    // 訓練聲音，預設開啟

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('詳細設定'),
        centerTitle: true,
      ),
      // 我們使用 ListView 來排列設定選項，
      // 這樣如果未來選項變多，畫面也可以滾動。
      body: ListView(
        children: [
          // --- 第一個區塊：提醒設定 ---
          // SwitchListTile 是一個非常方便的元件，它結合了 ListTile（列表項目）和 Switch（開關）。
          SwitchListTile(
            // `secondary` 是顯示在標題左側的圖示。
            secondary: const Icon(Icons.notifications_active_outlined),
            // `title` 是這個設定項目的主標題。
            title: const Text('測量體重提醒'),
            // `subtitle` 是副標題，用來做更詳細的說明。
            subtitle: const Text('在您設定的測量日提醒您記錄體重'),
            // `value` 用來決定這個開關目前是「開」還是「關」的狀態。
            value: _isReminderEnabled,
            // `onChanged` 是最重要的部分。當使用者撥動開關時，這個函式會被觸發。
            // 它會回傳一個新的布林值 (newValue)，代表開關的新狀態。
            onChanged: (bool newValue) {
              // 我們呼叫 setState() ＝> Flutter更改畫面
              // 然後我們將狀態變數更新成使用者操作後的新狀態。
              setState(() {
                _isReminderEnabled = newValue;
              });
            },
          ),

          // --- 第二個區塊：聲音設定 ---
          SwitchListTile(
            secondary: const Icon(Icons.volume_up_outlined),
            title: const Text('訓練提示音效'),
            subtitle: const Text('在訓練開始或休息倒數時播放提示音'),
            value: _isSoundEnabled,
            onChanged: (bool newValue) {
              setState(() {
                _isSoundEnabled = newValue;
              });
            },
          ),
          
          // Divider 是一條分隔線
          const Divider(),

          // --- 第三個區塊：資料管理 ---
          // 對於不是開關的選項，我們可以用單純的 ListTile。
          ListTile(
            leading: const Icon(Icons.import_export),
            title: const Text('匯出訓練紀錄'),
            // `trailing` 是顯示在項目最右側的元件，通常是一個箭頭圖示。
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // 這裡未來會實作匯出資料的功能
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_forever, color: Colors.red.shade700),
            title: Text(
              '清除所有紀錄',
              //警告顏色
              style: TextStyle(color: Colors.red.shade700),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // 【重要】在真實 App 中，點擊這裡應該要跳出一個再次確認的對話框，
              // 避免使用者誤觸。我們未來可以再來完善這個功能。
            },
          ),
        ],
      ),
    );
  }
}
