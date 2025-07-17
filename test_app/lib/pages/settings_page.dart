// lib/pages/settings_page.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/database_helper.dart';
import './profile_page.dart';
import './device_connection_page.dart';
import './login_page.dart';


enum ExportFormat { csv, json }

class SettingsPage extends StatefulWidget {
  final String account;
  const SettingsPage({super.key, required this.account});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<void> _exportData(ExportFormat format) async {
    final messenger = ScaffoldMessenger.of(context);
    final logs = await DatabaseHelper.instance.getWorkoutLogs();

    if (!mounted) return;
    if (logs.isEmpty) {
      messenger.showSnackBar(
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
          log.bodyPart.name,
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

      await Share.shareXFiles([XFile(path)], text: '我的訓練紀錄');

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('分享視窗已開啟')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('匯出失敗: $e')),
      );
    }
  }

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
                  child: Text(
                    '選擇匯出格式',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                _buildDialogButton(
                  text: 'CSV (方便檢視)',
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _exportData(ExportFormat.csv);
                  },
                ),
                const Divider(height: 1),
                _buildDialogButton(
                  text: 'JSON (適合備份)',
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _exportData(ExportFormat.json);
                  },
                ),
                const Divider(height: 1),
                _buildDialogButton(
                  text: '取消',
                  color: Colors.red.shade400,
                  onPressed: () => Navigator.of(dialogContext).pop(),
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
                      Text('確認清除',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text(
                        '此操作將永久刪除所有訓練紀錄且無法復原。',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                _buildDialogButton(
                  text: '全部清除',
                  color: Colors.red.shade400,
                  isBold: true,
                  onPressed: () async {
                    // 【修正】在 await 之前，先取得 context 相關的物件
                    final navigator = Navigator.of(dialogContext);
                    final messenger = ScaffoldMessenger.of(context);

                    await DatabaseHelper.instance.deleteAllWorkoutLogs();

                    if (!mounted) return;
                    navigator.pop();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('所有訓練紀錄已成功清除'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                _buildDialogButton(
                  text: '取消',
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showLogoutConfirmationDialog() async {
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
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Text(
                    '是否確認登出？',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 1),
                _buildDialogButton(
                  text: '登出',
                  color: Colors.red.shade400,
                  isBold: true,
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()),
                      (Route<dynamic> route) => false,
                    );
                  },
                ),
                const Divider(height: 1),
                _buildDialogButton(
                  text: '稍後再說',
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
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
        title: const Text('設定'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          children: [
            // --- 群組一：個人資料 ---
            _buildSettingsGroup(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('個人資料修改'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProfilePage(account: widget.account),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // --- 群組二：連結裝置 ---
            _buildSettingsGroup(
              children: [
                ListTile(
                  leading: const Icon(Icons.bluetooth_connected),
                  title: const Text('連結裝置'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DeviceConnectionPage(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // --- 群組三：資料管理 ---
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
                  title: Text(
                    '清除所有紀錄',
                    style: TextStyle(color: Colors.red.shade400),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _showClearDataConfirmationDialog,
                ),
              ],
            ),
            // --- 使用 Spacer 將後續元件推到最底部 ---
            const Spacer(),
            // --- 登出按鈕 ---
            _buildSettingsGroup(
              children: [
                ListTile(
                  title: Center(
                    child: Text(
                      '登出',
                      style:
                          TextStyle(color: Colors.red.shade400, fontSize: 17),
                    ),
                  ),
                  onTap: _showLogoutConfirmationDialog,
                ),
              ],
            ),
          ],
        ),
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

  // 【新增】一個 Helper 方法來建立對話框按鈕，避免重複程式碼
  Widget _buildDialogButton({
    required String text,
    required VoidCallback onPressed,
    Color? color,
    bool isBold = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: TextButton(
        // 【修改】將 onPressed 參數移到 child 的前面
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 17,
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
