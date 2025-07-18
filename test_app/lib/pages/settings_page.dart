// 設定中心，提供「個人資料」、「連結裝置」等功能的入口。

import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';
import '../models/workout_log_model.dart';
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
  bool _isReminderEnabled = false;
  int _reminderFrequency = 7;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isReminderEnabled = prefs.getBool('reminder_enabled') ?? false;
      _reminderFrequency = prefs.getInt('reminder_frequency') ?? 7;
    });
  }

  Future<void> _saveReminderEnabled(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_enabled', isEnabled);
    setState(() {
      _isReminderEnabled = isEnabled;
    });

    if (isEnabled) {
      // 【修改】呼叫通知服務來設定提醒 (時間暫定為晚上 8 點)
      NotificationService.instance.scheduleReminder(
        id: 0,
        title: '該記錄體重囉！',
        body: '打開 App 來記錄您今天的體重變化吧！',
        everyXDays: _reminderFrequency,
        hour: 20, // 20:00 (晚上 8 點)
        minute: 0,
      );
    } else {
      // 【修改】呼叫通知服務來取消提醒
      NotificationService.instance.cancelAllNotifications();
    }
  }

  Future<void> _saveReminderFrequency(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_frequency', days);
    setState(() {
      _reminderFrequency = days;
    });
    if (_isReminderEnabled) {
      // 【修改】先取消舊的，再用新的頻率設定提醒
      await NotificationService.instance.cancelAllNotifications();
      await NotificationService.instance.scheduleReminder(
        id: 0,
        title: '該記錄體重囉！',
        body: '打開 App 來記錄您今天的體重變化吧！',
        everyXDays: days,
        hour: 20, // 20:00 (晚上 8 點)
        minute: 0,
      );
    }
  }

  Future<void> _showFrequencyDialog() async {
    int selectedValue = _reminderFrequency;
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('選擇提醒頻率'),
          content: SizedBox(
            height: 150,
            child: CupertinoPicker(
              itemExtent: 40,
              scrollController:
                  FixedExtentScrollController(initialItem: selectedValue - 1),
              onSelectedItemChanged: (int index) => selectedValue = index + 1,
              children: List<Widget>.generate(
                  30, (int index) => Center(child: Text('每 ${index + 1} 天'))),
            ),
          ),
          actions: [
            TextButton(
                child: const Text('取消'),
                onPressed: () => Navigator.of(context).pop()),
            TextButton(
                child: const Text('確定'),
                onPressed: () {
                  _saveReminderFrequency(selectedValue);
                  Navigator.of(context).pop();
                }),
          ],
        );
      },
    );
  }

  Future<void> _exportData(ExportFormat format) async {
    final messenger = ScaffoldMessenger.of(context);
    final logs = await DatabaseHelper.instance.getWorkoutLogs();
    if (!mounted) return;
    if (logs.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('沒有任何訓練紀錄可以匯出')));
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
      await Share.shareXFiles([XFile(path)], text: '我的訓練紀錄');
      if (mounted) {
        messenger.showSnackBar(const SnackBar(content: Text('分享視窗已開啟')));
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('匯出失敗: $e')));
    }
  }

  Future<void> _showExportOptionsDialog() async {
    return showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
            titlePadding: EdgeInsets.zero,
            contentPadding: EdgeInsets.zero,
            actionsPadding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.0)),
            content: SizedBox(
                width: 270,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: Text('選擇匯出格式',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold))),
                  const Divider(height: 1),
                  _buildDialogButton(
                      text: 'CSV (方便檢視)',
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        _exportData(ExportFormat.csv);
                      }),
                  const Divider(height: 1),
                  _buildDialogButton(
                      text: 'JSON (適合備份)',
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        _exportData(ExportFormat.json);
                      }),
                  const Divider(height: 1),
                  _buildDialogButton(
                      text: '取消',
                      color: Colors.red.shade400,
                      onPressed: () => Navigator.of(dialogContext).pop())
                ]))));
  }

  Future<void> _showClearDataConfirmationDialog() async {
    return showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
            titlePadding: EdgeInsets.zero,
            contentPadding: EdgeInsets.zero,
            actionsPadding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.0)),
            content: SizedBox(
                width: 270,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Column(children: [
                        Text('確認清除',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('此操作將永久刪除所有訓練紀錄且無法復原。',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13))
                      ])),
                  const Divider(height: 1),
                  _buildDialogButton(
                      text: '全部清除',
                      color: Colors.red.shade400,
                      isBold: true,
                      onPressed: () async {
                        final navigator = Navigator.of(dialogContext);
                        final messenger = ScaffoldMessenger.of(context);
                        await DatabaseHelper.instance.deleteAllWorkoutLogs();
                        if (!mounted) return;
                        navigator.pop();
                        messenger.showSnackBar(const SnackBar(
                            content: Text('所有訓練紀錄已成功清除'),
                            backgroundColor: Colors.green));
                      }),
                  const Divider(height: 1),
                  _buildDialogButton(
                      text: '取消',
                      onPressed: () => Navigator.of(dialogContext).pop())
                ]))));
  }

  Future<void> _showLogoutConfirmationDialog() async {
    return showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
            titlePadding: EdgeInsets.zero,
            contentPadding: EdgeInsets.zero,
            actionsPadding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.0)),
            content: SizedBox(
                width: 270,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Text('是否確認登出？',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold))),
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
                            (Route<dynamic> route) => false);
                      }),
                  const Divider(height: 1),
                  _buildDialogButton(
                      text: '稍後再說',
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: () => Navigator.of(dialogContext).pop())
                ]))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
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
                              ProfilePage(account: widget.account))),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- 新增：提醒設定 ---
            _buildSettingsGroup(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined),
                  title: const Text('測量體重提醒'),
                  value: _isReminderEnabled,
                  onChanged: _saveReminderEnabled,
                ),
                if (_isReminderEnabled)
                  ListTile(
                    leading: const Icon(Icons.timer_outlined),
                    title: const Text('提醒頻率'),
                    trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '每 $_reminderFrequency 天',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade400, 
                        ),
                    ),
                      const SizedBox(width: 4), 
                      Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade600),
                    ]
                    ),
                    onTap: _showFrequencyDialog,
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // --- 群組三：連結裝置 ---
            _buildSettingsGroup(
              children: [
                ListTile(
                  leading: const Icon(Icons.bluetooth_connected),
                  title: const Text('連結裝置'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const DeviceConnectionPage())),
                ),
                
              ],
            ),
            const SizedBox(height: 24),

            // --- 群組四：資料管理 ---
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
                  title: Text('清除所有紀錄',
                      style: TextStyle(color: Colors.red.shade400)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _showClearDataConfirmationDialog,
                ),
              ],
            ),

            const Spacer(),

            // --- 登出按鈕 ---
            _buildSettingsGroup(
              children: [
                ListTile(
                  title: Center(
                      child: Text('登出',
                          style: TextStyle(
                              color: Colors.red.shade400, fontSize: 17))),
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
        clipBehavior: Clip.antiAlias, child: Column(children: children));
  }

  Widget _buildDialogButton(
      {required String text,
      required VoidCallback onPressed,
      Color? color,
      bool isBold = false}) {
    return SizedBox(
        width: double.infinity,
        height: 50,
        child: TextButton(
            onPressed: onPressed,
            child: Text(text,
                style: TextStyle(
                    fontSize: 17,
                    color: color,
                    fontWeight:
                        isBold ? FontWeight.bold : FontWeight.normal))));
  }
}
