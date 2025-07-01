// lib/pages/settings_page.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/database_helper.dart';
import '../models/workout_log_model.dart';

// 我們定義一個枚舉，來代表匯出的格式
enum ExportFormat { csv, json }

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isReminderEnabled = true;
  bool _isSoundEnabled = true;

  Future<void> _exportData(ExportFormat format) async {
    final logs = await DatabaseHelper.instance.getWorkoutLogs();

    if (!mounted) return;

    if (logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('沒有任何訓練紀錄可以匯出')),
      );
      return;
    }

    String fileContent;
    String fileName;

    if (format == ExportFormat.csv) {
      List<List<dynamic>> rows = [];
      rows.add(['completedAt', 'exerciseName', 'totalSets', 'bodyPart']);
      for (var log in logs) {
        rows.add([
          log.completedAt.toIso8601String(),
          log.exerciseName,
          log.totalSets,
          log.bodyPart.name
        ]);
      }
      fileContent = const ListToCsvConverter().convert(rows);
      fileName = 'workout_logs.csv';
    } else {
      final logsAsMaps = logs.map((log) => log.toMap()).toList();
      fileContent = jsonEncode(logsAsMaps);
      fileName = 'workout_logs.json';
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/$fileName';
      final file = File(path);
      await file.writeAsString(fileContent);

      final result = await Share.shareXFiles([XFile(path)], text: '我的訓練紀錄');

      if (result.status == ShareResultStatus.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('匯出檔案已準備就緒！')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('匯出失敗: $e')),
      );
    }
  }

  // --- 【對話框美化】 ---
  // 我們將匯出選項的對話框，也改成跟登出、清除一樣的風格
  Future<void> _showExportOptionsDialog() async {
    return showDialog<void>(
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
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Text('選擇匯出格式', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ),
                Divider(height: 1, color: Colors.grey.shade700),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton(
                    child: const Text('CSV (方便檢視)', style: TextStyle(fontSize: 17)),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _exportData(ExportFormat.csv);
                    },
                  ),
                ),
                Divider(height: 1, color: Colors.grey.shade700),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton(
                    child: const Text('JSON (適合備份)', style: TextStyle(fontSize: 17)),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _exportData(ExportFormat.json);
                    },
                  ),
                ),
                // --- 【新增】紅色的取消按鈕 ---
                Divider(height: 1, color: Colors.grey.shade700),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton(
                    child: Text(
                      '取消',
                      style: TextStyle(color: Colors.red.shade400, fontSize: 17),
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showClearDataConfirmationDialog() async {
    return showDialog<void>(
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
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text('確認清除', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('此操作將永久刪除所有訓練紀錄且無法復原。', textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.grey.shade700),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton(
                    child: Text('全部清除', style: TextStyle(color: Colors.red.shade400, fontSize: 17, fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      final navigator = Navigator.of(dialogContext);
                      final messenger = ScaffoldMessenger.of(context);
                      final mountedState = mounted;
                      await DatabaseHelper.instance.deleteAllWorkoutLogs();
                      if (!mountedState) return;
                      navigator.pop();
                      messenger.showSnackBar(const SnackBar(content: Text('所有訓練紀錄已成功清除'), backgroundColor: Colors.green));
                    },
                  ),
                ),
                Divider(height: 1, color: Colors.grey.shade700),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: TextButton(
                    child: const Text('取消', style: TextStyle(fontSize: 17)),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('詳細設定'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        children: [
          _buildSettingsGroup(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.notifications_active_outlined),
                title: const Text('測量體重提醒'),
                subtitle: const Text('在您設定的測量日提醒您記錄體重'),
                value: _isReminderEnabled,
                onChanged: (bool newValue) => setState(() => _isReminderEnabled = newValue),
              ),
              const Divider(height: 1, indent: 56), 
              SwitchListTile(
                secondary: const Icon(Icons.volume_up_outlined),
                title: const Text('訓練提示音效'),
                subtitle: const Text('在訓練開始或休息倒數時播放提示音'),
                value: _isSoundEnabled,
                onChanged: (bool newValue) => setState(() => _isSoundEnabled = newValue),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsGroup(
            children: [
              ListTile(
                leading: const Icon(Icons.import_export),
                title: const Text('匯出訓練紀錄'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showExportOptionsDialog,
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: Text('清除所有紀錄', style: TextStyle(color: Colors.red.shade400)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _showClearDataConfirmationDialog,
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
