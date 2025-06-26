// lib/pages/settings_page.dart

import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isReminderEnabled = true;
  bool _isSoundEnabled = true;

  @override
  Widget build(BuildContext context) {
    // 【修正】我們定義一個固定的圖示顏色，來取代 withOpacity
    const iconColor = Color.fromRGBO(255, 255, 255, 0.8);

    return Scaffold(
      appBar: AppBar(
        title: const Text('詳細設定'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        children: [
          // --- 第一個設定群組 ---
          _buildSettingsGroup(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.notifications_active_outlined, color: iconColor),
                title: const Text('測量體重提醒'),
                subtitle: const Text('在您設定的測量日提醒您記錄體重'),
                value: _isReminderEnabled,
                onChanged: (bool newValue) {
                  setState(() {
                    _isReminderEnabled = newValue;
                  });
                },
              ),
              const Divider(height: 1, indent: 56), 
              SwitchListTile(
                secondary: const Icon(Icons.volume_up_outlined, color: iconColor),
                title: const Text('訓練提示音效'),
                subtitle: const Text('在訓練開始或休息倒數時播放提示音'),
                value: _isSoundEnabled,
                onChanged: (bool newValue) {
                  setState(() {
                    _isSoundEnabled = newValue;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // --- 第二個設定群組 ---
          _buildSettingsGroup(
            children: [
              ListTile(
                leading: const Icon(Icons.import_export, color: iconColor),
                title: const Text('匯出訓練紀錄'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: Text(
                  '清除所有紀錄',
                  style: TextStyle(color: Colors.red.shade400),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup({required List<Widget> children}) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: children,
      ),
    );
  }
}
