// lib/pages/settings_page.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

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
  // --- 所有 Helper 方法 (匯出、對話框等) 都維持不變，我們只修改 build 方法 ---
  Future<void> _exportData(ExportFormat format) async {
    final logs = await DatabaseHelper.instance.getWorkoutLogs();
    if (!mounted) return;
    if (logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('沒有任何訓練紀錄可以匯出')));
      return;
    }
    String fileContent;
    String fileName;
    if (format == ExportFormat.csv) {
      List<List<dynamic>> rows = [];
      rows.add(['completedAt', 'exerciseName', 'totalSets', 'bodyPart']);
      for (var log in logs) {
        rows.add([log.completedAt.toIso8601String(), log.exerciseName, log.totalSets, log.bodyPart.name]);
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('分享視窗已開啟')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('匯出失敗: $e')));
    }
  }

  Future<void> _showExportOptionsDialog() async {
    return showDialog<void>(context: context, builder: (BuildContext dialogContext) {
      return AlertDialog(titlePadding: EdgeInsets.zero, contentPadding: EdgeInsets.zero, actionsPadding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)), content: SizedBox(width: 270, child: Column(mainAxisSize: MainAxisSize.min, children: [ const Padding(padding: EdgeInsets.symmetric(vertical: 20.0), child: Text('選擇匯出格式', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))), const Divider(height: 1), SizedBox(width: double.infinity, height: 50, child: TextButton(child: const Text('CSV (方便檢視)', style: TextStyle(fontSize: 17)), onPressed: () { Navigator.of(dialogContext).pop(); _exportData(ExportFormat.csv); })), const Divider(height: 1), SizedBox(width: double.infinity, height: 50, child: TextButton(child: const Text('JSON (適合備份)', style: TextStyle(fontSize: 17)), onPressed: () { Navigator.of(dialogContext).pop(); _exportData(ExportFormat.json); })), const Divider(height: 1), SizedBox(width: double.infinity, height: 50, child: TextButton(child: Text('取消', style: TextStyle(color: Colors.red.shade400, fontSize: 17)), onPressed: () => Navigator.of(dialogContext).pop())), ])));
    });
  }

  Future<void> _showClearDataConfirmationDialog() async {
    return showDialog<void>(context: context, builder: (BuildContext dialogContext) {
      return AlertDialog(titlePadding: EdgeInsets.zero, contentPadding: EdgeInsets.zero, actionsPadding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)), content: SizedBox(width: 270, child: Column(mainAxisSize: MainAxisSize.min, children: [ const Padding(padding: EdgeInsets.all(20.0), child: Column(children: [ Text('確認清除', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)), SizedBox(height: 4), Text('此操作將永久刪除所有訓練紀錄且無法復原。', textAlign: TextAlign.center, style: TextStyle(fontSize: 13)) ])), const Divider(height: 1), SizedBox(width: double.infinity, height: 50, child: TextButton(child: Text('全部清除', style: TextStyle(color: Colors.red.shade400, fontSize: 17, fontWeight: FontWeight.bold)), onPressed: () async { await DatabaseHelper.instance.deleteAllWorkoutLogs(); if (!mounted) return; Navigator.of(dialogContext).pop(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('所有訓練紀錄已成功清除'), backgroundColor: Colors.green)); })), const Divider(height: 1), SizedBox(width: double.infinity, height: 50, child: TextButton(child: const Text('取消', style: TextStyle(fontSize: 17)), onPressed: () => Navigator.of(dialogContext).pop())) ])));
    });
  }

  Future<void> _showLogoutConfirmationDialog() async {
    return showDialog<void>(context: context, builder: (BuildContext dialogContext) {
      return AlertDialog(titlePadding: EdgeInsets.zero, contentPadding: EdgeInsets.zero, actionsPadding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)), content: SizedBox(width: 270, child: Column(mainAxisSize: MainAxisSize.min, children: [ const Padding(padding: EdgeInsets.symmetric(vertical: 24.0), child: Text('是否確認登出？', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))), const Divider(height: 1), SizedBox(width: double.infinity, height: 50, child: TextButton(child: Text('登出', style: TextStyle(color: Colors.red.shade400, fontSize: 17, fontWeight: FontWeight.bold)), onPressed: () { Navigator.of(dialogContext).pop(); Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginPage()), (Route<dynamic> route) => false); })), const Divider(height: 1), SizedBox(width: double.infinity, height: 50, child: TextButton(child: Text('稍後再說', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 17)), onPressed: () => Navigator.of(dialogContext).pop())) ])));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      // 【修改】將 body 從 ListView 改為 Column + Spacer 佈局，以將登出按鈕置底
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
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfilePage(account: widget.account))),
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
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DeviceConnectionPage())),
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
                  title: Text('清除所有紀錄', style: TextStyle(color: Colors.red.shade400)),
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
                  // 【修改】將登出按鈕的 onTap 事件，改為呼叫對話框方法
                  // 同時將文字顏色設為紅色
                  title: Center(
                    child: Text(
                      '登出',
                      style: TextStyle(color: Colors.red.shade400, fontSize: 17),
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

  // 沿用您原本美觀的 Helper 方法
  Widget _buildSettingsGroup({required List<Widget> children}) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: children,
      ),
    );
  }
}